import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.goal import Goal
from app.repositories.base import BaseRepository


class GoalRepository(BaseRepository[Goal]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Goal, db)

    async def get_by_user(self, user_id: uuid.UUID) -> list[Goal]:
        result = await self.db.execute(select(Goal).where(Goal.user_id == user_id))
        return list(result.scalars().all())
