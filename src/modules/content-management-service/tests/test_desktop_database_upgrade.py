import tempfile
from pathlib import Path
from typing import cast

from alembic.script import ScriptDirectory
from hypothesis import given, settings
from hypothesis import strategies as st
from sqlalchemy import create_engine, inspect, text

from desktop.database_upgrade import upgrade_database
from tests.migration_support import alembic_config, service_root

_DATABASE_FILE = "content.db"
_VERSION_QUERY = text("SELECT version_num FROM alembic_version")
_TABLES_EVERY_INSTALL_NEEDS = {"folders", "flashcard_decks", "notes", "files"}


def _sqlite_url(directory: str) -> str:
    return f"sqlite:///{Path(directory) / _DATABASE_FILE}"


def _latest_revision(database_url: str) -> str | None:
    scripts = ScriptDirectory.from_config(alembic_config(database_url))

    return scripts.get_current_head()


def _recorded_revision(database_url: str) -> str | None:
    engine = create_engine(database_url)

    with engine.connect() as connection:
        revision = cast(
            "str", connection.execute(_VERSION_QUERY).scalar_one()
        )

    engine.dispose()

    return revision


def _table_names(database_url: str) -> set[str]:
    engine = create_engine(database_url)
    names = set(inspect(engine).get_table_names())
    engine.dispose()

    return names


@settings(max_examples=3, deadline=None)
@given(st.integers(min_value=1, max_value=3))
def test_upgrade_database_property_lands_on_the_latest_revision(
    runs: int,
) -> None:
    with tempfile.TemporaryDirectory() as directory:
        database_url = _sqlite_url(directory)

        for _ in range(runs):
            upgrade_database(service_root() / "migrations", database_url)

        recorded = _recorded_revision(database_url)
        latest = _latest_revision(database_url)
        tables = _table_names(database_url)

    assert recorded == latest
    assert _TABLES_EVERY_INSTALL_NEEDS <= tables
