import uuid
from datetime import date, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.subscription import Subscription
from app.models.subscription_plan import SubscriptionPlan
from app.models.user import User
from app.repositories.subscription_plan_repository import SubscriptionPlanRepository
from app.repositories.subscription_repository import SubscriptionRepository
from app.schemas.subscription import PlanDiscountUpdate, SubscriptionCreate
from app.utils.constants import SubscriptionStatus
from app.utils.exceptions import BadRequest, NotFound


class SubscriptionService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = SubscriptionRepository(db)
        self.plan_repo = SubscriptionPlanRepository(db)

    async def list_plans(self, today: date) -> list[SubscriptionPlan]:
        return await self.plan_repo.get_all_ordered()

    async def subscribe(self, user: User, data: SubscriptionCreate) -> Subscription:
        plan = await self.plan_repo.get_by_tier(data.tier)
        if not plan:
            raise NotFound("SubscriptionPlan")

        # Cancel any existing active subscription
        existing = await self.repo.get_active_by_user(user.id)
        if existing:
            await self.repo.update(existing, status=SubscriptionStatus.CANCELLED)

        # Apply active discount if any
        today = data.started_at
        discount_active = (
            plan.discount_percent is not None
            and plan.discount_valid_from is not None
            and plan.discount_valid_to is not None
            and plan.discount_valid_from <= today <= plan.discount_valid_to
        )
        price_paid = (
            int(plan.price_cents * (1 - plan.discount_percent / 100))
            if discount_active
            else plan.price_cents
        )
        expires_at = data.started_at + timedelta(days=plan.expires_after_days)

        sub = await self.repo.create(
            user_id=user.id,
            plan_id=plan.id,
            status=SubscriptionStatus.ACTIVE,
            started_at=data.started_at,
            expires_at=expires_at,
            price_paid=price_paid,
            currency=data.currency,
        )
        # Attach the already-loaded plan to avoid a lazy-load outside async context.
        sub.plan = plan
        return sub

    async def get_active(self, user: User) -> Subscription | None:
        return await self.repo.get_active_by_user(user.id)

    async def cancel(self, user: User) -> None:
        sub = await self.repo.get_active_by_user(user.id)
        if not sub:
            raise BadRequest("No active subscription to cancel")
        await self.repo.update(sub, status=SubscriptionStatus.CANCELLED)

    async def update_plan_discount(
        self, tier: str, data: PlanDiscountUpdate
    ) -> SubscriptionPlan:
        plan = await self.plan_repo.get_by_tier(tier)
        if not plan:
            raise NotFound("SubscriptionPlan")
        # Pass None explicitly to clear a discount when fields are omitted.
        return await self.plan_repo.update(
            plan,
            discount_percent=data.discount_percent,
            discount_valid_from=data.discount_valid_from,
            discount_valid_to=data.discount_valid_to,
        )

    @staticmethod
    def get_max_days_for_subscription(subscription: Subscription | None) -> int:
        if subscription is None or subscription.plan is None:
            return 7  # free tier default
        return subscription.plan.max_plan_days

    @staticmethod
    def get_goal_limit_for_subscription(subscription: Subscription | None) -> int:
        if subscription is None or subscription.plan is None:
            return 2  # free tier default
        return subscription.plan.total_goal_limit
