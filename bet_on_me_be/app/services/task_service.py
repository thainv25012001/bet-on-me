import uuid
from datetime import date
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.task_repository import TaskRepository
from app.repositories.plan_repository import PlanRepository
from app.repositories.goal_repository import GoalRepository
from app.repositories.daily_reward_repository import DailyRewardRepository
from app.schemas.task import TaskCreate, TaskStatusUpdateOut, DailyRewardInfo
from app.models.goal import Goal
from app.models.plan import Plan
from app.models.task import Task
from app.models.stake import Stake
from app.models.daily_reward import DailyReward
from app.models.user import User
from app.utils.constants import GoalStatus, TaskStatus, StakeStatus, DailyRewardStatus
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

    async def update_task_status(
        self, task_id: uuid.UUID, user: User, status: str
    ) -> TaskStatusUpdateOut:
        task = await self.get_task(task_id, user)
        updated = await self.repo.update(task, status=status)
        daily_reward_info: DailyRewardInfo | None = None
        day_complete = False
        if status == TaskStatus.SUCCESS:
            await self._maybe_evaluate_goal(task)
            day_complete, daily_reward_info = await self._maybe_create_daily_reward(
                updated, user
            )
        from app.schemas.task import TaskOut
        return TaskStatusUpdateOut(
            task=TaskOut.model_validate(updated),
            day_complete=day_complete,
            daily_reward=daily_reward_info,
        )

    async def _maybe_create_daily_reward(
        self, task: Task, user: User
    ) -> tuple[bool, DailyRewardInfo | None]:
        """If all tasks for this task's execution_date+goal are done, create a DailyReward."""
        if task.execution_date is None:
            return False, None

        db = self.repo.db

        # Count total and done tasks for this plan+date.
        total_result = await db.execute(
            select(func.count()).select_from(Task).where(
                Task.plan_id == task.plan_id,
                Task.execution_date == task.execution_date,
            )
        )
        total = total_result.scalar_one()

        done_result = await db.execute(
            select(func.count()).select_from(Task).where(
                Task.plan_id == task.plan_id,
                Task.execution_date == task.execution_date,
                Task.status == TaskStatus.SUCCESS,
            )
        )
        done = done_result.scalar_one()

        if total == 0 or done < total:
            return False, None

        # All done — get goal_id from plan.
        plan = await db.get(Plan, task.plan_id)
        if plan is None:
            return True, None

        reward_repo = DailyRewardRepository(db)
        existing = await reward_repo.get_by_goal_day(plan.goal_id, task.execution_date)
        if existing:
            return True, DailyRewardInfo(id=existing.id, amount=existing.amount)

        # Get active stake to know amount_per_day.
        stake_result = await db.execute(
            select(Stake).where(
                Stake.goal_id == plan.goal_id,
                Stake.status == StakeStatus.ACTIVE,
            )
        )
        stake = stake_result.scalar_one_or_none()
        amount = stake.amount_per_day if stake and stake.amount_per_day else 0

        reward = DailyReward(
            user_id=user.id,
            goal_id=plan.goal_id,
            stake_id=stake.id if stake else uuid.uuid4(),
            execution_date=task.execution_date,
            amount=amount,
            status=DailyRewardStatus.PENDING,
        )
        db.add(reward)
        await db.commit()
        await db.refresh(reward)
        return True, DailyRewardInfo(id=reward.id, amount=reward.amount)

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
