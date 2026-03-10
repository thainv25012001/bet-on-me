import uuid
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.stake import Stake
from app.repositories.base import BaseRepository


class StakeRepository(BaseRepository[Stake]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Stake, db)

    async def get_by_goal(self, goal_id: uuid.UUID, skip: int = 0, limit: int = 20) -> list[Stake]:
        result = await self.db.execute(
            select(Stake).where(Stake.goal_id == goal_id).offset(skip).limit(limit)
        )
        return list(result.scalars().all())

    async def count_by_goal(self, goal_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(func.count()).select_from(Stake).where(Stake.goal_id == goal_id)
        )
        return result.scalar_one()
