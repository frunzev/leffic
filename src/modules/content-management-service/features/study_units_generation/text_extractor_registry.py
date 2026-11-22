import os

from features.study_units_generation.email_text_extractor import (
    EmailTextExtractor,
)
from features.study_units_generation.html_text_extractor import (
    HtmlTextExtractor,
)
from features.study_units_generation.image_text_extractor import (
    ImageTextExtractor,
)
from features.study_units_generation.office_text_extractor import (
    OfficeTextExtractor,
)
from features.study_units_generation.pdf_text_extractor import (
    PdfTextExtractor,
)
from features.study_units_generation.plain_text_extractor import (
    PlainTextExtractor,
)
from features.study_units_generation.text_extractor import (
    TextExtractor,
    TextExtractorFactory,
)
from shared.libreoffice_exporter import provide_pdf_conversion

TEXT_RECOGNIZER_BINARY = os.getenv("TEXT_RECOGNIZER_BINARY", "tesseract")

_PDF_EXTENSIONS = ("pdf",)
_PLAIN_TEXT_EXTENSIONS = ("txt", "csv", "json")
_HTML_EXTENSIONS = ("html", "htm")
_EMAIL_EXTENSIONS = ("eml",)
_IMAGE_EXTENSIONS = ("gif", "jpg", "jpeg", "png", "tiff", "tif")
_OFFICE_EXTENSIONS = (
    "doc", "docx", "odt", "rtf",
    "ppt", "pptx", "odp",
    "xls", "xlsx",
)

_EXTENSIONS_OF_EACH_EXTRACTOR: tuple[
    tuple[TextExtractor, tuple[str, ...]], ...
] = (
    (PdfTextExtractor(), _PDF_EXTENSIONS),
    (PlainTextExtractor(), _PLAIN_TEXT_EXTENSIONS),
    (HtmlTextExtractor(), _HTML_EXTENSIONS),
    (EmailTextExtractor(), _EMAIL_EXTENSIONS),
    (ImageTextExtractor(TEXT_RECOGNIZER_BINARY), _IMAGE_EXTENSIONS),
    (OfficeTextExtractor(provide_pdf_conversion()), _OFFICE_EXTENSIONS),
)

text_extractor_factory = TextExtractorFactory()

for _extractor, _extensions in _EXTENSIONS_OF_EACH_EXTRACTOR:
    for _extension in _extensions:
        text_extractor_factory.register_extractor(_extension, _extractor)
