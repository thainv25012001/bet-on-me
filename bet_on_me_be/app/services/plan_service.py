import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.plan_repository import PlanRepository
from app.repositories.goal_repository import GoalRepository
from app.schemas.plan import PlanCreate
from app.models.plan import Plan
from app.models.user import User
from app.utils.exceptions import NotFound, Forbidden


class PlanService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = PlanRepository(db)
        self.goal_repo = GoalRepository(db)

    async def list_plans(self, goal_id: uuid.UUID, user: User, page: int, page_size: int) -> tuple[list[Plan], int]:
        goal = await self.goal_repo.get(goal_id)
        if not goal:
            raise NotFound("Goal")
        if str(goal.user_id) != str(user.id):
            raise Forbidden()
        skip = (page - 1) * page_size
        items = await self.repo.get_by_goal(goal_id, skip=skip, limit=page_size)
        total = await self.repo.count_by_goal(goal_id)
        return items, total

    async def create_plan(self, goal_id: uuid.UUID, user: User, data: PlanCreate) -> Plan:
        goal = await self.goal_repo.get(goal_id)
        if not goal:
            raise NotFound("Goal")
        if str(goal.user_id) != str(user.id):
            raise Forbidden()
        return await self.repo.create(goal_id=goal_id, **data.model_dump())
