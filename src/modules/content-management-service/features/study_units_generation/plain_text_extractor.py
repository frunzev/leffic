from pathlib import Path
from typing import override

from features.study_units_generation.text_extractor import TextExtractor

_ENCODING = "utf-8"
_SKIP_UNDECODABLE_BYTES = "ignore"


class PlainTextExtractor(TextExtractor):
    @override
    def extract_text(self, filename: str, extension: str) -> str:
        document = Path(filename).read_bytes()
        text = document.decode(_ENCODING, errors=_SKIP_UNDECODABLE_BYTES)

        return text.strip()
