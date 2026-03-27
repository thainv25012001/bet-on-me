import uuid
from datetime import date
from sqlalchemy import Text, Integer, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import UUIDBase
from app.utils.constants import DailyRewardStatus


class DailyReward(UUIDBase):
    __tablename__ = "daily_rewards"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    goal_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("goals.id"), nullable=False
    )
    stake_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("stakes.id"), nullable=False
    )
    execution_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    amount: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(
        Text, default=DailyRewardStatus.PENDING, nullable=False
    )

    user: Mapped["User"] = relationship("User")  # noqa: F821
