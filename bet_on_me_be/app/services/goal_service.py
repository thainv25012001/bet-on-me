import json
import uuid
from datetime import datetime, timezone as dt_timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
from openai import AsyncOpenAI
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.goal_repository import GoalRepository
from app.repositories.subscription_repository import SubscriptionRepository
from app.repositories.task_repository import TaskRepository
from app.schemas.goal import CommitmentOut, GoalCreate, GoalGenerateRequest, GoalUpdate
from app.models.goal import Goal
from app.models.goal_job import GoalJob
from app.models.plan import Plan
from app.models.stake import Stake
from app.models.user import User
from app.core.config import settings
from app.services.subscription_service import SubscriptionService
from app.utils.constants import GoalStatus, GoalMode, StakeStatus
from app.utils.exceptions import BadRequest, NotFound, Forbidden, GoalLimitReached


class GoalService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = GoalRepository(db)

    async def list_goals(self, user: User, page: int, page_size: int) -> tuple[list[Goal], int]:
        skip = (page - 1) * page_size
        items = await self.repo.get_by_user(user.id, skip=skip, limit=page_size)
        total = await self.repo.count_by_user(user.id)
        return items, total

    async def create_goal_draft(self, user: User, data: GoalCreate) -> Goal:
        """Persist basic goal info immediately. Plan/tasks are generated async."""
        db = self.repo.db

        # Enforce per-tier goal limit before creating.
        active_sub = await SubscriptionRepository(db).get_active_by_user(user.id)
        goal_limit = SubscriptionService.get_goal_limit_for_subscription(active_sub)
        current_count = await self.repo.count_active_by_user(user.id)
        if current_count >= goal_limit:
            raise GoalLimitReached(goal_limit)

        goal = Goal(
            user_id=user.id,
            title=data.title,
            description=data.description,
            start_date=data.start_date,
            # Placeholder when hours mode — consumer updates after AI estimates real duration.
            target_date=data.target_date or data.start_date,
            stake_per_day=data.stake_per_day,
        )
        db.add(goal)
        await db.commit()
        await db.refresh(goal)
        return goal

    async def get_goal(self, goal_id: uuid.UUID, user: User) -> Goal:
        goal = await self.repo.get(goal_id)
        if not goal:
            raise NotFound("Goal")
        if str(goal.user_id) != str(user.id):
            raise Forbidden()
        return goal

    async def update_goal(self, goal_id: uuid.UUID, user: User, data: GoalUpdate) -> Goal:
        goal = await self.get_goal(goal_id, user)
        return await self.repo.update(goal, **data.model_dump(exclude_unset=True))

    async def delete_goal(self, goal_id: uuid.UUID, user: User) -> None:
        goal = await self.get_goal(goal_id, user)
        await self.repo.delete(goal)

    async def evaluate_goal_status(self, goal: Goal) -> None:
        """Set goal to 'success' or 'failed' if the deadline has passed in the user's timezone.
        Does nothing if the deadline has not yet passed or no plan exists."""
        db = self.repo.db

        # Resolve the user's local date.
        user = await db.get(User, goal.user_id)
        try:
            tz = ZoneInfo(user.timezone or "UTC")
        except ZoneInfoNotFoundError:
            tz = ZoneInfo("UTC")
        local_date = datetime.now(dt_timezone.utc).astimezone(tz).date()

        # Only evaluate once the deadline day has fully passed in the user's timezone.
        if local_date <= goal.target_date:
            return

        # Find the plan.
        plan_result = await db.execute(select(Plan).where(Plan.goal_id == goal.id))
        plan = plan_result.scalar_one_or_none()
        if plan is None:
            return

        # Count tasks.
        task_repo = TaskRepository(db)
        total = await task_repo.count_by_plan(plan.id)
        if total == 0:
            return

        done = await task_repo.count_success_by_plan(plan.id)
        new_status = GoalStatus.SUCCESS if done == total else GoalStatus.FAILED
        await self.repo.update(goal, status=new_status)

    async def get_commitment(self, goal_id: uuid.UUID, user: User) -> CommitmentOut:
        """Return commitment details for a locked goal."""
        goal = await self.repo.get(goal_id)
        if not goal or str(goal.user_id) != str(user.id):
            raise NotFound("Goal")
        if goal.status != GoalStatus.LOCKED:
            raise BadRequest("Goal is not locked")

        db = self.repo.db
        stake_result = await db.execute(
            select(Stake).where(
                Stake.goal_id == goal.id,
                Stake.status == StakeStatus.PENDING,
            )
        )
        stake = stake_result.scalar_one_or_none()
        if stake is None:
            raise NotFound("No pending commitment found")

        # Derive actual generated days from the stake record, which was set
        # using plan_days (capped by subscription tier) not plan.total_days
        # (which equals the full goal duration for DURATION-mode goals).
        actual_days = (
            stake.total_committed // stake.amount_per_day
            if stake.amount_per_day and stake.amount_per_day > 0
            else 0
        )
        return CommitmentOut(
            goal_id=goal.id,
            amount_per_day=stake.amount_per_day,
            plan_total_days=actual_days,
            total_committed=stake.total_committed,
            stake_id=stake.id,
        )

    async def unlock_goal(self, goal_id: uuid.UUID, user: User) -> Goal:
        """Confirm commitment and move goal from locked → in_progress."""
        goal = await self.repo.get(goal_id)
        if not goal or str(goal.user_id) != str(user.id):
            raise NotFound("Goal")
        if goal.status != GoalStatus.LOCKED:
            raise BadRequest("Goal is not locked")

        db = self.repo.db
        stake_result = await db.execute(
            select(Stake).where(
                Stake.goal_id == goal.id,
                Stake.status == StakeStatus.PENDING,
            )
        )
        stake = stake_result.scalar_one_or_none()
        if stake:
            stake.status = StakeStatus.ACTIVE
        goal.status = GoalStatus.IN_PROGRESS
        await db.commit()
        await db.refresh(goal)
        return goal

    async def enqueue_goal_job(
        self, user: User, goal_id: uuid.UUID, data: GoalGenerateRequest
    ) -> dict:
        """Create a GoalJob linked to an existing goal and publish to Kafka."""
        from app.kafka.producer import send_goal_job

        db = self.repo.db

        # Verify goal exists and belongs to this user.
        goal = await self.repo.get(goal_id)
        if not goal:
            raise NotFound("Goal")
        if str(goal.user_id) != str(user.id):
            raise Forbidden()

        if data.mode == GoalMode.DURATION:
            total_days = (goal.target_date - goal.start_date).days
        else:
            active_sub = await SubscriptionRepository(db).get_active_by_user(user.id)
            total_days = SubscriptionService.get_max_days_for_subscription(active_sub)

        # Formula: max(5, 5 + int(total_days * 0.15))
        estimated_seconds = max(5, 5 + int(total_days * 0.15))

        payload = data.model_dump(mode="json")
        job = GoalJob(
            user_id=user.id,
            goal_id=goal_id,   # pre-set — goal already exists
            payload=payload,
            estimated_seconds=estimated_seconds,
        )
        db.add(job)
        await db.commit()
        await db.refresh(job)

        await send_goal_job(str(job.id), payload)
        return {"job_id": job.id, "estimated_seconds": estimated_seconds}

    async def get_job_status(self, job_id: uuid.UUID, user: User) -> dict:
        """Return the current status of a goal-creation job owned by user."""
        result = await self.repo.db.execute(
            select(GoalJob).where(
                GoalJob.id == job_id,
                GoalJob.user_id == user.id,
            )
        )
        job = result.scalar_one_or_none()
        if not job:
            raise NotFound("GoalJob")
        elapsed = int((datetime.utcnow() - job.created_at).total_seconds())
        return {
            "job_id": job.id,
            "status": job.status,
            "goal_id": job.goal_id,
            "error_message": job.error_message,
            "estimated_seconds": job.estimated_seconds,
            "elapsed_seconds": elapsed,
        }


