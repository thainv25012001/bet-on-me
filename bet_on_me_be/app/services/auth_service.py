from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.user_repository import UserRepository
from app.core.security import hash_password, verify_password, create_access_token
from app.schemas.user import UserCreate
from app.utils.exceptions import Conflict, Unauthorized


class AuthService:
    def __init__(self, db: AsyncSession) -> None:
        self.repo = UserRepository(db)

    async def register(self, data: UserCreate) -> dict:
        existing = await self.repo.get_by_email(data.email)
        if existing:
            raise Conflict("Email already registered")

        user = await self.repo.create(
            email=data.email,
            password_hash=hash_password(data.password),
            name=data.name,
        )
        token = create_access_token(str(user.id))
        return {"access_token": token, "token_type": "bearer"}

    async def login(self, email: str, password: str) -> dict:
        user = await self.repo.get_by_email(email)
        if not user or not user.password_hash:
            raise Unauthorized("Invalid credentials")
        if not verify_password(password, user.password_hash):
            raise Unauthorized("Invalid credentials")

        token = create_access_token(str(user.id))
        return {"access_token": token, "token_type": "bearer"}
