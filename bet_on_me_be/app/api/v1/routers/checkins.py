import uuid
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.checkin import CheckinCreate, CheckinUpdate, CheckinOut
from app.schemas.common import success_response
from app.services.checkin_service import CheckinService

router = APIRouter(tags=["checkins"])


@router.get("/tasks/{task_id}/checkins")
async def list_checkins(
    task_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = CheckinService(db)
    checkins = await service.list_checkins(task_id, current_user)
    return success_response([CheckinOut.model_validate(c) for c in checkins])


@router.post("/tasks/{task_id}/checkins")
async def create_checkin(
    task_id: uuid.UUID,
    data: CheckinCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = CheckinService(db)
    checkin = await service.create_checkin(task_id, current_user, data)
    return success_response(CheckinOut.model_validate(checkin))


@router.patch("/checkins/{checkin_id}")
async def update_checkin(
    checkin_id: uuid.UUID,
    data: CheckinUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = CheckinService(db)
    checkin = await service.update_checkin(checkin_id, current_user, data)
    return success_response(CheckinOut.model_validate(checkin))
