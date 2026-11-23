import importlib
import os
from collections.abc import Iterator
from dataclasses import dataclass
from types import ModuleType
from unittest import mock

import psycopg2
import pytest
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

import database_provisioning
from features.authentication import cookie_security
from shared import jwt_secret
from tests.postgres_fakes import FakeConnection, FakeCursor

_SECRET_VARIABLE = "JWT_SECRET_KEY"
_COOKIE_SECURITY_VARIABLE = "REFRESH_COOKIE_SECURE"
_STARTUP_SECRET = "a secret the service signs with"
_SIGN_UP = "/sign-up"
_SECURE_ATTRIBUTE = "secure"
_POSTGRES_URL = "postgresql://postgres:postgres@localhost:5432/users"
_SQLITE_URL = "sqlite:///accounts.db"
_EXISTING_DATABASE = (1,)
_CREATE_DATABASE = "CREATE DATABASE"
_SIGN_UP_REQUEST = {
    "username": "learner",
    "email": "learner@example.com",
    "password": "correct horse battery staple",
}

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
        except RuntimeError as refusal:
            return ServiceStartup(refusal=str(refusal), started_module=None)

    return ServiceStartup(refusal=None, started_module=started_module)


@pytest.fixture
def restored_settings() -> Iterator[object]:
    yield None
    _ = importlib.reload(jwt_secret)
    _ = importlib.reload(cookie_security)


@when(
    "the account service starts without a signing secret",
    target_fixture="service_startup",
)
def start_without_secret(restored_settings: object) -> ServiceStartup:
    _ = restored_settings

    return _started(jwt_secret, {_SECRET_VARIABLE: None})


@when(
    "the account service starts with a signing secret",
    target_fixture="service_startup",
)
def start_with_secret(restored_settings: object) -> ServiceStartup:
    _ = restored_settings
    return _started(jwt_secret, {_SECRET_VARIABLE: _STARTUP_SECRET})


@when(
    "the account service starts without a cookie security setting",
    target_fixture="service_startup",
)
def start_without_cookie_setting(restored_settings: object) -> ServiceStartup:
    _ = restored_settings

    return _started(cookie_security, {_COOKIE_SECURITY_VARIABLE: None})


@when(
    parsers.parse(
        'the account service starts with the cookie security setting "{value}"'
    ),
    target_fixture="service_startup",
)
def start_with_cookie_setting(
    restored_settings: object, value: str
) -> ServiceStartup:
    _ = restored_settings
    return _started(cookie_security, {_COOKIE_SECURITY_VARIABLE: value})


@then(parsers.parse('it refuses to start because "{reason}"'))
def check_refused_start(service_startup: ServiceStartup, reason: str) -> None:
    assert service_startup.refusal == reason


@then("it starts")
def check_started(service_startup: ServiceStartup) -> None:
    assert service_startup.refusal is None
    assert service_startup.started_module is not None


def _session_cookie_header(account_client: TestClient) -> str:
    reply: Response = account_client.post(_SIGN_UP, json=_SIGN_UP_REQUEST)
    _ = reply.raise_for_status()

    return reply.headers["set-cookie"].lower()


@then("the session cookie is sent only over HTTPS")
def check_cookie_secure(account_client: TestClient) -> None:
    assert _SECURE_ATTRIBUTE in _session_cookie_header(account_client)


@then("the session cookie is also sent over plain HTTP")
def check_cookie_not_secure(account_client: TestClient) -> None:
    assert _SECURE_ATTRIBUTE not in _session_cookie_header(account_client)


@pytest.fixture
def postgres_server(monkeypatch: pytest.MonkeyPatch) -> FakePostgresServer:
    server = FakePostgresServer()
    monkeypatch.setattr(psycopg2, "connect", server.connect)

    return server


@given("the Postgres server has no account database")
def remove_account_database(postgres_server: FakePostgresServer) -> None:
    postgres_server.cursor.existing = None


@given("the Postgres server already has the account database")
def keep_account_database(postgres_server: FakePostgresServer) -> None:
    postgres_server.cursor.existing = _EXISTING_DATABASE


@when("the account migrations start against Postgres")
def start_migrations_on_postgres(postgres_server: FakePostgresServer) -> None:
    _ = postgres_server
    database_provisioning.create_postgres_database_if_configured(_POSTGRES_URL)


@when("the account migrations start against SQLite")
def start_migrations_on_sqlite(postgres_server: FakePostgresServer) -> None:
    _ = postgres_server
    database_provisioning.create_postgres_database_if_configured(_SQLITE_URL)


def _created_databases(postgres_server: FakePostgresServer) -> list[str]:
    created: list[str] = []

    for statement in postgres_server.cursor.statements:
        if _CREATE_DATABASE in str(statement):
            created.append(str(statement))

    return created


@then("the account database is created")
def check_database_created(postgres_server: FakePostgresServer) -> None:
    assert len(_created_databases(postgres_server)) == 1


@then("no database is created")
def check_no_database_created(postgres_server: FakePostgresServer) -> None:
    assert postgres_server.connection_count == 1
    assert _created_databases(postgres_server) == []


@then("the Postgres server is never contacted")
def check_postgres_untouched(postgres_server: FakePostgresServer) -> None:
    assert postgres_server.connection_count == 0
