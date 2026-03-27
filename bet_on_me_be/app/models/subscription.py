import uuid
from datetime import date

from sqlalchemy import Date, ForeignKey, Integer, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import UUIDBase


class Subscription(UUIDBase):
    __tablename__ = "subscriptions"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    plan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("subscription_plans.id"), nullable=False
    )
    status: Mapped[str] = mapped_column(Text, default="active", nullable=False)
    started_at: Mapped[date] = mapped_column(Date, nullable=False)
    expires_at: Mapped[date] = mapped_column(Date, nullable=False)
    price_paid: Mapped[int | None] = mapped_column(Integer, nullable=True)
    currency: Mapped[str] = mapped_column(Text, default="USD", nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="subscriptions")  # noqa: F821
    plan: Mapped["SubscriptionPlan"] = relationship(  # noqa: F821
        "SubscriptionPlan", back_populates="subscriptions"
    )
