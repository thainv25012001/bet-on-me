import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.goal_repository import GoalRepository
from app.schemas.goal import GoalCreate, GoalUpdate
from app.models.goal import Goal
from app.models.user import User
from app.utils.exceptions import NotFound, Forbidden


class GoalService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = GoalRepository(db)

    async def list_goals(self, user: User) -> list[Goal]:
        return await self.repo.get_by_user(user.id)

    async def create_goal(self, user: User, data: GoalCreate) -> Goal:
        return await self.repo.create(user_id=user.id, **data.model_dump())

    async def get_goal(self, goal_id: uuid.UUID, user: User) -> Goal:
        goal = await self.repo.get(goal_id)
        if not goal:
            raise NotFound("Goal")
        if str(goal.user_id) != str(user.id):
            raise Forbidden()
        return goal

    async def update_goal(self, goal_id: uuid.UUID, user: User, data: GoalUpdate) -> Goal:
        goal = await self.get_goal(goal_id, user)
        return await self.repo.update(goal, **data.model_dump(exclude_unset=True))

    async def delete_goal(self, goal_id: uuid.UUID, user: User) -> None:
        goal = await self.get_goal(goal_id, user)
        await self.repo.delete(goal)
