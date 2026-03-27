"""add_subscriptions_table

Revision ID: 4c9ca3747d0a
Revises: 00368ac0d202
Create Date: 2026-03-27

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "4c9ca3747d0a"
down_revision: Union[str, None] = "14f26f198319"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
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
        op.f("ix_subscriptions_user_id"), "subscriptions", ["user_id"], unique=False
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

    op.add_column("users", sa.Column("is_admin", sa.Boolean(), nullable=False, server_default="false"))


def downgrade() -> None:
    op.drop_column("users", "is_admin")
    op.drop_table("subscription_discounts")
    op.drop_index(op.f("ix_subscriptions_user_id"), table_name="subscriptions")
    op.drop_table("subscriptions")
