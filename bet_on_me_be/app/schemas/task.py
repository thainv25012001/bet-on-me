import uuid
from datetime import date, datetime
from pydantic import BaseModel


class TaskGuideStep(BaseModel):
    step: int
    action: str
    example: str | None = None


class TaskCreate(BaseModel):
    day_number: int | None = None
    title: str | None = None
    description: str | None = None
    explanation: str | None = None
    guide: list[TaskGuideStep] | None = None
    estimated_minutes: int | None = None


class TaskStatusUpdate(BaseModel):
    status: str  # "pending" | "success" | "failed"


class TaskOut(BaseModel):
    id: uuid.UUID
    plan_id: uuid.UUID
    day_number: int | None
    execution_date: date | None = None
    title: str | None
    description: str | None
    explanation: str | None = None
    guide: list[TaskGuideStep] | None = None
    estimated_minutes: int | None
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class DailyRewardInfo(BaseModel):
    id: uuid.UUID
    amount: int


class TaskStatusUpdateOut(BaseModel):
    task: TaskOut
    day_complete: bool
    daily_reward: DailyRewardInfo | None = None


class TaskTodayOut(BaseModel):
    id: uuid.UUID
    title: str | None
    description: str | None
    explanation: str | None
    guide: list[TaskGuideStep] | None
    estimated_minutes: int | None
    day_number: int | None
    execution_date: date | None
    status: str
    goal_id: uuid.UUID
    goal_title: str
    total_days: int

    model_config = {"from_attributes": False}
