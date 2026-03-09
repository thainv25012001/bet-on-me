import uuid
from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.core.security import decode_access_token
from app.repositories.user_repository import UserRepository
from app.models.user import User
from app.utils.exceptions import Unauthorized

bearer_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    token = credentials.credentials
    user_id = decode_access_token(token)
    if not user_id:
        raise Unauthorized("Invalid or expired token")

    try:
        uid = uuid.UUID(user_id)
    except ValueError:
        raise Unauthorized("Invalid token payload")

    repo = UserRepository(db)
    user = await repo.get(uid)
    if not user:
        raise Unauthorized("User not found")
    return user
