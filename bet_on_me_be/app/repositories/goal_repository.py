import uuid
from datetime import date
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.goal import Goal
from app.models.user import User
from app.repositories.base import BaseRepository
from app.utils.constants import GoalStatus


class GoalRepository(BaseRepository[Goal]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Goal, db)

    async def get_by_user(self, user_id: uuid.UUID, skip: int = 0, limit: int = 20) -> list[Goal]:
        result = await self.db.execute(
            select(Goal).where(Goal.user_id == user_id).order_by(Goal.created_at.desc()).offset(skip).limit(limit)
        )
        return list(result.scalars().all())

    async def count_by_user(self, user_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(func.count()).select_from(Goal).where(Goal.user_id == user_id)
        )
        return result.scalar_one()

    async def count_in_progress_by_user(self, user_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(func.count()).select_from(Goal).where(
                Goal.user_id == user_id,
                Goal.status == GoalStatus.IN_PROGRESS,
            )
        )
        return result.scalar_one()

    async def get_in_progress_past_target(self, cutoff: date) -> list[tuple[Goal, str]]:
        """Returns (goal, user_timezone) for in_progress goals where target_date <= cutoff."""
        result = await self.db.execute(
            select(Goal, User.timezone)
            .join(User, Goal.user_id == User.id)
            .where(Goal.status == GoalStatus.IN_PROGRESS, Goal.target_date <= cutoff)
        )
        return result.all()
