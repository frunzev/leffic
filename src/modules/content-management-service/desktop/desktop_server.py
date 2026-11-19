from collections.abc import Mapping
from pathlib import Path

import uvicorn

from app_factory import create_app
from desktop.database_upgrade import upgrade_database
from desktop.desktop_port import read_desktop_port
from desktop.generation_worker import start_generation_worker
from features.study_units_generation.celery_app import celery_app
from shared.database import SQLALCHEMY_DATABASE_URL
from shared.local_disk_file_storage import create_files_directory

_LOOPBACK_HOST = "127.0.0.1"


def serve_desktop(
    environment: Mapping[str, str], migrations_directory: Path
) -> None:
    port = read_desktop_port(environment)

    create_files_directory()
    upgrade_database(migrations_directory, SQLALCHEMY_DATABASE_URL)
    _ = start_generation_worker(celery_app)

    uvicorn.run(create_app(), host=_LOOPBACK_HOST, port=port)
