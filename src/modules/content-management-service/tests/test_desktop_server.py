import contextlib
import tempfile
from pathlib import Path
from unittest import mock

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

from desktop.desktop_server import serve_desktop
from features.study_units_generation.celery_app import celery_app
from shared.database import SQLALCHEMY_DATABASE_URL

_UPGRADE = "desktop.desktop_server.upgrade_database"
_WORKER = "desktop.desktop_server.start_generation_worker"
_SERVE = "desktop.desktop_server.uvicorn.run"
_LOOPBACK_HOST = "127.0.0.1"
_MIGRATIONS = Path("/bundle/migrations")
_FILES_DIRECTORY = "files"

_UNPRIVILEGED_PORTS = st.integers(min_value=1024, max_value=65535)
_REFUSED_PORT_TEXT = st.one_of(
    st.integers(min_value=0, max_value=1023).map(str),
    st.integers(min_value=65536).map(str),
    st.text(alphabet="abc-. ", max_size=6),
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
        mock.patch(_SERVE) as serve,
    ):
        serve_desktop({"DESKTOP_PORT": str(port)}, _MIGRATIONS)
        files_directory_exists = Path(_FILES_DIRECTORY).is_dir()

    upgrade.assert_called_once_with(_MIGRATIONS, SQLALCHEMY_DATABASE_URL)
    worker.assert_called_once_with(celery_app)
    assert serve.call_args.kwargs["host"] == _LOOPBACK_HOST
    assert serve.call_args.kwargs["port"] == port
    assert files_directory_exists


@settings(max_examples=25, deadline=None)
@given(_REFUSED_PORT_TEXT)
def test_serve_desktop_property_starts_nothing_for_a_refused_port(
    port_text: str,
) -> None:
    with (
        mock.patch(_UPGRADE) as upgrade,
        mock.patch(_WORKER) as worker,
        mock.patch(_SERVE) as serve,
        pytest.raises(ValueError, match="DESKTOP_PORT"),
    ):
        serve_desktop({"DESKTOP_PORT": port_text}, _MIGRATIONS)

    upgrade.assert_not_called()
    worker.assert_not_called()
    serve.assert_not_called()
