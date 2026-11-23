from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "b7c41e2d9a05"
down_revision: str | Sequence[str] | None = "a1f292d976d1"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_TABLE = "provider_keys"
_COLUMN = "spent_month"
_MONTH_LENGTH = 7
_NO_MONTH = ""


def upgrade() -> None:
    op.add_column(
        _TABLE,
        sa.Column(
            _COLUMN,
            sa.String(length=_MONTH_LENGTH),
            nullable=False,
            server_default=_NO_MONTH,
        ),
    )


def downgrade() -> None:
    with op.batch_alter_table(_TABLE) as batch:
        batch.drop_column(_COLUMN)
