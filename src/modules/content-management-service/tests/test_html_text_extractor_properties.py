from hypothesis import given, settings

from features.study_units_generation.html_text_extractor import (
    HtmlTextExtractor,
    html_document_text,
)
from tests.extracted_text_support import (
    LINE_SEPARATOR,
    WHITESPACE_PADDING,
    WORD_SEQUENCES,
    page_of_paragraphs,
    text_extracted_from_stored_file,
)


@settings(max_examples=50)
@given(WORD_SEQUENCES, WHITESPACE_PADDING)
def test_html_document_text_property_puts_every_paragraph_on_its_own_line(
    paragraph_words: list[str], padding: str
) -> None:
    markup = page_of_paragraphs(paragraph_words, padding)

    extracted = html_document_text(markup)

    assert extracted == LINE_SEPARATOR.join(paragraph_words)


@settings(max_examples=50)
@given(WORD_SEQUENCES, WHITESPACE_PADDING)
def test_html_document_text_property_leaves_no_markup_behind(
    paragraph_words: list[str], padding: str
) -> None:
    markup = page_of_paragraphs(paragraph_words, padding)

    extracted = html_document_text(markup.encode())

    assert "<" not in extracted
    assert ">" not in extracted


@settings(max_examples=25, deadline=None)
@given(WORD_SEQUENCES, WHITESPACE_PADDING)
def test_extract_text_property_html_reads_the_page_at_the_path(
    paragraph_words: list[str], padding: str
) -> None:
    markup = page_of_paragraphs(paragraph_words, padding)

    extracted = text_extracted_from_stored_file(
        HtmlTextExtractor(), markup.encode(), "html"
    )

    assert extracted == LINE_SEPARATOR.join(paragraph_words)
