import tempfile
import uuid
from pathlib import Path

import pytest
from fastapi import HTTPException
from hypothesis import given, settings
from hypothesis import strategies as st

from features.file_system.pdf_page_count import (
    StoredPdfPages,
    provide_stored_pdf_pages,
)
from shared.file_storage import storage_name
from shared.local_disk_file_storage import LocalDiskFileStorage
from shared.models import File
from shared.pdf_conversion import PdfConversion
from tests.file_storage_fakes import KnownFileContents
from tests.pdf_support import CopyingExporter, PdfDocuments, SilentExporter

_BAD_REQUEST = 400
_NOT_FOUND = 404
_PAGE_COUNTS = st.integers(min_value=1, max_value=8)
_CONVERTED_EXTENSIONS = st.sampled_from(["docx", "odt", "pptx", "png"])
_UNREADABLE_DOCUMENTS = st.one_of(
    st.just(b""), st.binary(max_size=64).map(lambda noise: b"x" + noise)
)
_COPYING_CONVERSION = PdfConversion(CopyingExporter())
_FAILING_CONVERSION = PdfConversion(SilentExporter())


def _stored_file(extension: str) -> File:
    return File(id=uuid.uuid4(), name="lecture", extension=extension)


def _contents_for(file: File, document: bytes) -> KnownFileContents:
    stored_name = storage_name(str(file.id), file.extension)

    return KnownFileContents({stored_name: document})


@settings(max_examples=25, deadline=None)
@given(_PAGE_COUNTS)
def test_page_count_of_property_counts_every_page_of_a_stored_pdf(
    page_count: int,
) -> None:
    file = _stored_file("pdf")
    contents = _contents_for(file, PdfDocuments.blank(page_count))

    counted = StoredPdfPages(contents, _FAILING_CONVERSION).page_count_of(
        file
    )

    assert counted == page_count


@settings(max_examples=25, deadline=None)
@given(_PAGE_COUNTS, _CONVERTED_EXTENSIONS)
def test_page_count_of_property_counts_the_converted_pdf(
    page_count: int, extension: str
) -> None:
    file = _stored_file(extension)
    contents = _contents_for(file, PdfDocuments.blank(page_count))

    counted = StoredPdfPages(contents, _COPYING_CONVERSION).page_count_of(
        file
    )

    assert counted == page_count


@settings(max_examples=25, deadline=None)
@given(_UNREADABLE_DOCUMENTS)
def test_page_count_of_property_refuses_an_unreadable_pdf(
    document: bytes,
) -> None:
    file = _stored_file("pdf")
    pages = StoredPdfPages(_contents_for(file, document), _FAILING_CONVERSION)

    with pytest.raises(HTTPException) as refusal:
        _ = pages.page_count_of(file)

    assert refusal.value.status_code == _BAD_REQUEST


@settings(max_examples=25, deadline=None)
@given(st.sampled_from(["pdf", "docx", ""]))
def test__pdf_document_property_refuses_a_file_no_longer_stored(
    extension: str,
) -> None:
    pages = StoredPdfPages(KnownFileContents({}), _COPYING_CONVERSION)

    with pytest.raises(HTTPException) as refusal:
        _ = pages.page_count_of(_stored_file(extension))

    assert refusal.value.status_code == _NOT_FOUND


@settings(max_examples=25, deadline=None)
@given(_CONVERTED_EXTENSIONS, st.binary(max_size=32))
def test__pdf_document_property_refuses_a_failed_conversion(
    extension: str, document: bytes
) -> None:
    file = _stored_file(extension)
    pages = StoredPdfPages(_contents_for(file, document), _FAILING_CONVERSION)

    with pytest.raises(HTTPException) as refusal:
        _ = pages.page_count_of(file)

    assert refusal.value.status_code == _BAD_REQUEST
    assert str(refusal.value.detail).startswith("Conversion failed: ")


@settings(max_examples=25, deadline=None)
@given(_PAGE_COUNTS)
def test_provide_stored_pdf_pages_property_counts_from_the_given_storage(
    page_count: int,
) -> None:
    file = _stored_file("pdf")

    with tempfile.TemporaryDirectory() as storage:
        stored_name = storage_name(str(file.id), file.extension)
        _ = (Path(storage) / stored_name).write_bytes(
            PdfDocuments.blank(page_count)
        )
        pages = provide_stored_pdf_pages(
            LocalDiskFileStorage(Path(storage)), _FAILING_CONVERSION
        )

        assert pages.page_count_of(file) == page_count
