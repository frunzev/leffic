from collections.abc import Iterator
from pathlib import Path
from unittest import mock

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session, sessionmaker

from shared.models import File as StoredFile
from tests.access_support import crashless_client, scoped_client
from tests.file_storage_fakes import (
    FailingFileStorage,
    injected_file_storage,
)
from tests.file_upload_support import (
    LEARNER_FOLDER_ID,
    RECORDED_FILES,
    SERVER_ERROR,
    STORAGE_FAILURE_MESSAGE,
    names_in,
    numbered_filenames,
    sessions_without_a_home_folder,
    storage_directory,
    upload,
)
from tests.support import authorization


@pytest.fixture
def sessions() -> sessionmaker[Session]:
    return sessions_without_a_home_folder()


@pytest.fixture
def crashless(sessions: sessionmaker[Session]) -> Iterator[TestClient]:
    yield from crashless_client(sessions)


@pytest.fixture
def strict(sessions: sessionmaker[Session]) -> Iterator[TestClient]:
    yield from scoped_client(sessions)


def test_storage_failure_midway_removes_the_earlier_files(
    crashless: TestClient, tmp_path: Path
) -> None:
    failing_storage = FailingFileStorage(tmp_path, 2, STORAGE_FAILURE_MESSAGE)

    with injected_file_storage(crashless, failing_storage):
        response = upload(
            crashless,
            LEARNER_FOLDER_ID,
            authorization(),
            numbered_filenames(3, "pdf"),
        )

    assert response.status_code == SERVER_ERROR
    assert names_in(tmp_path) == set()


def test_storage_failure_on_the_first_file_writes_nothing(
    crashless: TestClient, tmp_path: Path
) -> None:
    failing_storage = FailingFileStorage(tmp_path, 0, STORAGE_FAILURE_MESSAGE)

    with injected_file_storage(crashless, failing_storage):
        _ = upload(
            crashless,
            LEARNER_FOLDER_ID,
            authorization(),
            numbered_filenames(3, "pdf"),
        )

    assert names_in(tmp_path) == set()


def test_storage_failure_on_the_last_of_many_files_removes_them_all(
    crashless: TestClient, tmp_path: Path
) -> None:
    failing_storage = FailingFileStorage(tmp_path, 9, STORAGE_FAILURE_MESSAGE)

    with injected_file_storage(crashless, failing_storage):
        _ = upload(
            crashless,
            LEARNER_FOLDER_ID,
            authorization(),
            numbered_filenames(10, "pdf"),
        )

    assert names_in(tmp_path) == set()


def test_storage_failure_commits_nothing(
    crashless: TestClient,
    sessions: sessionmaker[Session],
    tmp_path: Path,
) -> None:
    failing_storage = FailingFileStorage(tmp_path, 1, STORAGE_FAILURE_MESSAGE)

    with injected_file_storage(crashless, failing_storage):
        _ = upload(
            crashless,
            LEARNER_FOLDER_ID,
            authorization(),
            numbered_filenames(2, "pdf"),
        )

    with sessions() as session:
        assert session.query(StoredFile).count() == 0


def test_database_failure_removes_every_written_file(
    crashless: TestClient, tmp_path: Path
) -> None:
    with storage_directory(tmp_path), mock.patch(
        RECORDED_FILES, side_effect=RuntimeError(STORAGE_FAILURE_MESSAGE)
    ):
        response = upload(
            crashless,
            LEARNER_FOLDER_ID,
            authorization(),
            numbered_filenames(3, "pdf"),
        )

    assert response.status_code == SERVER_ERROR
    assert names_in(tmp_path) == set()


def test_a_storage_failure_reaches_the_caller_unchanged(
    strict: TestClient, tmp_path: Path
) -> None:
    failing_storage = FailingFileStorage(tmp_path, 1, STORAGE_FAILURE_MESSAGE)

    with injected_file_storage(strict, failing_storage), pytest.raises(
        RuntimeError, match=STORAGE_FAILURE_MESSAGE
    ):
        _ = upload(
            strict,
            LEARNER_FOLDER_ID,
            authorization(),
            numbered_filenames(2, "pdf"),
        )


def test_a_database_failure_reaches_the_caller_unchanged(
    strict: TestClient, tmp_path: Path
) -> None:
    with storage_directory(tmp_path), mock.patch(
        RECORDED_FILES, side_effect=RuntimeError(STORAGE_FAILURE_MESSAGE)
    ), pytest.raises(RuntimeError, match=STORAGE_FAILURE_MESSAGE):
        _ = upload(strict, LEARNER_FOLDER_ID, authorization())


def test_upload_files_does_not_roll_back_by_hand(
    crashless: TestClient, tmp_path: Path
) -> None:
    with storage_directory(tmp_path), mock.patch.object(
        Session, "commit", side_effect=RuntimeError(STORAGE_FAILURE_MESSAGE)
    ), mock.patch.object(Session, "rollback") as rollback:
        response = upload(crashless, LEARNER_FOLDER_ID, authorization())

    assert response.status_code == SERVER_ERROR
    assert names_in(tmp_path) == set()
    assert not rollback.called