async def _generate_tasks(
    goal_title: str,
    hours_per_day: float,
    mode: str,
    duration: int | None,
    max_days: int,
) -> dict:
    client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
    daily_minutes = int(hours_per_day * 60)

    if mode == GoalMode.DURATION:
        # plan_days = capped task window; total_days = real full goal duration
        plan_days = min(duration, max_days)
        prompt = _build_duration_prompt(goal_title, duration, plan_days, hours_per_day, daily_minutes)
    else:
        prompt = _build_hours_prompt(goal_title, hours_per_day, daily_minutes, max_days)

    response = await client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
    )
    content = response.choices[0].message.content
    parsed = json.loads(content)

    tasks = parsed.get("tasks")
    if tasks is None:
        for v in parsed.values():
            if isinstance(v, list):
                tasks = v
                break
    if tasks is None:
        raise ValueError(f"Unexpected OpenAI response shape: {content}")

    if mode == GoalMode.HOURS:
        estimated_total_days = parsed.get("estimated_total_days")
        if not isinstance(estimated_total_days, int) or estimated_total_days < 1:
            raise ValueError(f"Mode B response missing valid estimated_total_days: {content}")
        total_days = estimated_total_days
        plan_days = min(max(item["day_number"] for item in tasks), max_days)
    else:
        total_days = duration  # real full goal duration

    # Server-side guard: verify every day from 1..plan_days has at least one task.
    days_present = {item["day_number"] for item in tasks}
    missing = [d for d in range(1, plan_days + 1) if d not in days_present]
    if missing:
        raise ValueError(
            f"AI response is missing tasks for day(s) {missing} "
            f"(plan_days={plan_days}). Raw: {content[:300]}"
        )

    return {"overview": parsed.get("overview"), "tasks": tasks, "plan_days": plan_days, "total_days": total_days}


