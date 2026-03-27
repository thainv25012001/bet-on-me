import uuid
from datetime import date, datetime

from pydantic import BaseModel, field_validator


class SubscriptionPlanOut(BaseModel):
    id: uuid.UUID
    tier: str
    name: str
    price_cents: int
    description: str
    features: list[str]
    max_plan_days: int
    expires_after_days: int
    discount_percent: float | None
    discount_valid_from: date | None
    discount_valid_to: date | None
    discounted_price_cents: int | None = None  # computed by from_plan(), not an ORM field

    model_config = {"from_attributes": True}

    @classmethod
    def from_plan(cls, plan: object, today: date) -> "SubscriptionPlanOut":
        discount_active = (
            plan.discount_percent is not None  # type: ignore[union-attr]
            and plan.discount_valid_from is not None  # type: ignore[union-attr]
            and plan.discount_valid_to is not None  # type: ignore[union-attr]
            and plan.discount_valid_from <= today <= plan.discount_valid_to  # type: ignore[union-attr]
        )
        discounted = (
            int(plan.price_cents * (1 - plan.discount_percent / 100))  # type: ignore[union-attr]
            if discount_active
            else None
        )
        return cls(
            id=plan.id,  # type: ignore[union-attr]
            tier=plan.tier,  # type: ignore[union-attr]
            name=plan.name,  # type: ignore[union-attr]
            price_cents=plan.price_cents,  # type: ignore[union-attr]
            description=plan.description,  # type: ignore[union-attr]
            features=plan.features or [],  # type: ignore[union-attr]
            max_plan_days=plan.max_plan_days,  # type: ignore[union-attr]
            expires_after_days=plan.expires_after_days,  # type: ignore[union-attr]
            discount_percent=plan.discount_percent if discount_active else None,  # type: ignore[union-attr]
            discount_valid_from=plan.discount_valid_from if discount_active else None,  # type: ignore[union-attr]
            discount_valid_to=plan.discount_valid_to if discount_active else None,  # type: ignore[union-attr]
            discounted_price_cents=discounted,
        )


class SubscriptionCreate(BaseModel):
    tier: str
    started_at: date
    currency: str = "USD"


class UserSubscriptionOut(BaseModel):
    id: uuid.UUID
    plan_id: uuid.UUID
    status: str
    started_at: date
    expires_at: date
    price_paid: int | None
    currency: str
    created_at: datetime
    plan: SubscriptionPlanOut | None = None

    model_config = {"from_attributes": True}


class PlanDiscountUpdate(BaseModel):
    discount_percent: float | None = None
    discount_valid_from: date | None = None
    discount_valid_to: date | None = None

    @field_validator("discount_percent")
    @classmethod
    def validate_discount(cls, v: float | None) -> float | None:
        if v is not None and not (0.0 < v <= 100.0):
            raise ValueError("discount_percent must be between 0 and 100")
        return v
