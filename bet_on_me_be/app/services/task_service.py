import uuid
from datetime import date
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.task_repository import TaskRepository
from app.repositories.plan_repository import PlanRepository
from app.repositories.goal_repository import GoalRepository
from app.schemas.task import TaskCreate
from app.models.goal import Goal
from app.models.plan import Plan
from app.models.task import Task
from app.models.user import User
from app.utils.constants import GoalStatus, TaskStatus
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

    async def list_tasks(self, plan_id: uuid.UUID, user: User, page: int, page_size: int) -> tuple[list[Task], int]:
        await self._check_plan_ownership(plan_id, user)
        skip = (page - 1) * page_size
        items = await self.repo.get_by_plan(plan_id, skip=skip, limit=page_size)
        total = await self.repo.count_by_plan(plan_id)
        return items, total

    async def create_task(self, plan_id: uuid.UUID, user: User, data: TaskCreate) -> Task:
        await self._check_plan_ownership(plan_id, user)
        return await self.repo.create(plan_id=plan_id, **data.model_dump())

    async def get_task(self, task_id: uuid.UUID, user: User) -> Task:
        task = await self.repo.get(task_id)
        if not task:
            raise NotFound("Task")
        await self._check_plan_ownership(task.plan_id, user)
        return task

    async def get_today_tasks(self, user: User) -> list[dict]:
        return await self.repo.get_today_for_user(user.id, date.today())

    async def update_task_status(self, task_id: uuid.UUID, user: User, status: str) -> Task:
        task = await self.get_task(task_id, user)
        updated = await self.repo.update(task, status=status)
        if status == TaskStatus.SUCCESS:
            await self._maybe_evaluate_goal(task)
        return updated

    async def _maybe_evaluate_goal(self, task: Task) -> None:
        """Trigger goal evaluation immediately when a task is marked success."""
        from app.services.goal_service import GoalService
        db = self.repo.db

        plan = await db.get(Plan, task.plan_id)
        if plan is None:
            return

        goal_result = await db.execute(
            select(Goal).where(Goal.id == plan.goal_id, Goal.status == GoalStatus.IN_PROGRESS)
        )
        goal = goal_result.scalar_one_or_none()
        if goal is None:
            return

        await GoalService(db).evaluate_goal_status(goal)
