import subprocess
from pathlib import Path
from unittest import mock

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

from shared.libreoffice_exporter import (
    LibreOfficeExporter,
    provide_pdf_conversion,
)
from shared.pdf_conversion import ConversionError
from tests.pdf_support import LibreOfficeStub, PdfDocuments

_EXTENSIONS = st.sampled_from(["docx", "odt", "pptx", "rtf"])
_PAGE_COUNTS = st.integers(min_value=1, max_value=6)
_DIRECTORIES = st.text(alphabet="abc", min_size=1, max_size=6)
_STEMS = st.text(alphabet="abcdef", min_size=1, max_size=8)
_SUBPROCESS_RUN = "shared.libreoffice_exporter.subprocess.run"
_CONFIGURED_BINARY = "shared.libreoffice_exporter.LIBREOFFICE_BINARY"
_LIBREOFFICE_BINARIES = (
    "libreoffice",
    "/Applications/LibreOffice.app/Contents/MacOS/soffice",
    "/usr/bin/soffice",
)


@settings(max_examples=50)
@given(_EXTENSIONS, _DIRECTORIES)
def test__command_property_always_writes_a_pdf_into_the_given_directory(
    extension: str, directory: str
) -> None:
    source = Path(f"/work/document.{extension}")
    command = LibreOfficeExporter._command(source, directory)

    assert command[0] == "libreoffice"
    assert "--headless" in command
    assert command[command.index("--convert-to") + 1] == "pdf"
    assert command[command.index("--outdir") + 1] == directory
    assert command[-1] == str(source)


@settings(max_examples=25, deadline=None)
@given(_STEMS, _EXTENSIONS, _DIRECTORIES)
def test_export_pdf_property_names_the_pdf_after_the_source(
    stem: str, extension: str, directory: str
) -> None:
    succeeded = subprocess.CompletedProcess(
        args=[], returncode=0, stderr=b""
    )
    source = Path(f"/work/{stem}.{extension}")

    with mock.patch(_SUBPROCESS_RUN, return_value=succeeded):
        exported = LibreOfficeExporter().export_pdf(source, directory)

    assert exported == Path(directory) / f"{stem}.pdf"


@settings(max_examples=10, deadline=None)
@given(st.integers(min_value=1, max_value=9))
def test_export_pdf_property_reports_whatever_libreoffice_complained(
    return_code: int,
) -> None:
    failure = subprocess.CompletedProcess(
        args=[], returncode=return_code, stderr=b"it went wrong"
    )
    source = Path("/work/document.docx")

    with (
        mock.patch(_SUBPROCESS_RUN, return_value=failure),
        pytest.raises(ConversionError, match="it went wrong"),
    ):
        _ = LibreOfficeExporter().export_pdf(source, "/work")


@settings(max_examples=25)
@given(_EXTENSIONS, st.sampled_from(_LIBREOFFICE_BINARIES))
def test__command_property_starts_the_configured_libreoffice(
    extension: str, binary: str
) -> None:
    source = Path(f"/work/document.{extension}")

    with mock.patch(_CONFIGURED_BINARY, binary):
        command = LibreOfficeExporter._command(source, "/work")

    assert command[0] == binary


@settings(max_examples=10, deadline=None)
@given(st.sampled_from(_LIBREOFFICE_BINARIES))
def test_export_pdf_property_names_a_missing_libreoffice(binary: str) -> None:
    source = Path("/work/document.docx")
    missing = FileNotFoundError(binary)

    with (
        mock.patch(_CONFIGURED_BINARY, binary),
        mock.patch(_SUBPROCESS_RUN, side_effect=missing),
        pytest.raises(ConversionError, match="LibreOffice is not installed"),
    ):
        _ = LibreOfficeExporter().export_pdf(source, "/work")


@settings(max_examples=10, deadline=None)
@given(_EXTENSIONS, _PAGE_COUNTS)
def test_provide_pdf_conversion_property_converts_through_libreoffice(
    extension: str, page_count: int
) -> None:
    stub = LibreOfficeStub(page_count)

    with mock.patch(_SUBPROCESS_RUN, stub):
        produced = provide_pdf_conversion().converted(b"anything", extension)

    assert PdfDocuments.page_count(produced) == page_count
    assert stub.converted_sources == [f"document.{extension}"]
