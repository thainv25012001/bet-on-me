import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.checkin_repository import CheckinRepository
from app.repositories.task_repository import TaskRepository
from app.repositories.plan_repository import PlanRepository
from app.repositories.goal_repository import GoalRepository
from app.schemas.checkin import CheckinCreate, CheckinUpdate
from app.models.checkin import Checkin
from app.models.user import User
from app.utils.exceptions import NotFound, Forbidden


class CheckinService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = CheckinRepository(db)
        self.task_repo = TaskRepository(db)
        self.plan_repo = PlanRepository(db)
        self.goal_repo = GoalRepository(db)

    async def _verify_task_ownership(self, task_id: uuid.UUID, user: User):
        task = await self.task_repo.get(task_id)
        if not task:
            raise NotFound("Task")
        plan = await self.plan_repo.get(task.plan_id)
        if not plan:
            raise NotFound("Plan")
        goal = await self.goal_repo.get(plan.goal_id)
        if not goal or str(goal.user_id) != str(user.id):
            raise Forbidden()
        return task

    async def list_checkins(self, task_id: uuid.UUID, user: User, page: int, page_size: int) -> tuple[list[Checkin], int]:
        await self._verify_task_ownership(task_id, user)
        skip = (page - 1) * page_size
        items = await self.repo.get_by_task(task_id, skip=skip, limit=page_size)
        total = await self.repo.count_by_task(task_id)
        return items, total

    async def create_checkin(self, task_id: uuid.UUID, user: User, data: CheckinCreate) -> Checkin:
        await self._verify_task_ownership(task_id, user)
        return await self.repo.create(task_id=task_id, user_id=user.id, **data.model_dump())

    async def update_checkin(self, checkin_id: uuid.UUID, user: User, data: CheckinUpdate) -> Checkin:
        checkin = await self.repo.get(checkin_id)
        if not checkin:
            raise NotFound("Checkin")
        if str(checkin.user_id) != str(user.id):
            raise Forbidden()
        return await self.repo.update(checkin, **data.model_dump(exclude_unset=True))
