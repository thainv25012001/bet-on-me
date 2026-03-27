"""restructure_subscriptions

Revision ID: bde38bd3f93f
Revises: 4c9ca3747d0a
Create Date: 2026-03-27

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "bde38bd3f93f"
down_revision: Union[str, None] = "4c9ca3747d0a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_PLANS = [
    {
        "tier": "free",
        "name": "Free",
        "price_cents": 0,
        "description": "Get started with AI-powered goal planning. Perfect for trying out the app.",
        "features": '["7-day task plan","AI goal breakdown","Daily task tracking","Basic progress view"]',
        "max_plan_days": 7,
        "expires_after_days": 30,
    },
    {
        "tier": "pro",
        "name": "Pro",
        "price_cents": 999,
        "description": "Serious about your goals? Get a full monthly plan with detailed daily tasks.",
        "features": '["31-day task plan","AI goal breakdown","Daily task tracking","Full progress analytics","Priority AI generation"]',
        "max_plan_days": 31,
        "expires_after_days": 31,
    },
    {
        "tier": "advanced",
        "name": "Advanced",
        "price_cents": 4999,
        "description": "Unlock the full year. Build lasting habits with 365 days of structured planning.",
        "features": '["365-day task plan","AI goal breakdown","Daily task tracking","Full progress analytics","Priority AI generation","Yearly milestone tracking","Dedicated support"]',
        "max_plan_days": 365,
        "expires_after_days": 365,
    },
]


def upgrade() -> None:
    # 1. Drop old subscription_discounts table
    op.drop_table("subscription_discounts")

    # 2. Create subscription_plans table
    op.create_table(
        "subscription_plans",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("tier", sa.Text(), nullable=False),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("price_cents", sa.Integer(), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("features", sa.dialects.postgresql.JSONB(), nullable=False),
        sa.Column("max_plan_days", sa.Integer(), nullable=False),
        sa.Column("expires_after_days", sa.Integer(), nullable=False),
        sa.Column("discount_percent", sa.Float(), nullable=True),
        sa.Column("discount_valid_from", sa.Date(), nullable=True),
        sa.Column("discount_valid_to", sa.Date(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("tier"),
    )

    # 3. Seed initial plans
    conn = op.get_bind()
    import uuid
    from datetime import datetime
    for p in _PLANS:
        import json
        conn.execute(
            sa.text(
                "INSERT INTO subscription_plans "
                "(id, created_at, tier, name, price_cents, description, features, "
                "max_plan_days, expires_after_days) VALUES "
                "(:id, :created_at, :tier, :name, :price_cents, :description, "
                ":features, :max_plan_days, :expires_after_days)"
            ),
            {
                "id": str(uuid.uuid4()),
                "created_at": datetime.utcnow(),
                "tier": p["tier"],
                "name": p["name"],
                "price_cents": p["price_cents"],
                "description": p["description"],
                "features": p["features"],
                "max_plan_days": p["max_plan_days"],
                "expires_after_days": p["expires_after_days"],
            },
        )

    # 4. Rebuild subscriptions table with plan_id FK (drop and recreate)
    op.drop_index("ix_subscriptions_user_id", table_name="subscriptions")
    op.drop_table("subscriptions")

    op.create_table(
        "subscriptions",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("plan_id", sa.UUID(), nullable=False),
        sa.Column("status", sa.Text(), nullable=False),
        sa.Column("started_at", sa.Date(), nullable=False),
        sa.Column("expires_at", sa.Date(), nullable=False),
        sa.Column("price_paid", sa.Integer(), nullable=True),
        sa.Column("currency", sa.Text(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["plan_id"], ["subscription_plans.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_subscriptions_user_id", "subscriptions", ["user_id"], unique=False
    )


def downgrade() -> None:
    op.drop_index("ix_subscriptions_user_id", table_name="subscriptions")
    op.drop_table("subscriptions")
    op.drop_table("subscription_plans")

    op.create_table(
        "subscriptions",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("tier", sa.Text(), nullable=False),
        sa.Column("status", sa.Text(), nullable=False),
        sa.Column("started_at", sa.Date(), nullable=False),
        sa.Column("expires_at", sa.Date(), nullable=False),
        sa.Column("price_paid", sa.Integer(), nullable=True),
        sa.Column("currency", sa.Text(), nullable=False),
        sa.Column("discount_percent", sa.Float(), nullable=True),
        sa.Column("discount_valid_from", sa.Date(), nullable=True),
        sa.Column("discount_valid_to", sa.Date(), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_subscriptions_user_id", "subscriptions", ["user_id"], unique=False
    )
    op.create_table(
        "subscription_discounts",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("tier", sa.Text(), nullable=True),
        sa.Column("discount_percent", sa.Float(), nullable=False),
        sa.Column("valid_from", sa.Date(), nullable=False),
        sa.Column("valid_to", sa.Date(), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
