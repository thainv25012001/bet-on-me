from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.subscription_plan import SubscriptionPlan
from app.repositories.base import BaseRepository


class SubscriptionPlanRepository(BaseRepository[SubscriptionPlan]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(SubscriptionPlan, db)

    async def get_by_tier(self, tier: str) -> SubscriptionPlan | None:
        result = await self.db.execute(
            select(SubscriptionPlan).where(SubscriptionPlan.tier == tier)
        )
        return result.scalar_one_or_none()

    async def get_all_ordered(self) -> list[SubscriptionPlan]:
        result = await self.db.execute(
            select(SubscriptionPlan).order_by(SubscriptionPlan.price_cents)
        )
        return list(result.scalars().all())
