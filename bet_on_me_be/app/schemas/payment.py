import uuid
from datetime import datetime
from pydantic import BaseModel


class PaymentCreate(BaseModel):
    amount: int
    currency: str = "USD"
    provider: str | None = None
    provider_payment_id: str | None = None
    status: str | None = None


class PaymentOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    amount: int | None
    currency: str
    provider: str | None
    provider_payment_id: str | None
    status: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
