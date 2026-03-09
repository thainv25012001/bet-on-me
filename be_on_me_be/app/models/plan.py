import uuid
from sqlalchemy import Text, Integer, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import UUIDBase


class Plan(UUIDBase):
    __tablename__ = "plans"

    goal_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("goals.id"), nullable=False
    )
    total_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    generated_by: Mapped[str] = mapped_column(Text, default="ai", nullable=False)

    goal: Mapped["Goal"] = relationship("Goal", back_populates="plans")  # noqa: F821
    tasks: Mapped[list["Task"]] = relationship("Task", back_populates="plan")  # noqa: F821
