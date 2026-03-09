import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.stake import Stake
from app.repositories.base import BaseRepository


class StakeRepository(BaseRepository[Stake]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Stake, db)

    async def get_by_goal(self, goal_id: uuid.UUID) -> list[Stake]:
        result = await self.db.execute(select(Stake).where(Stake.goal_id == goal_id))
        return list(result.scalars().all())
