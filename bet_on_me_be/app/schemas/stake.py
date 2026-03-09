import uuid
from datetime import datetime
from pydantic import BaseModel


class StakeCreate(BaseModel):
    amount_per_day: int | None = None
    total_committed: int | None = None


class StakeOut(BaseModel):
    id: uuid.UUID
    goal_id: uuid.UUID
    user_id: uuid.UUID
    amount_per_day: int | None
    total_committed: int | None
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
