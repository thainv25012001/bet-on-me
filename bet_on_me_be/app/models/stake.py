import uuid
from sqlalchemy import Text, Integer, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import UUIDBase
from app.utils.constants import StakeStatus


class Stake(UUIDBase):
    __tablename__ = "stakes"

    goal_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("goals.id"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    amount_per_day: Mapped[int | None] = mapped_column(Integer, nullable=True)
    total_committed: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status: Mapped[str] = mapped_column(Text, default=StakeStatus.ACTIVE, nullable=False)

    goal: Mapped["Goal"] = relationship("Goal", back_populates="stakes")  # noqa: F821
    user: Mapped["User"] = relationship("User", back_populates="stakes")  # noqa: F821
