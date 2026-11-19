from hypothesis import given, settings
from hypothesis import strategies as st

from features.study_units_generation.plain_text_extractor import (
    PlainTextExtractor,
)
from features.study_units_generation.text_extractor import (
    TextExtractorFactory,
)
from features.study_units_generation.text_extractor_registry import (
    text_extractor_factory,
)
from tests.extracted_text_support import (
    WHITESPACE_PADDING,
    text_extracted_from_stored_file,
)

_KNOWN_EXTENSIONS = st.sampled_from(["pdf", "docx", "txt", "png"])
_SPELLINGS = {
    "upper": str.upper,
    "lower": str.lower,
    "title": str.title,
}


def _extracted_plain_text(document: bytes) -> str:
    return text_extracted_from_stored_file(
        PlainTextExtractor(), document, "txt"
    )


@settings(max_examples=50)
@given(_KNOWN_EXTENSIONS, st.sampled_from(["upper", "lower", "title"]))
def test_get_text_extractor_property_ignores_the_spelling_of_the_case(
    extension: str, spelling: str
) -> None:
    spelled = _SPELLINGS[spelling](extension)
    found = text_extractor_factory.get_text_extractor(spelled)

    assert found is text_extractor_factory.get_text_extractor(extension)
    assert found is not None


@settings(max_examples=50)
@given(st.text(alphabet="abcdef", min_size=1, max_size=6))
def test_register_extractor_property_hands_back_what_was_registered(
    extension: str,
) -> None:
    factory = TextExtractorFactory()
    registered = PlainTextExtractor()

    assert factory.get_text_extractor(extension) is None

    factory.register_extractor(extension.upper(), registered)

    assert factory.get_text_extractor(extension) is registered


@settings(max_examples=50, deadline=None)
@given(st.text(max_size=40), WHITESPACE_PADDING, WHITESPACE_PADDING)
def test_extract_text_property_returns_the_document_without_its_padding(
    body: str, before: str, after: str
) -> None:
    padded = f"{before}{body}{after}".encode()

    extracted = _extracted_plain_text(padded)

    assert extracted == padded.decode("utf-8", errors="ignore").strip()
    assert extracted == body.strip()


@settings(max_examples=50, deadline=None)
@given(st.binary(max_size=64))
def test_extract_text_property_plain_text_skips_bytes_that_are_not_utf8(
    document: bytes,
) -> None:
    extracted = _extracted_plain_text(document)

    assert extracted == document.decode("utf-8", errors="ignore").strip()


@settings(max_examples=25)
@given(st.integers(min_value=1, max_value=3))
def test___init___property_starts_a_factory_with_nothing_registered(
    count: int,
) -> None:
    factories = [TextExtractorFactory() for _ in range(count)]

    assert all(
        factory.get_text_extractor("pdf") is None for factory in factories
    )
