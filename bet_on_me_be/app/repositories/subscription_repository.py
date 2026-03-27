import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models.subscription import Subscription
from app.repositories.base import BaseRepository


class SubscriptionRepository(BaseRepository[Subscription]):
    def __init__(self, db: AsyncSession) -> None:
        super().__init__(Subscription, db)

    async def get_active_by_user(self, user_id: uuid.UUID) -> Subscription | None:
        result = await self.db.execute(
            select(Subscription)
            .options(joinedload(Subscription.plan))
            .where(Subscription.user_id == user_id, Subscription.status == "active")
            .order_by(Subscription.created_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    async def get_by_user(
        self, user_id: uuid.UUID, skip: int = 0, limit: int = 20
    ) -> list[Subscription]:
        result = await self.db.execute(
            select(Subscription)
            .options(joinedload(Subscription.plan))
            .where(Subscription.user_id == user_id)
            .order_by(Subscription.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(result.scalars().all())
