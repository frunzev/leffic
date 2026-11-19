from collections.abc import Generator
from contextlib import contextmanager
from pathlib import Path
from typing import override
from unittest import mock

from features.study_units_generation.text_extractor import TextExtractor
from features.study_units_generation.text_extractor_registry import (
    text_extractor_factory,
)


class RecordingTextExtractor(TextExtractor):
    def __init__(self) -> None:
        self.filenames: list[str] = []
        self.extensions: list[str] = []
        self.documents: list[bytes] = []

    @override
    def extract_text(self, filename: str, extension: str) -> str:
        self.filenames.append(filename)
        self.extensions.append(extension)
        self.documents.append(Path(filename).read_bytes())

        return ""


@contextmanager
def extraction_recorded_by(
    recorder: RecordingTextExtractor,
) -> Generator[None]:
    with mock.patch.object(
        text_extractor_factory, "get_text_extractor", return_value=recorder
    ):
        yield
