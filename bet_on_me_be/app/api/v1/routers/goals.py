import uuid
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.goal import GoalCreate, GoalUpdate, GoalOut
from app.schemas.common import success_response
from app.services.goal_service import GoalService

router = APIRouter(prefix="/goals", tags=["goals"])


@router.get("")
async def list_goals(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = GoalService(db)
    goals = await service.list_goals(current_user)
    return success_response([GoalOut.model_validate(g) for g in goals])


@router.post("")
async def create_goal(
    data: GoalCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = GoalService(db)
    goal = await service.create_goal(current_user, data)
    return success_response(GoalOut.model_validate(goal))


@router.get("/{goal_id}")
async def get_goal(
    goal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = GoalService(db)
    goal = await service.get_goal(goal_id, current_user)
    return success_response(GoalOut.model_validate(goal))


@router.patch("/{goal_id}")
async def update_goal(
    goal_id: uuid.UUID,
    data: GoalUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = GoalService(db)
    goal = await service.update_goal(goal_id, current_user, data)
    return success_response(GoalOut.model_validate(goal))


@router.delete("/{goal_id}")
async def delete_goal(
    goal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = GoalService(db)
    await service.delete_goal(goal_id, current_user)
    return success_response(None)
