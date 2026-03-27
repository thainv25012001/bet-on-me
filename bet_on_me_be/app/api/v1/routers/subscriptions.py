from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.common import success_response
from app.schemas.subscription import (
    SubscriptionCreate,
    SubscriptionPlanOut,
    UserSubscriptionOut,
)
from app.services.subscription_service import SubscriptionService

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])


@router.get("/plans", response_model=None)
async def list_plans(db: AsyncSession = Depends(get_db)):
    """List all subscription plans with live pricing and active discount info."""
    service = SubscriptionService(db)
    today = date.today()
    plans = await service.list_plans(today)
    return success_response(
        [SubscriptionPlanOut.from_plan(p, today) for p in plans]
    )


@router.get("", response_model=None)
async def list_my_subscriptions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return full subscription history for the current user."""
    service = SubscriptionService(db)
    today = date.today()
    subs = await service.repo.get_by_user(current_user.id)
    result = []
    for s in subs:
        out = UserSubscriptionOut.model_validate(s)
        if s.plan:
            out.plan = SubscriptionPlanOut.from_plan(s.plan, today)
        result.append(out)
    return success_response(result)


@router.post("", status_code=201, response_model=None)
async def subscribe(
    data: SubscriptionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Subscribe to a plan. Cancels any existing active subscription first."""
    service = SubscriptionService(db)
    sub = await service.subscribe(current_user, data)
    out = UserSubscriptionOut.model_validate(sub)
    if sub.plan:
        out.plan = SubscriptionPlanOut.from_plan(sub.plan, data.started_at)
    return success_response(out)


@router.get("/me", response_model=None)
async def get_active_subscription(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return the current user's active subscription, or null if none."""
    service = SubscriptionService(db)
    sub = await service.get_active(current_user)
    if sub is None:
        return success_response(None)
    out = UserSubscriptionOut.model_validate(sub)
    if sub.plan:
        out.plan = SubscriptionPlanOut.from_plan(sub.plan, date.today())
    return success_response(out)


@router.delete("/me", response_model=None)
async def cancel_subscription(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cancel the current user's active subscription."""
    service = SubscriptionService(db)
    await service.cancel(current_user)
    return success_response(None)
