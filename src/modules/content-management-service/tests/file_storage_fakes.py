from collections.abc import Generator
from contextlib import contextmanager
from pathlib import Path
from typing import BinaryIO, cast, final

from fastapi import FastAPI
from fastapi.testclient import TestClient

from shared.file_storage import FileStorage
from shared.local_disk_file_storage import (
    LocalDiskFileStorage,
    provide_file_storage,
)
from shared.models import File


@final
class RecordingFileStorage:
    def __init__(self) -> None:
        self.saved: dict[str, bytes] = {}
        self.deleted: list[str] = []

    def save(self, content: BinaryIO, stored_name: str) -> None:
        self.saved[stored_name] = content.read()

    def delete(self, stored_name: str) -> None:
        self.deleted.append(stored_name)


@final
class FailingFileStorage:
    def __init__(
        self, files_directory: Path, failing_index: int, failure_message: str
    ) -> None:
        self.disk_storage: LocalDiskFileStorage = LocalDiskFileStorage(
            files_directory
        )
        self.failing_index: int = failing_index
        self.failure_message: str = failure_message
        self.save_calls: int = 0

    def save(self, content: BinaryIO, stored_name: str) -> None:
        current_call = self.save_calls
        self.save_calls += 1

        if current_call == self.failing_index:
            raise RuntimeError(self.failure_message)

        self.disk_storage.save(content, stored_name)

    def delete(self, stored_name: str) -> None:
        self.disk_storage.delete(stored_name)


@contextmanager
def injected_file_storage(
    client: TestClient, file_storage: FileStorage
) -> Generator[None]:
    application = cast("FastAPI", client.app)
    overrides = application.dependency_overrides
    overrides[provide_file_storage] = lambda: file_storage

    try:
        yield
    finally:
        del overrides[provide_file_storage]


@final
class KnownFileSizes:
    def __init__(self, sizes: dict[str, int]) -> None:
        self.sizes: dict[str, int] = sizes

    def size_of(self, stored_name: str) -> int | None:
        return self.sizes.get(stored_name)


@final
class KnownFileContents:
    def __init__(self, contents: dict[str, bytes]) -> None:
        self.contents: dict[str, bytes] = contents

    def contents_of(self, stored_name: str) -> bytes:
        if stored_name not in self.contents:
            raise FileNotFoundError(stored_name)

        return self.contents[stored_name]


@final
class FixedPdfPages:
    def __init__(self, page_count: int) -> None:
        self.page_count: int = page_count
        self.counted_file_ids: list[str] = []

    def page_count_of(self, file: File) -> int:
        self.counted_file_ids.append(str(file.id))

        return self.page_count

