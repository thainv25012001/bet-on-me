import uuid
from datetime import date, datetime
from typing import Literal
from pydantic import BaseModel
from app.schemas.plan import PlanOut


class GoalCreate(BaseModel):
    """Basic goal info saved immediately when the user submits the form."""
    title: str
    description: str | None = None
    start_date: date
    # None when mode='hours' — consumer updates it after AI estimates duration.
    target_date: date | None = None
    stake_per_day: int


class GoalGenerateRequest(BaseModel):
    """AI generation parameters sent after the goal record is created."""
    hours_per_day: float
    mode: Literal["duration", "hours"] = "duration"


class GoalUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    start_date: date | None = None
    target_date: date | None = None
    stake_per_day: int | None = None
    status: str | None = None


class GoalOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    description: str | None
    start_date: date
    target_date: date
    stake_per_day: int
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class GoalWithPlanOut(GoalOut):
    plan: PlanOut
