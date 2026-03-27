import uuid
from datetime import datetime
from sqlalchemy import Text, Integer, DateTime
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import UUIDBase
from app.utils.constants import JobStatus


class GoalJob(UUIDBase):
    __tablename__ = "goal_jobs"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True
    )
    # Full GoalCreate payload serialised as JSON so the consumer needs no extra context.
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False)

    status: Mapped[str] = mapped_column(
        Text, default=JobStatus.PENDING, nullable=False, index=True
    )

    # Filled on success by the consumer.
    goal_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )

    # Filled on failure by the consumer.
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Pre-calculated at enqueue time; shown to the user as wait estimate.
    estimated_seconds: Mapped[int] = mapped_column(Integer, nullable=False)

    started_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
