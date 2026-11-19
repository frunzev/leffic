import shutil
from pathlib import Path
from typing import BinaryIO

from shared.file_storage import FileContents, FileSizes, FileStorage

_FILES_DIRECTORY = "files"


class LocalDiskFileStorage:
    def __init__(self, files_directory: Path) -> None:
        self._files_directory: Path = files_directory

    def save(self, content: BinaryIO, stored_name: str) -> None:
        file_path = self._files_directory / stored_name

        with file_path.open("wb") as stored_file:
            shutil.copyfileobj(content, stored_file)

    def delete(self, stored_name: str) -> None:
        file_path = self._files_directory / stored_name

        if file_path.exists():
            file_path.unlink()

    def size_of(self, stored_name: str) -> int | None:
        file_path = self._files_directory / stored_name

        try:
            file_status = file_path.stat()
        except FileNotFoundError:
            return None

        return file_status.st_size

    def contents_of(self, stored_name: str) -> bytes:
        file_path = self._files_directory / stored_name

        return file_path.read_bytes()


def create_files_directory() -> None:
    Path(_FILES_DIRECTORY).mkdir(exist_ok=True)


def provide_file_storage() -> FileStorage:
    return LocalDiskFileStorage(Path(_FILES_DIRECTORY))


def provide_file_sizes() -> FileSizes:
    return LocalDiskFileStorage(Path(_FILES_DIRECTORY))


def provide_file_contents() -> FileContents:
    return LocalDiskFileStorage(Path(_FILES_DIRECTORY))
