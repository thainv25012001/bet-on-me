import uuid
from datetime import date, datetime
from pydantic import BaseModel


class GoalCreate(BaseModel):
    title: str
    description: str | None = None
    target_date: date | None = None
    stake_per_day: int | None = None


class GoalUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    target_date: date | None = None
    stake_per_day: int | None = None
    status: str | None = None


class GoalOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    description: str | None
    target_date: date | None
    stake_per_day: int | None
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
