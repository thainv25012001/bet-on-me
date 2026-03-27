"""add user timezone and rename goal active to in_progress

Revision ID: c7d4e2f1a839
Revises: a1f3c2e9b047
Create Date: 2026-03-27

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "c7d4e2f1a839"
down_revision: Union[str, None] = "a1f3c2e9b047"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add timezone column to users (default UTC for all existing users).
    op.add_column(
        "users",
        sa.Column(
            "timezone",
            sa.Text(),
            nullable=False,
            server_default="UTC",
        ),
    )
    op.alter_column("users", "timezone", server_default=None)

    # 2. Rename goal status "active" → "in_progress".
    conn = op.get_bind()
    conn.execute(
        sa.text("UPDATE goals SET status = 'in_progress' WHERE status = 'active'")
    )


def downgrade() -> None:
    # Revert goal status.
    conn = op.get_bind()
    conn.execute(
        sa.text("UPDATE goals SET status = 'active' WHERE status = 'in_progress'")
    )

    # Remove timezone column.
    op.drop_column("users", "timezone")
