import uuid
from datetime import date, datetime
from typing import Literal
from pydantic import BaseModel, model_validator
from app.schemas.plan import PlanOut


class GoalCreate(BaseModel):
    title: str
    description: str | None = None
    start_date: date
    target_date: date | None = None
    stake_per_day: int
    hours_per_day: float
    mode: Literal["duration", "hours"] = "duration"

    @model_validator(mode="after")
    def validate_target_date_for_mode(self) -> "GoalCreate":
        if self.mode == "duration" and self.target_date is None:
            raise ValueError("target_date is required when mode is 'duration'")
        return self


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
