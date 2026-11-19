from email import policy
from email.parser import BytesParser
from pathlib import Path
from typing import cast, override

from features.study_units_generation.html_text_extractor import (
    html_document_text,
)
from features.study_units_generation.text_extractor import TextExtractor

_PLAIN_BODY = ("plain",)
_HTML_BODY = ("html",)


class EmailTextExtractor(TextExtractor):
    @override
    def extract_text(self, filename: str, extension: str) -> str:
        email = Path(filename).read_bytes()
        message = BytesParser(policy=policy.default).parsebytes(email)

        plain_body = message.get_body(preferencelist=_PLAIN_BODY)

        if plain_body is not None:
            plain_text = cast("str", plain_body.get_content())

            return plain_text.strip()

        html_body = message.get_body(preferencelist=_HTML_BODY)

        if html_body is None:
            return ""

        markup = cast("str", html_body.get_content())

        return html_document_text(markup)
