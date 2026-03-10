import uuid
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.task import Task
from app.repositories.base import BaseRepository


class TaskRepository(BaseRepository[Task]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Task, db)

    async def get_by_plan(self, plan_id: uuid.UUID, skip: int = 0, limit: int = 20) -> list[Task]:
        result = await self.db.execute(
            select(Task).where(Task.plan_id == plan_id).offset(skip).limit(limit)
        )
        return list(result.scalars().all())

    async def count_by_plan(self, plan_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(func.count()).select_from(Task).where(Task.plan_id == plan_id)
        )
        return result.scalar_one()
