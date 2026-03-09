import uuid
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.task import TaskCreate, TaskOut
from app.schemas.common import success_response
from app.services.task_service import TaskService

router = APIRouter(tags=["tasks"])


@router.get("/plans/{plan_id}/tasks")
async def list_tasks(
    plan_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = TaskService(db)
    tasks = await service.list_tasks(plan_id, current_user)
    return success_response([TaskOut.model_validate(t) for t in tasks])


@router.post("/plans/{plan_id}/tasks")
async def create_task(
    plan_id: uuid.UUID,
    data: TaskCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = TaskService(db)
    task = await service.create_task(plan_id, current_user, data)
    return success_response(TaskOut.model_validate(task))


@router.get("/tasks/{task_id}")
async def get_task(
    task_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = TaskService(db)
    task = await service.get_task(task_id, current_user)
    return success_response(TaskOut.model_validate(task))
