import uuid
from datetime import date, datetime
from pydantic import BaseModel


class DailyRewardOut(BaseModel):
    id: uuid.UUID
    goal_id: uuid.UUID
    execution_date: date
    amount: int
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
