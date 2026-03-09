import uuid
from datetime import datetime
from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str | None = None


class UserUpdate(BaseModel):
    name: str | None = None
    avatar_url: str | None = None


class UserOut(BaseModel):
    id: uuid.UUID
    email: str
    name: str | None
    avatar_url: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
