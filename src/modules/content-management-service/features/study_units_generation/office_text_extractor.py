from pathlib import Path
from typing import override

from features.study_units_generation.pdf_text_extractor import (
    pdf_document_text,
)
from features.study_units_generation.text_extractor import TextExtractor
from shared.pdf_conversion import PdfConversion


class OfficeTextExtractor(TextExtractor):
    def __init__(self, pdf_conversion: PdfConversion) -> None:
        self._pdf_conversion: PdfConversion = pdf_conversion

    @override
    def extract_text(self, filename: str, extension: str) -> str:
        pdf_document = self._pdf_conversion.converted_file(
            Path(filename), extension
        )

        return pdf_document_text(pdf_document)
