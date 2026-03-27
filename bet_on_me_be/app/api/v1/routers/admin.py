from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_admin_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.common import success_response
from app.schemas.subscription import PlanDiscountUpdate, SubscriptionPlanOut
from app.services.subscription_service import SubscriptionService
from datetime import date

router = APIRouter(prefix="/admin", tags=["admin"])


@router.patch("/plans/{tier}", response_model=None)
async def update_plan_discount(
    tier: str,
    data: PlanDiscountUpdate,
    _: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    """Set or clear a discount on a subscription plan."""
    service = SubscriptionService(db)
    plan = await service.update_plan_discount(tier, data)
    return success_response(SubscriptionPlanOut.from_plan(plan, date.today()))
