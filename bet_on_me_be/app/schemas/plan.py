import uuid
from datetime import datetime
from pydantic import BaseModel


class PlanCreate(BaseModel):
    total_days: int | None = None
    generated_by: str = "ai"


class PlanOut(BaseModel):
    id: uuid.UUID
    goal_id: uuid.UUID
    total_days: int | None
    generated_by: str
    created_at: datetime

    model_config = {"from_attributes": True}
