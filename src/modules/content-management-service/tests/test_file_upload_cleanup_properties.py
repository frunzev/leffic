import tempfile
import uuid
from pathlib import Path
from unittest import mock

import pytest
from fastapi.testclient import TestClient
from hypothesis import given, settings
from hypothesis import strategies as st

from tests.access_support import _wired_app
from tests.file_storage_fakes import (
    FailingFileStorage,
    injected_file_storage,
)
from tests.file_upload_support import (
    EXTENSIONS,
    RECORDED_FILES,
    STORAGE_FAILURE_MESSAGE,
    emptied,
    names_in,
    numbered_filenames,
    storage_directory,
    upload,
)
from tests.folder_seeding import seeded_folder
from tests.property_support import property_world
from tests.support import USER_ID, authorization

_PROPERTY_CLIENT, _PROPERTY_SESSIONS = property_world()
_STRICT_CLIENT = TestClient(_wired_app(_PROPERTY_SESSIONS))
_PROPERTY_STORAGE = Path(tempfile.mkdtemp())


def _seeded_owned_folder() -> str:
    with _PROPERTY_SESSIONS() as session:
        return str(seeded_folder(session, uuid.UUID(USER_ID), {}))


@settings(max_examples=20, deadline=None)
@given(st.integers(min_value=1, max_value=4), EXTENSIONS)
def test_upload_files_property_writes_no_bytes_when_storage_fails(
    file_count: int, extension: str
) -> None:
    directory = emptied(_PROPERTY_STORAGE)
    failing_storage = FailingFileStorage(
        directory, file_count - 1, STORAGE_FAILURE_MESSAGE
    )

    with injected_file_storage(_PROPERTY_CLIENT, failing_storage):
        _ = upload(
            _PROPERTY_CLIENT,
            _seeded_owned_folder(),
            authorization(),
            numbered_filenames(file_count, extension),
        )

    assert names_in(directory) == set()


@settings(max_examples=20, deadline=None)
@given(st.integers(min_value=1, max_value=4), EXTENSIONS)
def test_upload_files_property_writes_no_bytes_when_the_database_fails(
    file_count: int, extension: str
) -> None:
    directory = emptied(_PROPERTY_STORAGE)

    with storage_directory(directory), mock.patch(
        RECORDED_FILES, side_effect=RuntimeError(STORAGE_FAILURE_MESSAGE)
    ):
        _ = upload(
            _PROPERTY_CLIENT,
            _seeded_owned_folder(),
            authorization(),
            numbered_filenames(file_count, extension),
        )

    assert names_in(directory) == set()


@settings(max_examples=20, deadline=None)
@given(st.text(min_size=1, max_size=40))
def test_upload_files_property_reraises_the_storage_failure_unchanged(
    message: str,
) -> None:
    directory = emptied(_PROPERTY_STORAGE)
    failing_storage = FailingFileStorage(directory, 0, message)

    with injected_file_storage(
        _STRICT_CLIENT, failing_storage
    ), pytest.raises(RuntimeError) as raised:
        _ = upload(
            _STRICT_CLIENT, _seeded_owned_folder(), authorization()
        )

    assert str(raised.value) == message
