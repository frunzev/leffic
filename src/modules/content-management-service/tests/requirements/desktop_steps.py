import threading
import time
from pathlib import Path
from typing import NamedTuple, cast

import hypothesis
import pytest
import uvicorn
from alembic.script import ScriptDirectory
from hypothesis import strategies as st
from pytest_bdd import given, parsers, then, when
from sqlalchemy import create_engine, inspect, text

from desktop import desktop_server
from desktop.database_upgrade import upgrade_database
from desktop.desktop_parent import read_parent_process_id
from desktop.desktop_port import read_desktop_port
from desktop.parent_watch import watch_parent
from tests.migration_support import alembic_config, service_root

_POLL_SECONDS = 0.01
_PATIENCE_SECONDS = 2.0
_OBSERVED_POLLS = 10
_ADOPTING_PROCESS_ID = 1
_PORT_VARIABLE = "DESKTOP_PORT"
_PARENT_VARIABLE = "DESKTOP_PARENT_PROCESS_ID"
_DATABASE_FILE = "desktop.db"
_MIGRATIONS_DIRECTORY = "migrations"
_VERSION_QUERY = text("SELECT version_num FROM alembic_version")
_PROPERTY_EXAMPLES = 60
_UNPRIVILEGED_PORTS = st.integers(min_value=1024, max_value=65535)
_REFUSED_PORTS = st.one_of(
    st.integers(min_value=0, max_value=1023),
    st.integers(min_value=65536, max_value=10_000_000),
)
_UNREADABLE_PROCESS_IDS = st.text(alphabet="abc-. ", max_size=6)
_TABLES_STEP = (
    'the database has the tables "{first_table}", "{second_table}", '
    '"{third_table}" and "{fourth_table}"'
)
_START_STEP = (
    "the desktop backend starts on port {port:d} "
    "for the app with process id {process_id:d}"
)


class WatchedApp:
    def __init__(self, process_id: int) -> None:
        self.parent_process_id: int = process_id
        self.stopped: threading.Event = threading.Event()

    def read_parent_id(self) -> int:
        return self.parent_process_id

    def stop_backend(self) -> None:
        self.stopped.set()

    def exit(self) -> None:
        self.parent_process_id = _ADOPTING_PROCESS_ID


class ServedAddress(NamedTuple):
    host: str
    port: int


class RecordingServer:
    def __init__(self) -> None:
        self.addresses: list[ServedAddress] = []

    def run(self, app: object, *, host: str, port: int) -> None:
        _ = app
        self.addresses.append(ServedAddress(host, port))


def _ignore(*_arguments: object) -> None:
    return None


@hypothesis.settings(max_examples=_PROPERTY_EXAMPLES, deadline=None)
@hypothesis.given(port=_UNPRIVILEGED_PORTS)
def _accepts_every_unprivileged_port(port: int) -> None:
    assert read_desktop_port({_PORT_VARIABLE: str(port)}) == port


@hypothesis.settings(max_examples=_PROPERTY_EXAMPLES, deadline=None)
@hypothesis.given(port=_REFUSED_PORTS)
def _refuses_every_impossible_port(port: int) -> None:
    with pytest.raises(ValueError, match=_PORT_VARIABLE):
        _ = read_desktop_port({_PORT_VARIABLE: str(port)})


@hypothesis.settings(max_examples=_PROPERTY_EXAMPLES, deadline=None)
@hypothesis.given(process_id_text=_UNREADABLE_PROCESS_IDS)
def _refuses_every_unreadable_process_id(process_id_text: str) -> None:
    with pytest.raises(ValueError, match=_PARENT_VARIABLE):
        _ = read_parent_process_id({_PARENT_VARIABLE: process_id_text})


def _upgraded_database(tmp_path: Path, upgrade_count: int) -> str:
    database_url = f"sqlite:///{tmp_path / _DATABASE_FILE}"
    migrations = service_root() / _MIGRATIONS_DIRECTORY

    for _ in range(upgrade_count):
        upgrade_database(migrations, database_url)

    return database_url


