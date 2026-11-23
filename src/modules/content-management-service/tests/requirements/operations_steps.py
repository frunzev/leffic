import importlib
import os
import uuid
from collections.abc import Iterator
from dataclasses import dataclass
from types import ModuleType
from unittest import mock

import psycopg2
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from pytest_bdd import given, parsers, then, when

from shared import chosen_ai_engine, database, jwt_secret
from shared.database import get_db
from shared.models import Folder
from tests.database_bootstrap_support import FakeConnection, FakeCursor
from tests.requirements.requirement_lookup import Sessions
from tests.support import USER_ID

_SECRET_VARIABLE = "JWT_SECRET_KEY"
_ENGINE_VARIABLE = "CHAT_ENGINE"
_STARTUP_SECRET = "a secret the service signs with"
_POSTGRES_URL = "postgresql://postgres:postgres@localhost:5432/content"
_SQLITE_URL = "sqlite:///content.db"
_EXISTING_DATABASE = (1,)
_CREATE_DATABASE = "CREATE DATABASE"

SettingChanges = dict[str, str | None]


@dataclass(frozen=True)
class ServiceStartup:
    refusal: str | None
    started_module: ModuleType | None


class FakePostgresServer:
    def __init__(self) -> None:
        self.cursor: FakeCursor = FakeCursor(existing=None)
        self.connection_count: int = 0

    def connect(self, **connection_settings: str) -> FakeConnection:
        _ = connection_settings
        self.connection_count += 1

        return FakeConnection(self.cursor)


def _apply_setting_changes(setting_changes: SettingChanges) -> None:
    for setting_name, setting_value in setting_changes.items():
        if setting_value is None:
            _ = os.environ.pop(setting_name, None)
        else:
            os.environ[setting_name] = setting_value


def _started(
    module: ModuleType, setting_changes: SettingChanges
) -> ServiceStartup:
    with mock.patch.dict(os.environ):
        _apply_setting_changes(setting_changes)

        try:
            started_module = importlib.reload(module)
        except (RuntimeError, ValueError) as refusal:
            return ServiceStartup(refusal=str(refusal), started_module=None)

    return ServiceStartup(refusal=None, started_module=started_module)


@pytest.fixture
def restored_secret() -> Iterator[object]:
    yield None
    _ = importlib.reload(jwt_secret)


@pytest.fixture
def restored_engine() -> Iterator[object]:
    yield None
    _ = importlib.reload(chosen_ai_engine)


@when(
    parsers.parse('the content service starts with the AI engine "{engine}"'),
    target_fixture="service_startup",
)
def start_with_engine(restored_engine: object, engine: str) -> ServiceStartup:
    _ = restored_engine

    return _started(chosen_ai_engine, {_ENGINE_VARIABLE: engine})


@when(
    "the content service starts without a signing secret",
    target_fixture="service_startup",
)
def start_without_secret(restored_secret: object) -> ServiceStartup:
    _ = restored_secret

    return _started(jwt_secret, {_SECRET_VARIABLE: None})


@when(
    "the content service starts with a signing secret",
    target_fixture="service_startup",
)
def start_with_secret(restored_secret: object) -> ServiceStartup:
    _ = restored_secret

    return _started(jwt_secret, {_SECRET_VARIABLE: _STARTUP_SECRET})


@then(parsers.parse('it refuses to start because "{reason}"'))
def check_refused_start(service_startup: ServiceStartup, reason: str) -> None:
    assert service_startup.refusal == reason


@then("it starts")
def check_started(service_startup: ServiceStartup) -> None:
    assert service_startup.refusal is None
    assert service_startup.started_module is not None


@pytest.fixture
def content_postgres_server(
    monkeypatch: pytest.MonkeyPatch,
) -> FakePostgresServer:
    server = FakePostgresServer()
    monkeypatch.setattr(psycopg2, "connect", server.connect)

    return server


@given("the Postgres server has no content database")
def remove_content_database(
    content_postgres_server: FakePostgresServer,
) -> None:
    content_postgres_server.cursor.existing = None


@given("the Postgres server already has the content database")
def keep_content_database(
    content_postgres_server: FakePostgresServer,
) -> None:
    content_postgres_server.cursor.existing = _EXISTING_DATABASE


@when("the content migrations start against Postgres")
def start_migrations_on_postgres(
    content_postgres_server: FakePostgresServer,
) -> None:
    _ = content_postgres_server
    database.create_postgres_database_if_configured(_POSTGRES_URL)


@when("the content migrations start against SQLite")
def start_migrations_on_sqlite(
    content_postgres_server: FakePostgresServer,
) -> None:
    _ = content_postgres_server
    database.create_postgres_database_if_configured(_SQLITE_URL)


def _created_databases(server: FakePostgresServer) -> list[str]:
    created: list[str] = []

    for statement in server.cursor.statements:
        if _CREATE_DATABASE in str(statement):
            created.append(str(statement))

    return created


@then("the content database is created")
def check_database_created(
    content_postgres_server: FakePostgresServer,
) -> None:
    assert len(_created_databases(content_postgres_server)) == 1


@then("no content database is created")
def check_no_database_created(
    content_postgres_server: FakePostgresServer,
) -> None:
    assert content_postgres_server.connection_count == 1
    assert _created_databases(content_postgres_server) == []


@then("the content Postgres server is never contacted")
def check_postgres_untouched(
    content_postgres_server: FakePostgresServer,
) -> None:
    assert content_postgres_server.connection_count == 0


def _served_app(client: TestClient) -> FastAPI:
    served_app = client.app

    if not isinstance(served_app, FastAPI):
        raise TypeError(served_app)

    return served_app


@given("the content service uses its own database")
def use_own_database(
    client: TestClient, sessions: Sessions, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(database, "SessionLocal", sessions)
    _ = _served_app(client).dependency_overrides.pop(get_db)


def _stored_folder_names(sessions: Sessions) -> list[str]:
    with sessions() as session:
        stored_folders = session.query(Folder).all()
        folder_names: list[str] = []

        for stored_folder in stored_folders:
            folder_names.append(stored_folder.name)

    return folder_names


@then(parsers.parse('the content database holds the folder "{folder_name}"'))
def check_folder_stored(sessions: Sessions, folder_name: str) -> None:
    assert folder_name in _stored_folder_names(sessions)


@then("the content database holds my home folder")
def check_home_stored(sessions: Sessions) -> None:
    home_id = uuid.UUID(USER_ID)

    with sessions() as session:
        home_folder = session.get(Folder, home_id)

    assert home_folder is not None
