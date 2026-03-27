import secrets
from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.user_repository import UserRepository
from app.core.security import hash_password, verify_password, create_access_token
from app.schemas.user import UserCreate
from app.utils.exceptions import BadRequest, Conflict, NotFound, Unauthorized

_RESET_TOKEN_TTL_HOURS = 6


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

    async def forgot_password(self, email: str) -> dict:
        """Generate a password-reset token for the given email.

        Always returns success to avoid leaking whether an email is registered.
        In production the token would be emailed; here it is returned directly.
        """
        user = await self.repo.get_by_email(email)
        if not user:
            # Return a dummy response — don't reveal whether email exists.
            return {"message": "If that email is registered, a reset token has been sent."}

        token = secrets.token_urlsafe(32)
        expires = datetime.now(timezone.utc) + timedelta(hours=_RESET_TOKEN_TTL_HOURS)
        await self.repo.update(user, reset_token=token, reset_token_expires=expires)
        return {
            "message": "If that email is registered, a reset token has been sent.",
            "reset_token": token,  # Remove this line when email delivery is wired up.
        }

    async def reset_password(self, token: str, new_password: str) -> dict:
        user = await self.repo.get_by_token(token)
        if not user:
            raise BadRequest("Invalid or expired reset token")

        now = datetime.now(timezone.utc)
        expires = user.reset_token_expires
        if expires is None or (expires.tzinfo is None and expires.replace(tzinfo=timezone.utc) < now) or (expires.tzinfo is not None and expires < now):
            raise BadRequest("Invalid or expired reset token")

        await self.repo.update(
            user,
            password_hash=hash_password(new_password),
            reset_token=None,
            reset_token_expires=None,
        )
        return {"message": "Password reset successfully"}
