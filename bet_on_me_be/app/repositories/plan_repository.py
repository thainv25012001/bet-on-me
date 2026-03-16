import uuid
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.plan import Plan
from app.repositories.base import BaseRepository


class PlanRepository(BaseRepository[Plan]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Plan, db)

    async def get_by_goal(self, goal_id: uuid.UUID, skip: int = 0, limit: int = 20) -> list[Plan]:
        result = await self.db.execute(
            select(Plan).where(Plan.goal_id == goal_id).options(selectinload(Plan.tasks)).offset(skip).limit(limit)
        )
        return list(result.scalars().all())

    async def count_by_goal(self, goal_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(func.count()).select_from(Plan).where(Plan.goal_id == goal_id)
        )
        return result.scalar_one()
