import uuid
from datetime import datetime
from pydantic import BaseModel


class CheckinCreate(BaseModel):
    proof_url: str | None = None


class CheckinUpdate(BaseModel):
    status: str | None = None
    proof_url: str | None = None


class CheckinOut(BaseModel):
    id: uuid.UUID
    task_id: uuid.UUID
    user_id: uuid.UUID
    status: str
    proof_url: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
