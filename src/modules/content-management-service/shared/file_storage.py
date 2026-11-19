from typing import BinaryIO, Protocol


class FileStorage(Protocol):
    def save(self, content: BinaryIO, stored_name: str) -> None: ...

    def delete(self, stored_name: str) -> None: ...


class FileSizes(Protocol):
    def size_of(self, stored_name: str) -> int | None: ...


class FileContents(Protocol):
    def contents_of(self, stored_name: str) -> bytes: ...


def storage_name(file_id: str, extension: str) -> str:
    if not extension:
        return file_id

    return f"{file_id}.{extension}"
