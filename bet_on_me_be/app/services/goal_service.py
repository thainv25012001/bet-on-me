import json
import uuid
from openai import AsyncOpenAI
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm.attributes import set_committed_value
from app.repositories.goal_repository import GoalRepository
from app.schemas.goal import GoalCreate, GoalUpdate
from app.models.goal import Goal
from app.models.plan import Plan
from app.models.task import Task
from app.models.user import User
from app.core.config import settings
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

        # 1. Call OpenAI before touching the DB so the connection isn't held
        #    open during a potentially slow HTTP round-trip.
        duration = (data.target_date - data.start_date).days
        tasks_data = await _generate_tasks(data.title, duration)

        try:
            # 2. Create goal row
            goal = Goal(user_id=user.id, **data.model_dump())
            db.add(goal)
            await db.flush()  # assigns goal.id

            # 3. Create plan row
            plan = Plan(goal_id=goal.id, total_days=duration, generated_by="ai")
            db.add(plan)
            await db.flush()  # assigns plan.id

            # 4. Create task rows
            tasks = [
                Task(
                    plan_id=plan.id,
                    day_number=item["day_number"],
                    title=item["title"],
                    description=item.get("description"),
                    estimated_minutes=item.get("estimated_minutes"),
                )
                for item in tasks_data
            ]
            for task in tasks:
                db.add(task)

            # 5. Single commit
            await db.commit()

            # 6. Refresh goal; plan/tasks have Python-side defaults, no refresh needed
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


async def _generate_tasks(goal_title: str, duration: int) -> list[dict]:
    client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
    prompt = f"""
You are a productivity coach. Generate a structured daily plan for the following goal.

Goal: {goal_title}
Duration: {duration} days

Return a JSON object with a single key "tasks" whose value is an array.
Each element must have exactly these fields:
- "day_number": integer (1-based day index)
- "title": string (short action title, max 10 words)
- "description": string (1-2 sentence explanation of what to do)
- "estimated_minutes": integer (realistic time estimate for that day's task)

Example:
{{
  "tasks": [
    {{
      "day_number": 1,
      "title": "Define your goal clearly",
      "description": "Write down a specific, measurable version of your goal and identify the first obstacle.",
      "estimated_minutes": 30
    }}
  ]
}}

Return only the JSON object, no extra text.
"""
    response = await client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
    )
    content = response.choices[0].message.content
    parsed = json.loads(content)
    if isinstance(parsed, list):
        return parsed
    if "tasks" in parsed:
        return parsed["tasks"]
    for v in parsed.values():
        if isinstance(v, list):
            return v
    raise ValueError(f"Unexpected OpenAI response shape: {content}")
