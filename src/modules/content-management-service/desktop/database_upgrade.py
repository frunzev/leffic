from pathlib import Path

from alembic import command
from alembic.config import Config

_SCRIPT_LOCATION = "script_location"
_DATABASE_URL = "sqlalchemy.url"
_LATEST_REVISION = "head"


def upgrade_database(migrations_directory: Path, database_url: str) -> None:
    configuration = Config()
    configuration.set_main_option(_SCRIPT_LOCATION, str(migrations_directory))
    configuration.set_main_option(_DATABASE_URL, database_url)

    command.upgrade(configuration, _LATEST_REVISION)
