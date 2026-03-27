"""add total_goal_limit to subscription_plans

Revision ID: a1f3c2e9b047
Revises: bde38bd3f93f
Create Date: 2026-03-27

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "a1f3c2e9b047"
down_revision: Union[str, None] = "bde38bd3f93f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# Tier → goal limit
_LIMITS = {
    "free": 2,
    "pro": 6,
    "advanced": 30,
}


def upgrade() -> None:
    # Add column with a safe default so existing rows are not null.
    op.add_column(
        "subscription_plans",
        sa.Column(
            "total_goal_limit",
            sa.Integer(),
            nullable=False,
            server_default="2",
        ),
    )

    # Set the correct limit per tier.
    conn = op.get_bind()
    for tier, limit in _LIMITS.items():
        conn.execute(
            sa.text(
                "UPDATE subscription_plans SET total_goal_limit = :limit WHERE tier = :tier"
            ),
            {"limit": limit, "tier": tier},
        )

    # Drop the server default — values are now explicit.
    op.alter_column("subscription_plans", "total_goal_limit", server_default=None)


def downgrade() -> None:
    op.drop_column("subscription_plans", "total_goal_limit")
