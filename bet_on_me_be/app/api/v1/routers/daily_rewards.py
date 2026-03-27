import uuid
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.daily_reward import DailyRewardOut
from app.schemas.common import success_response
from app.services.daily_reward_service import DailyRewardService

router = APIRouter(prefix="/daily-rewards", tags=["daily-rewards"])


@router.get("")
async def list_claimable_rewards(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return all unclaimed daily rewards for the current user."""
    service = DailyRewardService(db)
    rewards = await service.list_claimable(current_user)
    return success_response([DailyRewardOut.model_validate(r) for r in rewards])


@router.post("/{reward_id}/claim")
async def claim_reward(
    reward_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mark a pending daily reward as claimed."""
    service = DailyRewardService(db)
    reward = await service.claim(reward_id, current_user)
    return success_response(DailyRewardOut.model_validate(reward))
