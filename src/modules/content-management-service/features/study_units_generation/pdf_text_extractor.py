import io
from pathlib import Path
from typing import override

from pypdf import PdfReader

from features.study_units_generation.text_extractor import TextExtractor

_PAGE_SEPARATOR = "\n"


def pdf_document_text(pdf_document: bytes) -> str:
    reader = PdfReader(io.BytesIO(pdf_document))
    page_texts: list[str] = []

    for page in reader.pages:
        page_texts.append(page.extract_text())

    document_text = _PAGE_SEPARATOR.join(page_texts)

    return document_text.strip()


class PdfTextExtractor(TextExtractor):
    @override
    def extract_text(self, filename: str, extension: str) -> str:
        pdf_document = Path(filename).read_bytes()

        return pdf_document_text(pdf_document)
