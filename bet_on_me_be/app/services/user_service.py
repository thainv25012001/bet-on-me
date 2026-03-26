from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserUpdate
from app.models.user import User
from app.core.security import hash_password, verify_password
from app.utils.exceptions import BadRequest


class UserService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = UserRepository(db)

    async def get_profile(self, user: User) -> User:
        return user

    async def update_profile(self, user: User, data: UserUpdate) -> User:
        changes = data.model_dump(exclude_unset=True)
        return await self.repo.update(user, **changes)

    async def change_password(
        self, user: User, current_password: str, new_password: str
    ) -> dict:
        if not user.password_hash or not verify_password(current_password, user.password_hash):
            raise BadRequest("Current password is incorrect")
        await self.repo.update(user, password_hash=hash_password(new_password))
        return {"message": "Password changed successfully"}
