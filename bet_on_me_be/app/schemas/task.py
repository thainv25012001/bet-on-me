import uuid
from datetime import datetime
from pydantic import BaseModel


class TaskCreate(BaseModel):
    day_number: int | None = None
    title: str | None = None
    description: str | None = None
    estimated_minutes: int | None = None


class TaskOut(BaseModel):
    id: uuid.UUID
    plan_id: uuid.UUID
    day_number: int | None
    title: str | None
    description: str | None
    estimated_minutes: int | None
    created_at: datetime

    model_config = {"from_attributes": True}