def _build_duration_prompt(title: str, full_duration: int, plan_days: int, hours_per_day: float, daily_minutes: int) -> str:
    cap_note = (
        f"Note: this is a {full_duration}-day goal but only the first {plan_days} days are being planned now."
        if plan_days < full_duration else ""
    )
    t1 = min(90, daily_minutes // 3)
    t2 = min(90, daily_minutes // 3)
    t3 = daily_minutes - t1 - t2
    return f"""
You are a productivity coach. Generate a structured daily plan for the following goal.

Goal: {title}
Full goal duration: {full_duration} days
Available time per day: {hours_per_day} hours ({daily_minutes} minutes)
{cap_note}

RULES — read carefully before generating:
1. Generate tasks for EVERY day from 1 to {plan_days}. The tasks array MUST contain at least one entry for each day_number 1, 2, 3 … {plan_days}. Skipping any day is an error.
2. For each day, the SUM of estimated_minutes across that day's tasks MUST be between {int(daily_minutes * 0.85)} and {int(daily_minutes * 1.15)} minutes. Add multiple tasks to the same day to reach the budget — do NOT leave a day under-filled.
3. Do not add any task with day_number > {plan_days}.

Return a JSON object with exactly these two keys:
- "overview": string (2-3 sentences summarising the overall strategy and milestones for the full {full_duration}-day goal)
- "tasks": array of ALL task objects for days 1 through {plan_days}

Each task object must have exactly these fields:
- "day_number": integer (1-based, 1 ≤ day_number ≤ {plan_days})
- "title": string (short action title, max 10 words)
- "description": string (1-2 sentences describing what the task involves)
- "explanation": string (2-3 sentences explaining WHY this task matters for the goal)
- "guide": array of step objects, each with "step" (int), "action" (string), "example" (string)
- "estimated_minutes": integer (time for this single task)

Example structure — note how EACH day gets multiple tasks that together fill {daily_minutes} min:
{{
  "overview": "...",
  "tasks": [
    {{"day_number": 1, "title": "Task A for day 1", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t1}}},
    {{"day_number": 1, "title": "Task B for day 1", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t2}}},
    {{"day_number": 1, "title": "Task C for day 1", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t3}}},
    {{"day_number": 2, "title": "Task A for day 2", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t1}}},
    {{"day_number": 2, "title": "Task B for day 2", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t2}}},
    {{"day_number": 2, "title": "Task C for day 2", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t3}}},
    "... continue this exact pattern for day 3, day 4, … day {plan_days}"
  ]
}}

Before returning, verify: does every day_number from 1 to {plan_days} appear in the tasks array? If any day is missing, add its tasks before outputting.

Return only the JSON object, no extra text.
"""


def _build_hours_prompt(title: str, hours_per_day: float, daily_minutes: int, max_days: int) -> str:
    t1 = min(90, daily_minutes // 3)
    t2 = min(90, daily_minutes // 3)
    t3 = daily_minutes - t1 - t2
    return f"""
You are a productivity coach. A user wants to achieve the following goal and can commit
{hours_per_day} hours ({daily_minutes} minutes) per day.

Goal: {title}
Available time per day: {hours_per_day} hours ({daily_minutes} minutes)
Maximum days to generate: {max_days}

First, estimate the total number of days needed to fully achieve this goal at {hours_per_day} hours/day.
Let N = min(your estimate, {max_days}).
Then generate tasks for days 1 through N only.

RULES — read carefully before generating:
1. Generate tasks for EVERY day from 1 to N. The tasks array MUST contain at least one entry for each day_number 1, 2, 3 … N. Skipping any day is an error.
2. For each day, the SUM of estimated_minutes across that day's tasks MUST be between {int(daily_minutes * 0.85)} and {int(daily_minutes * 1.15)} minutes. Add multiple tasks to the same day to reach the budget — do NOT leave a day under-filled.
3. Do not add any task with day_number > {max_days}.

Return a JSON object with exactly these three keys:
- "estimated_total_days": integer — your estimate of the FULL days needed (can exceed {max_days})
- "overview": string (2-3 sentences summarising the overall strategy for the full goal)
- "tasks": array of ALL task objects for days 1 through N

Each task object must have exactly these fields:
- "day_number": integer (1-based, must not exceed {max_days})
- "title": string (short action title, max 10 words)
- "description": string (1-2 sentence description of what the task involves)
- "explanation": string (2-3 sentences explaining WHY this task is important for the goal)
- "guide": array of step objects with "step" (integer), "action" (string), "example" (string) keys
- "estimated_minutes": integer (realistic time estimate for this specific task)

Example structure — note how EACH day gets multiple tasks that together fill {daily_minutes} min:
{{
  "estimated_total_days": 30,
  "overview": "...",
  "tasks": [
    {{"day_number": 1, "title": "Task A for day 1", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t1}}},
    {{"day_number": 1, "title": "Task B for day 1", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t2}}},
    {{"day_number": 1, "title": "Task C for day 1", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t3}}},
    {{"day_number": 2, "title": "Task A for day 2", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t1}}},
    {{"day_number": 2, "title": "Task B for day 2", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t2}}},
    {{"day_number": 2, "title": "Task C for day 2", "description": "...", "explanation": "...", "guide": [{{"step": 1, "action": "...", "example": "..."}}], "estimated_minutes": {t3}}},
    "... continue this exact pattern for day 3, day 4, … day N"
  ]
}}

Before returning, verify: does every day_number from 1 to N appear in the tasks array? If any day is missing, add its tasks before outputting.

Return only the JSON object, no extra text.
"""
