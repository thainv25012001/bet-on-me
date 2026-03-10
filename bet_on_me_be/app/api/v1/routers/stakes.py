import uuid
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.stake import StakeCreate, StakeOut
from app.schemas.common import success_response, paginated_response
from app.services.stake_service import StakeService

router = APIRouter(tags=["stakes"])


@router.get("/goals/{goal_id}/stakes")
async def list_stakes(
    goal_id: uuid.UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = StakeService(db)
    items, total = await service.list_stakes(goal_id, current_user, page, page_size)
    return paginated_response([StakeOut.model_validate(s) for s in items], total, page, page_size)


@router.post("/goals/{goal_id}/stakes")
async def create_stake(
    goal_id: uuid.UUID,
    data: StakeCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = StakeService(db)
    stake = await service.create_stake(goal_id, current_user, data)
    return success_response(StakeOut.model_validate(stake))
