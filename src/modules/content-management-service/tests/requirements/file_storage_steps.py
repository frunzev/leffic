from collections.abc import Callable
from pathlib import Path
from typing import BinaryIO

import pytest
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from shared.local_disk_file_storage import LocalDiskFileStorage
from tests.pdf_support import PdfDocuments
from tests.requirements.file_steps import HomeUploader, stored_file_id
from tests.requirements.requirement_listing import (
    FILE_ENTRY,
    HOME,
    entries_of_type,
    entry_names,
)
from tests.requirements.requirement_lookup import (
    Sessions,
    folder_id_named,
    home_folder_id,
    reply_body,
)
from tests.support import authorization

_FILE_BOOKMARK = "/file-bookmark"
_STORAGE_FAILURE = "the disk is full"
_FAILING_SAVE_NUMBER = 2
_LONG_EXTENSION_LETTER = "x"
_LONG_NAME_STEM = "notes."

StorageSave = Callable[[LocalDiskFileStorage, BinaryIO, str], None]


class SecondSaveFailure:
    def __init__(
        self, files_directory: Path, original_save: StorageSave
    ) -> None:
        self._files_directory: Path = files_directory
        self._original_save: StorageSave = original_save
        self.save_count: int = 0

    def __call__(self, content: BinaryIO, stored_name: str) -> None:
        self.save_count += 1

        if self.save_count == _FAILING_SAVE_NUMBER:
            raise OSError(_STORAGE_FAILURE)

        storage = LocalDiskFileStorage(self._files_directory)
        self._original_save(storage, content, stored_name)


def _pdf_upload(file_name: str) -> tuple[str, bytes]:
    return file_name, PdfDocuments.with_text([file_name])


@given("storage fails while saving the second file")
def fail_second_save(
    monkeypatch: pytest.MonkeyPatch, stored_files_directory: Path
) -> None:
    second_save_failure = SecondSaveFailure(
        stored_files_directory, LocalDiskFileStorage.save
    )
    monkeypatch.setattr(LocalDiskFileStorage, "save", second_save_failure)


@when(
    parsers.parse(
        (
            'I try to upload the PDFs "{first_file_name}" and '
            '"{second_file_name}" into home'
        )
    ),
    target_fixture="reply",
)
def try_to_upload_pdfs(
    home_uploader: HomeUploader,
    sessions: Sessions,
    first_file_name: str,
    second_file_name: str,
) -> Response:
    uploads = [_pdf_upload(first_file_name), _pdf_upload(second_file_name)]

    return home_uploader.attempted_upload(home_folder_id(sessions), uploads)


@when(
    parsers.parse(
        (
            'I try to upload the PDF "{file_name}" and a file with a '
            "{extension_length:d}-letter extension into home"
        )
    ),
    target_fixture="reply",
)
def try_to_upload_long_name(
    home_uploader: HomeUploader,
    sessions: Sessions,
    file_name: str,
    extension_length: int,
) -> Response:
    long_extension = _LONG_EXTENSION_LETTER * extension_length
    long_file_name = f"{_LONG_NAME_STEM}{long_extension}"
    uploads = [_pdf_upload(file_name), (long_file_name, file_name.encode())]

    return home_uploader.attempted_upload(home_folder_id(sessions), uploads)


@then("home contains no files")
def check_home_has_no_files(client: TestClient) -> None:
    assert entry_names(client, HOME, FILE_ENTRY) == []


@then(parsers.parse('the file "{file_name}" is listed without a size'))
def check_file_without_size(client: TestClient, file_name: str) -> None:
    listed_sizes: dict[object, object] = {}

    for file_entry in entries_of_type(client, HOME, FILE_ENTRY):
        listed_sizes[file_entry["name"]] = file_entry["size_bytes"]

    assert listed_sizes[file_name] is None


@given(
    parsers.parse(
        'I upload the PDF "{file_name}" saying "{page_text}" into "{folder_name}"'
    )
)
def upload_pdf_into_folder(
    home_uploader: HomeUploader,
    sessions: Sessions,
    file_name: str,
    page_text: str,
    folder_name: str,
) -> None:
    folder_id = folder_id_named(sessions, folder_name)
    pdf_document = PdfDocuments.with_text([page_text])
    home_uploader.upload_into(folder_id, [(file_name, pdf_document)])


@when(
    parsers.parse('I open the bookmark of "{file_name}"'),
    target_fixture="reply",
)
def open_bookmark(
    client: TestClient, sessions: Sessions, file_name: str
) -> Response:
    return client.get(
        _FILE_BOOKMARK,
        params={"file_id": stored_file_id(sessions, file_name)},
        headers=authorization(),
    )


@then(parsers.parse("it counts {page_count:d} pages"))
@then(parsers.parse("it counts {page_count:d} page"))
def check_page_count(reply: Response, page_count: int) -> None:
    assert reply_body(reply)["page_count"] == page_count
