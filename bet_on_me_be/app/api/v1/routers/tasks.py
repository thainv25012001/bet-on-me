import uuid
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.task import TaskCreate, TaskOut, TaskStatusUpdate, TaskTodayOut, TaskStatusUpdateOut
from app.schemas.common import success_response, paginated_response
from app.services.task_service import TaskService

router = APIRouter(tags=["tasks"])


@router.get("/plans/{plan_id}/tasks")
async def list_tasks(
    plan_id: uuid.UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = TaskService(db)
    items, total = await service.list_tasks(plan_id, current_user, page, page_size)
    return paginated_response([TaskOut.model_validate(t) for t in items], total, page, page_size)


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


@router.get("/tasks/today")
async def get_today_tasks(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = TaskService(db)
    items = await service.get_today_tasks(current_user)
    return success_response([TaskTodayOut(**item) for item in items])


@router.get("/tasks/{task_id}")
async def get_task(
    task_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = TaskService(db)
    task = await service.get_task(task_id, current_user)
    return success_response(TaskOut.model_validate(task))


@router.patch("/tasks/{task_id}/status")
async def update_task_status(
    task_id: uuid.UUID,
    data: TaskStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = TaskService(db)
    result = await service.update_task_status(task_id, current_user, data.status)
    return success_response(result.model_dump())
