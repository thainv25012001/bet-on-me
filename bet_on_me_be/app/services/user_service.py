from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserUpdate
from app.models.user import User
from app.utils.exceptions import NotFound


class UserService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = UserRepository(db)

    async def get_profile(self, user: User) -> User:
        return user

    async def update_profile(self, user: User, data: UserUpdate) -> User:
        changes = data.model_dump(exclude_unset=True)
        return await self.repo.update(user, **changes)
