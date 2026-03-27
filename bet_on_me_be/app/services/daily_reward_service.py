import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.daily_reward_repository import DailyRewardRepository
from app.models.daily_reward import DailyReward
from app.models.user import User
from app.utils.constants import DailyRewardStatus
from app.utils.exceptions import NotFound, Forbidden, BadRequest


class DailyRewardService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = DailyRewardRepository(db)

    async def list_claimable(self, user: User) -> list[DailyReward]:
        return await self.repo.get_claimable_for_user(user.id)

    async def claim(self, reward_id: uuid.UUID, user: User) -> DailyReward:
        reward = await self.repo.get(reward_id)
        if not reward:
            raise NotFound("DailyReward")
        if str(reward.user_id) != str(user.id):
            raise Forbidden()
        if reward.status != DailyRewardStatus.PENDING:
            raise BadRequest("Reward already claimed")
        return await self.repo.update(reward, status=DailyRewardStatus.CLAIMED)
