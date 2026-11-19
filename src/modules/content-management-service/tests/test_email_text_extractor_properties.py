import string
from email.message import EmailMessage

from hypothesis import given, settings
from hypothesis import strategies as st

from features.study_units_generation.email_text_extractor import (
    EmailTextExtractor,
)
from tests.extracted_text_support import (
    LINE_SEPARATOR,
    WHITESPACE_PADDING,
    WORD_SEQUENCES,
    page_of_paragraphs,
    text_extracted_from_stored_file,
)

_PLAIN_BODIES = st.text(
    alphabet=string.ascii_letters + string.digits + " \n", max_size=120
)
_HTML_SUBTYPE = "html"
_ATTACHMENT_NAME = "scan.bin"


def _plain_email_with_html_alternative(
    plain_body: str, markup: str
) -> bytes:
    message = EmailMessage()
    message.set_content(plain_body)
    message.add_alternative(markup, subtype=_HTML_SUBTYPE)

    return message.as_bytes()


def _html_email(markup: str) -> bytes:
    message = EmailMessage()
    message.set_content(markup, subtype=_HTML_SUBTYPE)

    return message.as_bytes()


def _attachment_email(attachment: bytes) -> bytes:
    message = EmailMessage()
    message.add_attachment(
        attachment,
        maintype="application",
        subtype="octet-stream",
        filename=_ATTACHMENT_NAME,
    )

    return message.as_bytes()


def _extracted(email: bytes) -> str:
    return text_extracted_from_stored_file(
        EmailTextExtractor(), email, "eml"
    )


@settings(max_examples=50, deadline=None)
@given(_PLAIN_BODIES, WORD_SEQUENCES, WHITESPACE_PADDING)
def test_extract_text_property_email_prefers_the_plain_body(
    plain_body: str, paragraph_words: list[str], padding: str
) -> None:
    markup = page_of_paragraphs(paragraph_words, padding)
    email = _plain_email_with_html_alternative(plain_body, markup)

    assert _extracted(email) == plain_body.strip()


@settings(max_examples=50, deadline=None)
@given(WORD_SEQUENCES, WHITESPACE_PADDING)
def test_extract_text_property_email_falls_back_to_the_html_body(
    paragraph_words: list[str], padding: str
) -> None:
    markup = page_of_paragraphs(paragraph_words, padding)
    email = _html_email(markup)

    assert _extracted(email) == LINE_SEPARATOR.join(paragraph_words)


@settings(max_examples=25, deadline=None)
@given(st.binary(max_size=64))
def test_extract_text_property_email_without_a_text_body_is_empty(
    attachment: bytes,
) -> None:
    email = _attachment_email(attachment)

    assert _extracted(email) == ""
