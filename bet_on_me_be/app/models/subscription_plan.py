import uuid
from datetime import date

from sqlalchemy import Date, Float, Integer, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import UUIDBase


class SubscriptionPlan(UUIDBase):
    __tablename__ = "subscription_plans"

    tier: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    price_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    features: Mapped[list] = mapped_column(JSONB, nullable=False, default=list)
    max_plan_days: Mapped[int] = mapped_column(Integer, nullable=False)
    expires_after_days: Mapped[int] = mapped_column(Integer, nullable=False)
    discount_percent: Mapped[float | None] = mapped_column(Float, nullable=True)
    discount_valid_from: Mapped[date | None] = mapped_column(Date, nullable=True)
    discount_valid_to: Mapped[date | None] = mapped_column(Date, nullable=True)

    subscriptions: Mapped[list["Subscription"]] = relationship(  # noqa: F821
        "Subscription", back_populates="plan"
    )
