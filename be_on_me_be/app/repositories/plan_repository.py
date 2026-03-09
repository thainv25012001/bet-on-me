import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.plan import Plan
from app.repositories.base import BaseRepository


class PlanRepository(BaseRepository[Plan]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Plan, db)

    async def get_by_goal(self, goal_id: uuid.UUID) -> list[Plan]:
        result = await self.db.execute(select(Plan).where(Plan.goal_id == goal_id))
        return list(result.scalars().all())
