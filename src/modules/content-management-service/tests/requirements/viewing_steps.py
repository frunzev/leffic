import shlex
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from shared import libreoffice_exporter
from tests.pdf_support import PdfDocuments
from tests.requirements.file_steps import file_extension, stored_file_id
from tests.requirements.requirement_lookup import Sessions, told_message
from tests.support import authorization

_FILE = "/file"
_PDF_MEDIA_TYPE = "application/pdf"
_OK = 200
_MISSING_LIBREOFFICE = "missing-libreoffice"
_FAKE_LIBREOFFICE = "fake-libreoffice"
_CONVERTED_PDF = "converted.pdf"
_LIBREOFFICE_NOT_INSTALLED = "LibreOffice is not installed"
_EXECUTABLE = 0o755
_CONVERTER_SCRIPT = """#!/bin/sh
output_directory="$5"
source_name=$(basename "$6")
cp {converted_pdf} "$output_directory/${{source_name%.*}}.pdf"
"""


def _use_libreoffice(
    monkeypatch: pytest.MonkeyPatch, libreoffice_binary: Path
) -> None:
    monkeypatch.setattr(
        libreoffice_exporter, "LIBREOFFICE_BINARY", str(libreoffice_binary)
    )


@given("LibreOffice is not installed")
def remove_libreoffice(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    _use_libreoffice(monkeypatch, tmp_path / _MISSING_LIBREOFFICE)


@given("LibreOffice converts files to PDF")
def install_converting_libreoffice(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    converted_pdf = tmp_path / _CONVERTED_PDF
    _ = converted_pdf.write_bytes(PdfDocuments.blank(1))

    converter = tmp_path / _FAKE_LIBREOFFICE
    script = _CONVERTER_SCRIPT.format(
        converted_pdf=shlex.quote(str(converted_pdf))
    )
    _ = converter.write_text(script, encoding="utf-8")
    converter.chmod(_EXECUTABLE)

    _use_libreoffice(monkeypatch, converter)


@when(parsers.parse('I open the file "{file_name}"'), target_fixture="reply")
def open_file(
    client: TestClient, sessions: Sessions, file_name: str
) -> Response:
    file_request = {
        "file_id": stored_file_id(sessions, file_name),
        "file_extension": file_extension(file_name),
    }

    return client.get(_FILE, params=file_request, headers=authorization())


@then("I get a PDF")
def check_pdf_received(reply: Response) -> None:
    assert reply.status_code == _OK
    assert reply.headers["content-type"] == _PDF_MEDIA_TYPE


@then("I am told LibreOffice is not installed")
def check_libreoffice_reported(reply: Response) -> None:
    assert _LIBREOFFICE_NOT_INSTALLED in str(told_message(reply))
