from datetime import datetime

from sqlalchemy import DateTime, Text
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

    goals: Mapped[list["Goal"]] = relationship("Goal", back_populates="user")  # noqa: F821
    payments: Mapped[list["Payment"]] = relationship("Payment", back_populates="user")  # noqa: F821
    stakes: Mapped[list["Stake"]] = relationship("Stake", back_populates="user")  # noqa: F821
