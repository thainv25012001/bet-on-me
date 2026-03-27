"""add daily_rewards table

Revision ID: e9f0a1b2c3d4
Revises: d8e3f4a2b591
Create Date: 2026-03-27

"""
from typing import Sequence, Union

import sqlalchemy as sa
import sqlalchemy.dialects.postgresql as pg
from alembic import op

revision: str = "e9f0a1b2c3d4"
down_revision: Union[str, None] = "d8e3f4a2b591"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "daily_rewards",
        sa.Column("id", pg.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", pg.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("goal_id", pg.UUID(as_uuid=True), sa.ForeignKey("goals.id"), nullable=False),
        sa.Column("stake_id", pg.UUID(as_uuid=True), sa.ForeignKey("stakes.id"), nullable=False),
        sa.Column("execution_date", sa.Date(), nullable=False, index=True),
        sa.Column("amount", sa.Integer(), nullable=False),
        sa.Column("status", sa.Text(), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_daily_rewards_user_id", "daily_rewards", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_daily_rewards_user_id", table_name="daily_rewards")
    op.drop_table("daily_rewards")
