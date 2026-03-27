import json
import uuid
from datetime import datetime, timedelta
from openai import AsyncOpenAI
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm.attributes import set_committed_value
from app.repositories.goal_repository import GoalRepository
from app.repositories.subscription_repository import SubscriptionRepository
from app.schemas.goal import GoalCreate, GoalUpdate
from app.models.goal import Goal
from app.models.goal_job import GoalJob
from app.models.plan import Plan
from app.models.task import Task
from app.models.user import User
from app.core.config import settings
from app.services.subscription_service import SubscriptionService
from app.utils.exceptions import NotFound, Forbidden


class GoalService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = GoalRepository(db)

    async def list_goals(self, user: User, page: int, page_size: int) -> tuple[list[Goal], int]:
        skip = (page - 1) * page_size
        items = await self.repo.get_by_user(user.id, skip=skip, limit=page_size)
        total = await self.repo.count_by_user(user.id)
        return items, total

    async def create_goal(self, user: User, data: GoalCreate) -> Goal:
        db = self.repo.db

        # 1. Determine subscription tier cap
        active_sub = await SubscriptionRepository(db).get_active_by_user(user.id)
        max_days = SubscriptionService.get_max_days_for_subscription(active_sub)

        # 2. Call OpenAI before touching the DB so the connection isn't held
        #    open during a potentially slow HTTP round-trip.
        duration = (data.target_date - data.start_date).days if data.mode == "duration" else None
        result = await _generate_tasks(
            goal_title=data.title,
            hours_per_day=data.hours_per_day,
            mode=data.mode,
            duration=duration,
            max_days=max_days,
        )
        tasks_data = result["tasks"]
        overview = result.get("overview")
        total_days = result["total_days"]   # real full goal duration (uncapped)
        # target_date reflects the full goal, not the subscription cap
        real_target_date = data.target_date if data.mode == "duration" else data.start_date + timedelta(days=total_days)

        try:
            # 3. Create goal row
            goal = Goal(
                user_id=user.id,
                title=data.title,
                description=data.description,
                start_date=data.start_date,
                target_date=real_target_date,
                stake_per_day=data.stake_per_day,
            )
            db.add(goal)
            await db.flush()  # assigns goal.id

            # 4. Create plan row — total_days is the full goal duration; tasks only cover the subscribed tier window
            plan = Plan(goal_id=goal.id, total_days=total_days, generated_by="ai", overview=overview, hours_per_day=data.hours_per_day)
            db.add(plan)
            await db.flush()  # assigns plan.id

            # 5. Create task rows
            tasks = [
                Task(
                    plan_id=plan.id,
                    day_number=item["day_number"],
                    execution_date=data.start_date + timedelta(days=item["day_number"] - 1),
                    title=item["title"],
                    description=item.get("description"),
                    explanation=item.get("explanation"),
                    guide=item.get("guide"),
                    estimated_minutes=item.get("estimated_minutes"),
                )
                for item in tasks_data
            ]
            for task in tasks:
                db.add(task)

            # 6. Single commit
            await db.commit()

            # 7. Refresh goal; plan/tasks have Python-side defaults, no refresh needed
            await db.refresh(goal)

            # Attach for GoalWithPlanOut serialisation
            set_committed_value(plan, "tasks", tasks)
            goal.plan = plan
            return goal

        except Exception:
            await db.rollback()
            raise

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

    async def enqueue_goal_job(self, user: User, data: GoalCreate) -> dict:
        """Create a GoalJob record and publish it to Kafka. Returns immediately."""
        # Lazy import to avoid circular dependency with kafka module.
        from app.kafka.producer import send_goal_job

        if data.mode == "duration":
            total_days = (data.target_date - data.start_date).days
        else:
            # Mode B: use the tier cap as the upper bound for time estimation
            active_sub = await SubscriptionRepository(self.repo.db).get_active_by_user(user.id)
            total_days = SubscriptionService.get_max_days_for_subscription(active_sub)

        # Formula: max(5, 5 + int(total_days * 0.15))
        # 30d→9s  60d→14s  90d→18s  180d→32s  365d→59s
        estimated_seconds = max(5, 5 + int(total_days * 0.15))

        payload = data.model_dump(mode="json")   # dates serialised as strings
        job = GoalJob(
            user_id=user.id,
            payload=payload,
            estimated_seconds=estimated_seconds,
        )
        db = self.repo.db
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

    if mode == "duration":
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

    if mode == "hours":
        estimated_total_days = parsed.get("estimated_total_days")
        if not isinstance(estimated_total_days, int) or estimated_total_days < 1:
            raise ValueError(f"Mode B response missing valid estimated_total_days: {content}")
        total_days = estimated_total_days
        plan_days = min(max(item["day_number"] for item in tasks), max_days)
    else:
        total_days = duration  # real full goal duration

    return {"overview": parsed.get("overview"), "tasks": tasks, "plan_days": plan_days, "total_days": total_days}


