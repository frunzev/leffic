from hypothesis import given, settings
from hypothesis import strategies as st

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
from features.study_units_generation.text_extractor import TextExtractor
from features.study_units_generation.text_extractor_registry import (
    text_extractor_factory,
)

_EXTRACTOR_KIND_BY_EXTENSION: dict[str, type[TextExtractor]] = {
    "pdf": PdfTextExtractor,
    "txt": PlainTextExtractor,
    "csv": PlainTextExtractor,
    "json": PlainTextExtractor,
    "html": HtmlTextExtractor,
    "htm": HtmlTextExtractor,
    "eml": EmailTextExtractor,
    "gif": ImageTextExtractor,
    "jpg": ImageTextExtractor,
    "jpeg": ImageTextExtractor,
    "png": ImageTextExtractor,
    "tiff": ImageTextExtractor,
    "tif": ImageTextExtractor,
    "doc": OfficeTextExtractor,
    "docx": OfficeTextExtractor,
    "odt": OfficeTextExtractor,
    "rtf": OfficeTextExtractor,
    "ppt": OfficeTextExtractor,
    "pptx": OfficeTextExtractor,
    "odp": OfficeTextExtractor,
    "xls": OfficeTextExtractor,
    "xlsx": OfficeTextExtractor,
}
_DROPPED_EXTENSIONS = ("mp3", "ogg", "wav", "msg", "epub", "ps")


@settings(max_examples=50)
@given(st.sampled_from(sorted(_EXTRACTOR_KIND_BY_EXTENSION)))
def test_get_text_extractor_property_reads_each_extension_with_its_kind(
    extension: str,
) -> None:
    expected_kind = _EXTRACTOR_KIND_BY_EXTENSION[extension]

    found = text_extractor_factory.get_text_extractor(extension)

    assert isinstance(found, expected_kind)


@settings(max_examples=25)
@given(st.sampled_from(_DROPPED_EXTENSIONS))
def test_get_text_extractor_property_reads_no_dropped_format(
    extension: str,
) -> None:
    assert text_extractor_factory.get_text_extractor(extension) is None
