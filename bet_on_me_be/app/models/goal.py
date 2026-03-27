import uuid
from datetime import date
from sqlalchemy import Text, Integer, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import UUIDBase
from app.utils.constants import GoalStatus


class Goal(UUIDBase):
    __tablename__ = "goals"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    title: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    target_date: Mapped[date] = mapped_column(Date, nullable=False)
    stake_per_day: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(Text, default=GoalStatus.DRAFT, nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="goals")  # noqa: F821
    plans: Mapped[list["Plan"]] = relationship("Plan", back_populates="goal", cascade="all, delete-orphan")  # noqa: F821
    stakes: Mapped[list["Stake"]] = relationship("Stake", back_populates="goal", cascade="all, delete-orphan")  # noqa: F821
