import uuid
from datetime import date
from sqlalchemy import select, func, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.task import Task
from app.models.plan import Plan
from app.models.goal import Goal
from app.repositories.base import BaseRepository
from app.utils.constants import GoalStatus, TaskStatus


class TaskRepository(BaseRepository[Task]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Task, db)

    async def get_by_plan(self, plan_id: uuid.UUID, skip: int = 0, limit: int = 20) -> list[Task]:
        result = await self.db.execute(
            select(Task).where(Task.plan_id == plan_id).order_by(Task.day_number.asc()).offset(skip).limit(limit)
        )
        return list(result.scalars().all())

    async def count_by_plan(self, plan_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(func.count()).select_from(Task).where(Task.plan_id == plan_id)
        )
        return result.scalar_one()

    async def count_success_by_plan(self, plan_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(func.count()).select_from(Task)
            .where(Task.plan_id == plan_id, Task.status == TaskStatus.SUCCESS)
        )
        return result.scalar_one()

    async def fail_overdue_tasks(self, today: date) -> int:
        """Mark all pending tasks whose execution_date is before today as failed.

        Only affects tasks belonging to in_progress goals so completed/failed
        goals are left untouched.  Returns the number of rows updated.
        """
        in_progress_goal_ids = (
            select(Goal.id)
            .join(Plan, Plan.goal_id == Goal.id)
            .where(Goal.status == GoalStatus.IN_PROGRESS)
        )
        result = await self.db.execute(
            update(Task)
            .where(
                Task.status == TaskStatus.PENDING,
                Task.execution_date < today,
                Task.plan_id.in_(
                    select(Plan.id).where(Plan.goal_id.in_(in_progress_goal_ids))
                ),
            )
            .values(status=TaskStatus.FAILED)
        )
        return result.rowcount

    async def get_today_for_user(self, user_id: uuid.UUID, today: date) -> list[dict]:
        stmt = (
            select(
                Task.id,
                Task.title,
                Task.description,
                Task.explanation,
                Task.guide,
                Task.estimated_minutes,
                Task.day_number,
                Task.execution_date,
                Task.status,
                Goal.id.label("goal_id"),
                Goal.title.label("goal_title"),
                Plan.total_days,
            )
            .join(Plan, Task.plan_id == Plan.id)
            .join(Goal, Plan.goal_id == Goal.id)
            .where(
                Goal.user_id == user_id,
                Goal.status == GoalStatus.IN_PROGRESS,
                Task.execution_date == today,
            )
            .order_by(Goal.id, Task.day_number)
        )
        result = await self.db.execute(stmt)
        return [dict(r) for r in result.mappings().all()]
