import contextlib
import tempfile
from pathlib import Path
from unittest import mock

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

from desktop.desktop_server import serve_desktop
from desktop.parent_watch import stop_this_process
from features.study_units_generation.celery_app import celery_app
from shared.database import SQLALCHEMY_DATABASE_URL

_UPGRADE = "desktop.desktop_server.upgrade_database"
_WORKER = "desktop.desktop_server.start_generation_worker"
_SERVE = "desktop.desktop_server.uvicorn.run"
_WATCH = "desktop.desktop_server.watch_parent"
_LOOPBACK_HOST = "127.0.0.1"
_MIGRATIONS = Path("/bundle/migrations")
_FILES_DIRECTORY = "files"
_APP_PROCESS_ID = 4242

_UNPRIVILEGED_PORTS = st.integers(min_value=1024, max_value=65535)
_REFUSED_PORT_TEXT = st.one_of(
    st.integers(min_value=0, max_value=1023).map(str),
    st.integers(min_value=65536).map(str),
    st.text(alphabet="abc-. ", max_size=6),
)
_REFUSED_PARENT_TEXT = st.text(alphabet="abc-. ", max_size=6)
_REFUSED_ENVIRONMENTS = st.one_of(
    st.fixed_dictionaries(
        {
            "DESKTOP_PORT": _REFUSED_PORT_TEXT,
            "DESKTOP_PARENT_PROCESS_ID": st.just(str(_APP_PROCESS_ID)),
        }
    ),
    st.fixed_dictionaries(
        {
            "DESKTOP_PORT": st.just("4100"),
            "DESKTOP_PARENT_PROCESS_ID": _REFUSED_PARENT_TEXT,
        }
    ),
)


@settings(max_examples=25, deadline=None)
@given(_UNPRIVILEGED_PORTS)
def test_serve_desktop_property_listens_only_on_the_loopback_address(
    port: int,
) -> None:
    with (
        tempfile.TemporaryDirectory() as data_directory,
        contextlib.chdir(data_directory),
        mock.patch(_UPGRADE) as upgrade,
        mock.patch(_WORKER) as worker,
        mock.patch(_WATCH) as watch,
        mock.patch(_SERVE) as serve,
    ):
        serve_desktop(
            {
                "DESKTOP_PORT": str(port),
                "DESKTOP_PARENT_PROCESS_ID": str(_APP_PROCESS_ID),
            },
            _MIGRATIONS,
        )
        files_directory_exists = Path(_FILES_DIRECTORY).is_dir()

    upgrade.assert_called_once_with(_MIGRATIONS, SQLALCHEMY_DATABASE_URL)
    worker.assert_called_once_with(celery_app)
    assert watch.call_args.args[0] == _APP_PROCESS_ID
    assert watch.call_args.args[2] is stop_this_process
    assert serve.call_args.kwargs["host"] == _LOOPBACK_HOST
    assert serve.call_args.kwargs["port"] == port
    assert files_directory_exists


@settings(max_examples=50, deadline=None)
@given(_REFUSED_ENVIRONMENTS)
def test_serve_desktop_property_starts_nothing_for_refused_settings(
    environment: dict[str, str],
) -> None:
    with (
        mock.patch(_UPGRADE) as upgrade,
        mock.patch(_WORKER) as worker,
        mock.patch(_WATCH) as watch,
        mock.patch(_SERVE) as serve,
        pytest.raises(ValueError, match="DESKTOP_"),
    ):
        serve_desktop(environment, _MIGRATIONS)

    upgrade.assert_not_called()
    worker.assert_not_called()
    watch.assert_not_called()
    serve.assert_not_called()
