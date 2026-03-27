from datetime import datetime

from sqlalchemy import Boolean, DateTime, Text, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import UUIDBase


class User(UUIDBase):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    password_hash: Mapped[str | None] = mapped_column(Text, nullable=True)
    name: Mapped[str | None] = mapped_column(Text, nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    reset_token: Mapped[str | None] = mapped_column(Text, nullable=True)
    reset_token_expires: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    timezone: Mapped[str] = mapped_column(Text, nullable=False, default="UTC")
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    goals: Mapped[list["Goal"]] = relationship("Goal", back_populates="user")  # noqa: F821
    payments: Mapped[list["Payment"]] = relationship("Payment", back_populates="user")  # noqa: F821
    stakes: Mapped[list["Stake"]] = relationship("Stake", back_populates="user")  # noqa: F821
    subscriptions: Mapped[list["Subscription"]] = relationship("Subscription", back_populates="user")  # noqa: F821
