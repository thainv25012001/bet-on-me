import uuid
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.goal import GoalCreate, GoalUpdate, GoalOut
from app.schemas.common import success_response, paginated_response
from app.services.goal_service import GoalService

router = APIRouter(prefix="/goals", tags=["goals"])


@router.get("")
async def list_goals(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = GoalService(db)
    items, total = await service.list_goals(current_user, page, page_size)
    return paginated_response([GoalOut.model_validate(g) for g in items], total, page, page_size)


@router.post("", status_code=202)
async def create_goal(
    data: GoalCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Enqueue a goal-creation job. Returns job_id and estimated wait time."""
    service = GoalService(db)
    result = await service.enqueue_goal_job(current_user, data)
    return success_response(result)


# NOTE: /jobs/{job_id} is registered BEFORE /{goal_id} so FastAPI does not
# try to parse the literal string "jobs" as a UUID.
@router.get("/jobs/{job_id}")
async def get_goal_job(
    job_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Poll the status of a goal-creation job."""
    service = GoalService(db)
    result = await service.get_job_status(job_id, current_user)
    return success_response(result)


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
