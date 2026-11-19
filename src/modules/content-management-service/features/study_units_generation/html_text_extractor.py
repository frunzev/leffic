from pathlib import Path
from typing import override

from bs4 import BeautifulSoup

from features.study_units_generation.text_extractor import TextExtractor

_HTML_PARSER = "html.parser"
_LINE_SEPARATOR = "\n"


def html_document_text(markup: str | bytes) -> str:
    page = BeautifulSoup(markup, _HTML_PARSER)

    return page.get_text(separator=_LINE_SEPARATOR, strip=True)


class HtmlTextExtractor(TextExtractor):
    @override
    def extract_text(self, filename: str, extension: str) -> str:
        markup = Path(filename).read_bytes()

        return html_document_text(markup)
