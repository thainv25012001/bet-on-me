import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.checkin import Checkin
from app.repositories.base import BaseRepository


class CheckinRepository(BaseRepository[Checkin]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Checkin, db)

    async def get_by_task(self, task_id: uuid.UUID) -> list[Checkin]:
        result = await self.db.execute(select(Checkin).where(Checkin.task_id == task_id))
        return list(result.scalars().all())
