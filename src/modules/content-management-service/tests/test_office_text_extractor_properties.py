from unittest import mock

from hypothesis import given, settings
from hypothesis import strategies as st

from features.study_units_generation.office_text_extractor import (
    OfficeTextExtractor,
)
from shared.libreoffice_exporter import provide_pdf_conversion
from shared.pdf_conversion import PdfConversion
from tests.extracted_text_support import (
    LINE_SEPARATOR,
    WORD_SEQUENCES,
    text_extracted_from_stored_file,
)
from tests.pdf_support import CopyingExporter, LibreOfficeStub, PdfDocuments

_OFFICE_EXTENSIONS = st.sampled_from(
    ["doc", "docx", "odt", "rtf", "ppt", "pptx", "odp", "xls", "xlsx"]
)
_PAGE_COUNTS = st.integers(min_value=1, max_value=4)
_SUBPROCESS_RUN = "shared.libreoffice_exporter.subprocess.run"
_OFFICE_PAYLOAD = b"office payload"


@settings(max_examples=25, deadline=None)
@given(WORD_SEQUENCES, _OFFICE_EXTENSIONS)
def test_extract_text_property_office_reads_the_text_of_the_converted_pdf(
    page_texts: list[str], extension: str
) -> None:
    extractor = OfficeTextExtractor(PdfConversion(CopyingExporter()))
    converted_document = PdfDocuments.with_text(page_texts)

    extracted = text_extracted_from_stored_file(
        extractor, converted_document, extension
    )

    assert extracted == LINE_SEPARATOR.join(page_texts)


@settings(max_examples=25, deadline=None)
@given(_OFFICE_EXTENSIONS, _PAGE_COUNTS)
def test_extract_text_property_office_converts_through_libreoffice(
    extension: str, page_count: int
) -> None:
    libreoffice = LibreOfficeStub(page_count)
    extractor = OfficeTextExtractor(provide_pdf_conversion())

    with mock.patch(_SUBPROCESS_RUN, libreoffice):
        extracted = text_extracted_from_stored_file(
            extractor, _OFFICE_PAYLOAD, extension
        )

    assert libreoffice.converted_sources == [f"document.{extension}"]
    assert extracted == ""
