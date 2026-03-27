import uuid
from datetime import date
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.daily_reward import DailyReward
from app.repositories.base import BaseRepository
from app.utils.constants import DailyRewardStatus


class DailyRewardRepository(BaseRepository[DailyReward]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(DailyReward, db)

    async def get_by_goal_day(
        self, goal_id: uuid.UUID, execution_date: date
    ) -> DailyReward | None:
        result = await self.db.execute(
            select(DailyReward).where(
                DailyReward.goal_id == goal_id,
                DailyReward.execution_date == execution_date,
            )
        )
        return result.scalar_one_or_none()

    async def get_claimable_for_user(self, user_id: uuid.UUID) -> list[DailyReward]:
        result = await self.db.execute(
            select(DailyReward)
            .where(
                DailyReward.user_id == user_id,
                DailyReward.status == DailyRewardStatus.PENDING,
            )
            .order_by(DailyReward.created_at.desc())
        )
        return list(result.scalars().all())
