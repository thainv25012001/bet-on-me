import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.task_repository import TaskRepository
from app.repositories.plan_repository import PlanRepository
from app.repositories.goal_repository import GoalRepository
from app.schemas.task import TaskCreate
from app.models.task import Task
from app.models.user import User
from app.utils.exceptions import NotFound, Forbidden


class TaskService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = TaskRepository(db)
        self.plan_repo = PlanRepository(db)
        self.goal_repo = GoalRepository(db)

    async def _check_plan_ownership(self, plan_id: uuid.UUID, user: User):
        plan = await self.plan_repo.get(plan_id)
        if not plan:
            raise NotFound("Plan")
        goal = await self.goal_repo.get(plan.goal_id)
        if not goal or str(goal.user_id) != str(user.id):
            raise Forbidden()
        return plan

    async def list_tasks(self, plan_id: uuid.UUID, user: User) -> list[Task]:
        await self._check_plan_ownership(plan_id, user)
        return await self.repo.get_by_plan(plan_id)

    async def create_task(self, plan_id: uuid.UUID, user: User, data: TaskCreate) -> Task:
        await self._check_plan_ownership(plan_id, user)
        return await self.repo.create(plan_id=plan_id, **data.model_dump())

    async def get_task(self, task_id: uuid.UUID, user: User) -> Task:
        task = await self.repo.get(task_id)
        if not task:
            raise NotFound("Task")
        await self._check_plan_ownership(task.plan_id, user)
        return task