def _build_duration_prompt(title: str, full_duration: int, plan_days: int, hours_per_day: float, daily_minutes: int) -> str:
    cap_note = (
        f"Note: this is a {full_duration}-day goal but only the first {plan_days} days are being planned now."
        if plan_days < full_duration else ""
    )
    return f"""
You are a productivity coach. Generate a structured daily plan for the following goal.

Goal: {title}
Full goal duration: {full_duration} days
Available time per day: {hours_per_day} hours ({daily_minutes} minutes)
{cap_note}

Rules:
- Generate tasks for day 1 through day {plan_days} ONLY. Do not generate tasks beyond day {plan_days}.
- Every day from 1 to {plan_days} must have at least one task.
- Each day's tasks should have a combined estimated_minutes roughly equal to {daily_minutes} minutes.

Return a JSON object with exactly these two keys:
- "overview": string (2-3 sentences summarising the overall strategy and milestones for the full {full_duration}-day goal)
- "tasks": array of task objects

Each task object must have exactly these fields:
- "day_number": integer (1-based, between 1 and {plan_days})
- "title": string (short action title, max 10 words)
- "description": string (1-2 sentence description of what the task involves)
- "explanation": string (2-3 sentences explaining WHY this task is important for the goal and what benefit it brings)
- "guide": array of step objects — a numbered step-by-step guide for completing this specific task.
  Each step object has:
    - "step": integer (1-based)
    - "action": string (what to do in this step, clear and specific)
    - "example": string (a concrete example of doing that action, tailored to the goal)
- "estimated_minutes": integer (realistic time estimate for this specific task)

Example:
{{
  "overview": "This plan progressively builds your skill over {full_duration} days by alternating between learning and practice sessions.",
  "tasks": [
    {{
      "day_number": 1,
      "title": "Define your goal clearly",
      "description": "Write down a specific, measurable version of your goal and identify the first obstacle.",
      "explanation": "Clarity on your goal is the foundation of every successful plan. Without a precise target you will struggle to measure progress or stay motivated when things get hard.",
      "guide": [
        {{
          "step": 1,
          "action": "Open a blank document or notebook",
          "example": "Open Notes on your phone or a fresh page in your journal"
        }},
        {{
          "step": 2,
          "action": "Write your goal using the SMART format (Specific, Measurable, Achievable, Relevant, Time-bound)",
          "example": "Instead of 'get fit', write 'run 5 km without stopping by {full_duration} days from now'"
        }},
        {{
          "step": 3,
          "action": "List the single biggest obstacle you expect to face",
          "example": "e.g. 'I tend to skip sessions when I feel tired after work'"
        }}
      ],
      "estimated_minutes": 30
    }}
  ]
}}

Important: Return only the JSON object, no extra text.
"""


def _build_hours_prompt(title: str, hours_per_day: float, daily_minutes: int, max_days: int) -> str:
    return f"""
You are a productivity coach. A user wants to achieve the following goal and can commit
{hours_per_day} hours ({daily_minutes} minutes) per day.

Goal: {title}
Available time per day: {hours_per_day} hours ({daily_minutes} minutes)
Maximum tasks to generate: {max_days} days

First, estimate the total number of days needed to fully achieve this goal at {hours_per_day} hours/day.
Then generate tasks for the first {max_days} days only (or fewer if your estimate is less than {max_days}).

Rules:
- Do not generate tasks beyond day {max_days}.
- Every day from 1 to min(your estimate, {max_days}) must have at least one task.
- Each day's tasks should have a combined estimated_minutes roughly equal to {daily_minutes} minutes.

Return a JSON object with exactly these three keys:
- "estimated_total_days": integer — your estimate of the FULL days needed (can exceed {max_days})
- "overview": string (2-3 sentences summarising the overall strategy for the full goal)
- "tasks": array of task objects covering day 1 through min(estimated_total_days, {max_days})

Each task object must have exactly these fields:
- "day_number": integer (1-based, must not exceed {max_days})
- "title": string (short action title, max 10 words)
- "description": string (1-2 sentence description of what the task involves)
- "explanation": string (2-3 sentences explaining WHY this task is important for the goal)
- "guide": array of step objects with "step" (integer), "action" (string), "example" (string) keys
- "estimated_minutes": integer (realistic time estimate for this specific task)

Important: Return only the JSON object, no extra text.
"""
