import uuid
from sqlalchemy import Text, Integer, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import UUIDBase
from app.utils.constants import PlanGeneratedBy


class Plan(UUIDBase):
    __tablename__ = "plans"

    goal_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("goals.id"), nullable=False
    )
    total_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    generated_by: Mapped[str] = mapped_column(Text, default=PlanGeneratedBy.AI, nullable=False)
    overview: Mapped[str | None] = mapped_column(Text, nullable=True)
    hours_per_day: Mapped[float | None] = mapped_column(Float, nullable=True)

    goal: Mapped["Goal"] = relationship("Goal", back_populates="plans")  # noqa: F821
    tasks: Mapped[list["Task"]] = relationship("Task", back_populates="plan", cascade="all, delete-orphan")  # noqa: F821
