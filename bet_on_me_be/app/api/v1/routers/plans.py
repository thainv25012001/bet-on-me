import uuid
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.plan import PlanCreate, PlanOut
from app.schemas.common import success_response
from app.services.plan_service import PlanService

router = APIRouter(tags=["plans"])


@router.get("/goals/{goal_id}/plans")
async def list_plans(
    goal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = PlanService(db)
    plans = await service.list_plans(goal_id, current_user)
    return success_response([PlanOut.model_validate(p) for p in plans])


@router.post("/goals/{goal_id}/plans")
async def create_plan(
    goal_id: uuid.UUID,
    data: PlanCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = PlanService(db)
    plan = await service.create_plan(goal_id, current_user, data)
    return success_response(PlanOut.model_validate(plan))