@given(
    parsers.parse(
        "the desktop backend watches the app with process id {process_id:d}"
    ),
    target_fixture="watched_app",
)
def watch_app(request: pytest.FixtureRequest, process_id: int) -> WatchedApp:
    watched_app = WatchedApp(process_id)
    _ = watch_parent(
        process_id,
        watched_app.read_parent_id,
        watched_app.stop_backend,
        _POLL_SECONDS,
    )
    request.addfinalizer(watched_app.exit)

    return watched_app


@when(parsers.parse("the app with process id {process_id:d} exits"))
def exit_app(watched_app: WatchedApp, process_id: int) -> None:
    assert watched_app.read_parent_id() == process_id
    watched_app.exit()


@when("the app keeps running")
def keep_app_running() -> None:
    time.sleep(_POLL_SECONDS * _OBSERVED_POLLS)


@then("the desktop backend stops itself")
def check_backend_stopped(watched_app: WatchedApp) -> None:
    assert watched_app.stopped.wait(timeout=_PATIENCE_SECONDS)


@then("the desktop backend keeps running")
def check_backend_running(watched_app: WatchedApp) -> None:
    assert not watched_app.stopped.wait(
        timeout=_POLL_SECONDS * _OBSERVED_POLLS
    )


@then("every port from 1024 to 65535 is accepted for the desktop backend")
def check_ports_accepted() -> None:
    _accepts_every_unprivileged_port()


@then(
    "every port below 1024 or above 65535 is refused for the desktop backend"
)
def check_ports_refused() -> None:
    _refuses_every_impossible_port()


@when(parsers.parse(_START_STEP), target_fixture="recording_server")
def start_backend(
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: Path,
    port: int,
    process_id: int,
) -> RecordingServer:
    monkeypatch.chdir(tmp_path)
    recording_server = RecordingServer()
    monkeypatch.setattr(desktop_server, "upgrade_database", _ignore)
    monkeypatch.setattr(desktop_server, "start_generation_worker", _ignore)
    monkeypatch.setattr(desktop_server, "watch_parent", _ignore)
    monkeypatch.setattr(uvicorn, "run", recording_server.run)
    environment = {
        _PORT_VARIABLE: str(port),
        _PARENT_VARIABLE: str(process_id),
    }

    migrations = service_root() / _MIGRATIONS_DIRECTORY
    desktop_server.serve_desktop(environment, migrations)

    return recording_server


@then(parsers.parse('it listens on "{host}" port {port:d}'))
def check_listening(
    recording_server: RecordingServer, host: str, port: int
) -> None:
    assert recording_server.addresses == [ServedAddress(host, port)]


@then("every missing or unreadable app process id is refused")
def check_unreadable_process_ids_refused() -> None:
    with pytest.raises(ValueError, match=_PARENT_VARIABLE):
        _ = read_parent_process_id({})

    _refuses_every_unreadable_process_id()


@then(parsers.parse("the app process id {process_id:d} is refused"))
def check_process_id_refused(process_id: int) -> None:
    with pytest.raises(ValueError, match=_PARENT_VARIABLE):
        _ = read_parent_process_id({_PARENT_VARIABLE: str(process_id)})


@when(
    "the desktop backend upgrades a fresh database",
    target_fixture="database_url",
)
def upgrade_fresh_database(tmp_path: Path) -> str:
    return _upgraded_database(tmp_path, upgrade_count=1)


@when(
    "the desktop backend upgrades a fresh database twice",
    target_fixture="database_url",
)
def upgrade_fresh_database_twice(tmp_path: Path) -> str:
    return _upgraded_database(tmp_path, upgrade_count=2)


@then(parsers.parse(_TABLES_STEP))
def check_tables(
    database_url: str,
    first_table: str,
    second_table: str,
    third_table: str,
    fourth_table: str,
) -> None:
    engine = create_engine(database_url)
    table_names = set(inspect(engine).get_table_names())
    engine.dispose()
    expected_tables = {first_table, second_table, third_table, fourth_table}

    assert expected_tables <= table_names


@then("the database is at the latest revision")
def check_latest_revision(database_url: str) -> None:
    scripts = ScriptDirectory.from_config(alembic_config(database_url))
    engine = create_engine(database_url)

    with engine.connect() as connection:
        recorded = cast("str", connection.execute(_VERSION_QUERY).scalar_one())

    engine.dispose()

    assert recorded == scripts.get_current_head()
