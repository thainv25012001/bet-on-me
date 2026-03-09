import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.task import Task
from app.repositories.base import BaseRepository


class TaskRepository(BaseRepository[Task]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Task, db)

    async def get_by_plan(self, plan_id: uuid.UUID) -> list[Task]:
        result = await self.db.execute(select(Task).where(Task.plan_id == plan_id))
        return list(result.scalars().all())
