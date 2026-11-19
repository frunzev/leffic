import string
import tempfile
from pathlib import Path

from hypothesis import strategies as st

from features.study_units_generation.text_extractor import TextExtractor

WORDS = st.text(
    alphabet=string.ascii_letters + string.digits, min_size=1, max_size=12
)
WORD_SEQUENCES = st.lists(WORDS, min_size=1, max_size=5)
WHITESPACE_PADDING = st.sampled_from(["", " ", "\n", "  \t\n"])
LINE_SEPARATOR = "\n"

_STORED_STEM = "stored"


def page_of_paragraphs(paragraph_words: list[str], padding: str) -> str:
    paragraphs = ""

    for word in paragraph_words:
        paragraphs += f"{padding}<p>{padding}{word}{padding}</p>{padding}"

    return f"<html><body><div>{paragraphs}</div></body></html>"


def text_extracted_from_stored_file(
    extractor: TextExtractor, document: bytes, extension: str
) -> str:
    with tempfile.TemporaryDirectory() as directory:
        stored = Path(directory) / f"{_STORED_STEM}.{extension}"
        _ = stored.write_bytes(document)

        return extractor.extract_text(str(stored), extension)
