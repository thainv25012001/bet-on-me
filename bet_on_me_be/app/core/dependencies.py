import uuid
from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.core.security import decode_access_token
from app.repositories.user_repository import UserRepository
from app.models.user import User
from app.utils.exceptions import Unauthorized, TokenExpired

bearer_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    token = credentials.credentials
    user_id, is_expired = decode_access_token(token)

    if is_expired:
        raise TokenExpired()
    if not user_id:
        raise Unauthorized("Invalid token")

    try:
        uid = uuid.UUID(user_id)
    except ValueError:
        raise Unauthorized("Invalid token payload")

    repo = UserRepository(db)
    user = await repo.get(uid)
    if not user:
        raise Unauthorized("User not found")
    return user


async def get_admin_user(
    current_user: User = Depends(get_current_user),
) -> User:
    from app.utils.exceptions import Forbidden
    if not current_user.is_admin:
        raise Forbidden()
    return current_user
