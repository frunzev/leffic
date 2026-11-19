import inspect
import tempfile
from pathlib import Path
from unittest import mock

from features.study_units_generation import (
    extraction_router,
    text_sources,
)
from features.study_units_generation.pdf_text_extractor import (
    PdfTextExtractor,
)
from features.study_units_generation.plain_text_extractor import (
    PlainTextExtractor,
)
from features.study_units_generation.text_extractor import (
    TextExtractorFactory,
)
from features.study_units_generation.text_extractor_registry import (
    text_extractor_factory,
)
from features.study_units_generation.text_sources import (
    StoredDocument,
    get_file_from_storage,
    provide_stored_document_text,
)
from tests.pdf_support import PdfDocuments
from tests.text_extractor_fakes import (
    RecordingTextExtractor,
    extraction_recorded_by,
)

_FILE_ID = "3f6c2b1a"
_OTHER_FILE_ID = "9a1d4c7b"
_PDF = StoredDocument(storage_name=f"{_FILE_ID}.pdf", extension="pdf")
_STORAGE_CONSTANT = '_FILES_DIRECTORY = "files"'
_STORED_DOCUMENT_TEXT = provide_stored_document_text()


def test_the_factory_knows_the_registered_extensions() -> None:
    assert isinstance(
        text_extractor_factory.get_text_extractor("pdf"), PdfTextExtractor
    )


def test_the_factory_is_case_insensitive() -> None:
    assert text_extractor_factory.get_text_extractor("PDF") is not None


def test_the_factory_returns_nothing_for_an_unknown_extension() -> None:
    assert text_extractor_factory.get_text_extractor("xyz") is None


def test_a_registered_extractor_is_returned() -> None:
    factory = TextExtractorFactory()
    extractor = PlainTextExtractor()
    factory.register_extractor("md", extractor)

    assert factory.get_text_extractor("md") is extractor


def test_the_extractor_decodes_and_strips_the_document(
    tmp_path: Path,
) -> None:
    stored = tmp_path / "stored.txt"
    _ = stored.write_bytes(b"  hello world  ")

    text = PlainTextExtractor().extract_text(str(stored), "txt")

    assert text == "hello world"


def test_reads_a_stored_file(tmp_path: Path) -> None:
    stored = tmp_path / "stored.bin"
    _ = stored.write_bytes(b"payload")

    with mock.patch.object(text_sources, "_FILES_DIRECTORY", str(tmp_path)):
        assert get_file_from_storage("stored.bin") == b"payload"


def test_text_from_files_reads_the_given_storage_name() -> None:
    document = StoredDocument(
        storage_name="a-name-nobody-would-build", extension="pdf"
    )

    with (
        mock.patch.object(
            text_sources, "get_file_from_storage", return_value=b""
        ) as reader,
        extraction_recorded_by(RecordingTextExtractor()),
    ):
        _ = _STORED_DOCUMENT_TEXT.text_from_files([document])

    assert reader.call_args.args[0] == "a-name-nobody-would-build"


def test_text_sources_has_no_database_import() -> None:
    source = inspect.getsource(text_sources)

    assert "sqlalchemy" not in source
    assert "shared.models" not in source


def test_reads_stay_in_one_place() -> None:
    router_source = inspect.getsource(extraction_router)

    assert "Path(" not in router_source
    assert "_FILES_DIRECTORY" not in router_source
    assert inspect.getsource(text_sources).count(_STORAGE_CONSTANT) == 1


def test_text_from_files_joins_every_document(tmp_path: Path) -> None:
    first = PdfDocuments.with_text(["payload"])
    _ = (tmp_path / f"{_FILE_ID}.pdf").write_bytes(first)
    other = StoredDocument(
        storage_name=f"{_OTHER_FILE_ID}.pdf", extension="pdf"
    )
    second = PdfDocuments.with_text(["second"])
    _ = (tmp_path / f"{_OTHER_FILE_ID}.pdf").write_bytes(second)

    with mock.patch.object(text_sources, "_FILES_DIRECTORY", str(tmp_path)):
        joined = _STORED_DOCUMENT_TEXT.text_from_files([_PDF, other])

    assert joined == "payload\nsecond\n"


def test_the_document_is_written_where_the_extractor_can_read_it(
    tmp_path: Path,
) -> None:
    _ = (tmp_path / f"{_FILE_ID}.pdf").write_bytes(b"payload")
    recorder = RecordingTextExtractor()

    with (
        mock.patch.object(text_sources, "_FILES_DIRECTORY", str(tmp_path)),
        extraction_recorded_by(recorder),
    ):
        _ = _STORED_DOCUMENT_TEXT.text_from_files([_PDF])

    assert recorder.filenames[0].startswith(tempfile.gettempdir())
    assert recorder.filenames[0].endswith(_PDF.storage_name)
    assert not Path(recorder.filenames[0]).exists()
    assert recorder.documents == [b"payload"]
    assert recorder.extensions == ["pdf"]


def test_text_from_files_skips_unknown_extensions(tmp_path: Path) -> None:
    unknown = StoredDocument(storage_name=f"{_FILE_ID}.xyz", extension="xyz")
    _ = (tmp_path / f"{_FILE_ID}.xyz").write_bytes(b"payload")

    with mock.patch.object(text_sources, "_FILES_DIRECTORY", str(tmp_path)):
        assert _STORED_DOCUMENT_TEXT.text_from_files([unknown]) == ""


def test_text_from_files_skips_documents_with_no_text(
    tmp_path: Path,
) -> None:
    blank_text = PdfDocuments.with_text(["   "])
    _ = (tmp_path / f"{_FILE_ID}.pdf").write_bytes(blank_text)

    with mock.patch.object(text_sources, "_FILES_DIRECTORY", str(tmp_path)):
        assert _STORED_DOCUMENT_TEXT.text_from_files([_PDF]) == ""


def test_extraction_needs_no_pre_created_directory(tmp_path: Path) -> None:
    document = PdfDocuments.with_text(["payload"])
    _ = (tmp_path / f"{_FILE_ID}.pdf").write_bytes(document)

    with mock.patch.object(text_sources, "_FILES_DIRECTORY", str(tmp_path)):
        extracted = _STORED_DOCUMENT_TEXT.text_from_files([_PDF])

    assert extracted == "payload\n"
