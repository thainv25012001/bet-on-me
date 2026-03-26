import base64
import hashlib
from datetime import datetime, timedelta

import bcrypt
from jose import jwt, JWTError
from app.core.config import settings


def _prehash(password: str) -> bytes:
    """SHA-256 prehash before bcrypt to support passwords of any length.

    bcrypt silently truncates at 72 bytes. Prehashing with SHA-256 produces
    a fixed 32-byte digest (44-char base64), well within the limit, while
    preserving the full entropy of the original password.
    """
    digest = hashlib.sha256(password.encode("utf-8")).digest()
    return base64.b64encode(digest)


def hash_password(password: str) -> str:
    return bcrypt.hashpw(_prehash(password), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(_prehash(plain), hashed.encode("utf-8"))


def create_access_token(user_id: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": user_id, "exp": expire}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_access_token(token: str) -> tuple[str | None, bool]:
    """Returns (user_id, is_expired). user_id is None on any failure."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload.get("sub"), False
    except jwt.ExpiredSignatureError:
        return None, True
    except JWTError:
        return None, False
