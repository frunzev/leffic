from fastapi.testclient import TestClient
from sqlalchemy.orm import Session, sessionmaker

from tests.access_support import HOME_ID, seeded_content
from tests.file_storage_fakes import (
    RecordingFileStorage,
    injected_file_storage,
)
from tests.support import authorization

_OK = 200


def test_deleting_a_file_removes_it_through_the_injected_storage(
    client: TestClient, sessions: sessionmaker[Session]
) -> None:
    owned = seeded_content(sessions, HOME_ID)
    recording_storage = RecordingFileStorage()

    with injected_file_storage(client, recording_storage):
        response = client.request(
            "DELETE",
            "/delete-file/",
            params={"file_id": owned.file_id},
            headers=authorization(),
        )

    assert response.status_code == _OK
    assert recording_storage.deleted == [f"{owned.file_id}.pdf"]


def test_deleting_a_folder_removes_its_files_through_the_injected_storage(
    client: TestClient, sessions: sessionmaker[Session]
) -> None:
    owned = seeded_content(sessions, HOME_ID)
    recording_storage = RecordingFileStorage()

    with injected_file_storage(client, recording_storage):
        response = client.request(
            "DELETE",
            "/delete-folder/",
            params={"folder_id": owned.folder_id},
            headers=authorization(),
        )

    assert response.status_code == _OK
    assert recording_storage.deleted == [f"{owned.file_id}.pdf"]


def test_uploading_writes_through_the_injected_storage(
    client: TestClient, sessions: sessionmaker[Session]
) -> None:
    owned = seeded_content(sessions, HOME_ID)
    recording_storage = RecordingFileStorage()

    with injected_file_storage(client, recording_storage):
        response = client.post(
            "/upload-files",
            files={"files": ("notes.pdf", b"payload", "application/pdf")},
            data={"folder_id": owned.folder_id},
            headers=authorization(),
        )

    assert response.status_code == _OK
    assert list(recording_storage.saved.values()) == [b"payload"]
