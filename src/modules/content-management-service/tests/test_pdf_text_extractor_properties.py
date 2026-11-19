from hypothesis import given, settings
from hypothesis import strategies as st

from features.study_units_generation.pdf_text_extractor import (
    PdfTextExtractor,
    pdf_document_text,
)
from tests.extracted_text_support import (
    LINE_SEPARATOR,
    WORD_SEQUENCES,
    WORDS,
    text_extracted_from_stored_file,
)
from tests.pdf_support import PdfDocuments

_SPACE_PADDING = st.sampled_from(["", " ", "  "])


@settings(max_examples=25, deadline=None)
@given(WORD_SEQUENCES)
def test_pdf_document_text_property_reads_every_page_in_order(
    page_texts: list[str],
) -> None:
    document = PdfDocuments.with_text(page_texts)

    extracted = pdf_document_text(document)

    assert extracted == LINE_SEPARATOR.join(page_texts)


@settings(max_examples=25, deadline=None)
@given(WORDS, _SPACE_PADDING, _SPACE_PADDING)
def test_pdf_document_text_property_strips_the_padding_around_the_text(
    word: str, before: str, after: str
) -> None:
    document = PdfDocuments.with_text([f"{before}{word}{after}"])

    assert pdf_document_text(document) == word


@settings(max_examples=10, deadline=None)
@given(st.integers(min_value=1, max_value=5))
def test_pdf_document_text_property_finds_nothing_on_blank_pages(
    page_count: int,
) -> None:
    assert pdf_document_text(PdfDocuments.blank(page_count)) == ""


@settings(max_examples=25, deadline=None)
@given(WORD_SEQUENCES)
def test_extract_text_property_pdf_reads_the_document_at_the_path(
    page_texts: list[str],
) -> None:
    document = PdfDocuments.with_text(page_texts)

    extracted = text_extracted_from_stored_file(
        PdfTextExtractor(), document, "pdf"
    )

    assert extracted == LINE_SEPARATOR.join(page_texts)
