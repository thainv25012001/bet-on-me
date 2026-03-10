import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.stake_repository import StakeRepository
from app.repositories.goal_repository import GoalRepository
from app.schemas.stake import StakeCreate
from app.models.stake import Stake
from app.models.user import User
from app.utils.exceptions import NotFound, Forbidden


class StakeService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = StakeRepository(db)
        self.goal_repo = GoalRepository(db)

    async def _check_goal_ownership(self, goal_id: uuid.UUID, user: User):
        goal = await self.goal_repo.get(goal_id)
        if not goal:
            raise NotFound("Goal")
        if str(goal.user_id) != str(user.id):
            raise Forbidden()
        return goal

    async def list_stakes(self, goal_id: uuid.UUID, user: User, page: int, page_size: int) -> tuple[list[Stake], int]:
        await self._check_goal_ownership(goal_id, user)
        skip = (page - 1) * page_size
        items = await self.repo.get_by_goal(goal_id, skip=skip, limit=page_size)
        total = await self.repo.count_by_goal(goal_id)
        return items, total

    async def create_stake(self, goal_id: uuid.UUID, user: User, data: StakeCreate) -> Stake:
        await self._check_goal_ownership(goal_id, user)
        return await self.repo.create(goal_id=goal_id, user_id=user.id, **data.model_dump())
