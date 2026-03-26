import uuid
from datetime import date
from sqlalchemy import Text, Integer, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import UUIDBase


class Task(UUIDBase):
    __tablename__ = "tasks"

    plan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("plans.id"), nullable=False
    )
    day_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    execution_date: Mapped[date | None] = mapped_column(Date, nullable=True, index=True)
    title: Mapped[str | None] = mapped_column(Text, nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    explanation: Mapped[str | None] = mapped_column(Text, nullable=True)
    guide: Mapped[list | None] = mapped_column(JSONB, nullable=True)
    estimated_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status: Mapped[str] = mapped_column(Text, default="pending", nullable=False, server_default="pending")

    plan: Mapped["Plan"] = relationship("Plan", back_populates="tasks")  # noqa: F821
