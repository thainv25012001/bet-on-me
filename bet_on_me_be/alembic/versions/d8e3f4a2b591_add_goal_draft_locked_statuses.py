"""add goal draft/locked statuses

Revision ID: d8e3f4a2b591
Revises: c7d4e2f1a839
Create Date: 2026-03-27

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "d8e3f4a2b591"
down_revision: Union[str, None] = "c7d4e2f1a839"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # status column is Text — new values need no schema change.
    # New goals will be created as 'draft'; consumer moves them to 'locked'
    # after the AI plan is generated; users unlock to 'in_progress'.
    pass


def downgrade() -> None:
    conn = op.get_bind()
    conn.execute(
        sa.text(
            "UPDATE goals SET status = 'in_progress' "
            "WHERE status IN ('draft', 'locked')"
        )
    )
