from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from shared.models import File
from tests.pdf_support import PdfDocuments
from tests.requirements.requirement_listing import (
    FILE_ENTRY,
    HOME,
    entry_names,
)
from tests.requirements.requirement_lookup import (
    Sessions,
    home_folder_id,
    is_unit_named,
    unit_id_named,
)
from tests.support import authorization

_UPLOAD_FILES = "/upload-files"
_DELETE_FILE = "/delete-file/"
_FILES_DIRECTORY = "files"
_OFFICE_DOCUMENT = b"PK\x03\x04 an office document"
_IMAGE_DOCUMENT = b"\x89PNG\r\n\x1a\n an image"
_FILE_FIELD = "files"
_PDF_TEXT_STEP = (
    'I upload the PDF "{file_name}" saying "{page_text}" into home'
)
_PDF_PAGES_STEP = (
    'I upload the PDF "{file_name}" with the pages '
    '"{first_page_text}" and "{second_page_text}" into home'
)
_TWO_PDFS_STEP = (
    'I upload the PDFs "{first_file_name}" and "{second_file_name}" into home'
)

Upload = tuple[str, bytes]


class HomeUploader:
    def __init__(
        self,
        client: TestClient,
        sessions: Sessions,
        stored_files_directory: Path,
    ) -> None:
        self._client: TestClient = client
        self._sessions: Sessions = sessions
        self._stored_files_directory: Path = stored_files_directory

    def attempted_upload(
        self, folder_id: str, uploads: list[Upload]
    ) -> Response:
        multipart_files: list[tuple[str, Upload]] = []

        for upload in uploads:
            multipart_files.append((_FILE_FIELD, upload))

        return self._client.post(
            _UPLOAD_FILES,
            files=multipart_files,
            data={"folder_id": folder_id},
            headers=authorization(),
        )

    def upload(self, uploads: list[Upload]) -> None:
        self.upload_into(home_folder_id(self._sessions), uploads)

    def upload_into(self, folder_id: str, uploads: list[Upload]) -> None:
        reply = self.attempted_upload(folder_id, uploads)
        _ = reply.raise_for_status()

        if not any(self._stored_files_directory.iterdir()):
            message = f"Nothing was stored in {self._stored_files_directory}"
            raise FileNotFoundError(message)


@pytest.fixture
def stored_files_directory(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> Path:
    monkeypatch.chdir(tmp_path)
    files_directory = tmp_path / _FILES_DIRECTORY
    files_directory.mkdir()

    return files_directory


@pytest.fixture
def home_uploader(
    client: TestClient, sessions: Sessions, stored_files_directory: Path
) -> HomeUploader:
    return HomeUploader(client, sessions, stored_files_directory)


def stored_file_id(sessions: Sessions, file_name: str) -> str:
    return unit_id_named(sessions, File, file_name)


def file_extension(file_name: str) -> str:
    return Path(file_name).suffix.lstrip(".")


@given(parsers.parse(_PDF_TEXT_STEP))
@when(parsers.parse(_PDF_TEXT_STEP))
def upload_text_pdf(
    home_uploader: HomeUploader, file_name: str, page_text: str
) -> None:
    pdf_document = PdfDocuments.with_text([page_text])
    home_uploader.upload([(file_name, pdf_document)])


@given(parsers.parse(_PDF_PAGES_STEP))
def upload_two_page_pdf(
    home_uploader: HomeUploader,
    file_name: str,
    first_page_text: str,
    second_page_text: str,
) -> None:
    pdf_document = PdfDocuments.with_text([first_page_text, second_page_text])
    home_uploader.upload([(file_name, pdf_document)])


@given(parsers.parse(_TWO_PDFS_STEP))
@when(parsers.parse(_TWO_PDFS_STEP))
def upload_two_pdfs(
    home_uploader: HomeUploader, first_file_name: str, second_file_name: str
) -> None:
    uploads = [
        (first_file_name, PdfDocuments.with_text([first_file_name])),
        (second_file_name, PdfDocuments.with_text([second_file_name])),
    ]
    home_uploader.upload(uploads)


@given(
    parsers.parse(
        'I upload the {page_count:d}-page PDF "{file_name}" into home'
    )
)
def upload_blank_pdf(
    home_uploader: HomeUploader, page_count: int, file_name: str
) -> None:
    home_uploader.upload([(file_name, PdfDocuments.blank(page_count))])


@given(parsers.parse('I upload the file "{file_name}" into home'))
def upload_office_file(home_uploader: HomeUploader, file_name: str) -> None:
    home_uploader.upload([(file_name, _OFFICE_DOCUMENT)])


@given(parsers.parse('I upload the image "{file_name}" into home'))
def upload_image(home_uploader: HomeUploader, file_name: str) -> None:
    home_uploader.upload([(file_name, _IMAGE_DOCUMENT)])


@then(parsers.parse('home contains the file "{file_name}"'))
def check_home_has_file(client: TestClient, file_name: str) -> None:
    assert file_name in entry_names(client, HOME, FILE_ENTRY)


@when(parsers.parse('I delete the file "{file_name}"'))
def delete_file(
    client: TestClient, sessions: Sessions, file_name: str
) -> None:
    reply = client.delete(
        _DELETE_FILE,
        params={"file_id": stored_file_id(sessions, file_name)},
        headers=authorization(),
    )
    _ = reply.raise_for_status()


@then(parsers.parse('the file "{file_name}" does not exist'))
def check_file_gone(sessions: Sessions, file_name: str) -> None:
    assert not is_unit_named(sessions, File, file_name)


@then("nothing is left on disk")
def check_disk_empty(stored_files_directory: Path) -> None:
    assert list(stored_files_directory.iterdir()) == []
