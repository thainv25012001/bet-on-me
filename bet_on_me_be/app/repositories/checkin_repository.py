import uuid
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.checkin import Checkin
from app.repositories.base import BaseRepository


class CheckinRepository(BaseRepository[Checkin]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Checkin, db)

    async def get_by_task(self, task_id: uuid.UUID, skip: int = 0, limit: int = 20) -> list[Checkin]:
        result = await self.db.execute(
            select(Checkin).where(Checkin.task_id == task_id).offset(skip).limit(limit)
        )
        return list(result.scalars().all())

    async def count_by_task(self, task_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(func.count()).select_from(Checkin).where(Checkin.task_id == task_id)
        )
        return result.scalar_one()
