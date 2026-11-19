import io
import tempfile
from pathlib import Path
from unittest import mock

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

from shared import local_disk_file_storage
from shared.local_disk_file_storage import (
    LocalDiskFileStorage,
    create_files_directory,
    provide_file_contents,
    provide_file_sizes,
    provide_file_storage,
)

_FILENAMES = st.text(alphabet="abcdef0123456789", min_size=3, max_size=10)
_CONTENT = st.binary(min_size=0, max_size=64)


@settings(max_examples=25, deadline=None)
@given(filename=_FILENAMES, content=_CONTENT)
def test_save_property_writes_exactly_the_bytes_it_is_given(
    filename: str, content: bytes
) -> None:
    with tempfile.TemporaryDirectory() as storage:
        disk_storage = LocalDiskFileStorage(Path(storage))
        disk_storage.save(io.BytesIO(content), filename)

        assert (Path(storage) / filename).read_bytes() == content


@settings(max_examples=25, deadline=None)
@given(filename=_FILENAMES, content=_CONTENT)
def test_save_property_never_creates_the_directory(
    filename: str, content: bytes
) -> None:
    with tempfile.TemporaryDirectory() as storage:
        absent = Path(storage) / "files"
        disk_storage = LocalDiskFileStorage(absent)

        with pytest.raises(FileNotFoundError):
            disk_storage.save(io.BytesIO(content), filename)

        assert not absent.exists()


@settings(max_examples=25, deadline=None)
@given(filename=_FILENAMES, is_stored_first=st.booleans())
def test_delete_property_is_safe_to_repeat(
    *, filename: str, is_stored_first: bool
) -> None:
    with tempfile.TemporaryDirectory() as storage:
        stored = Path(storage) / filename

        if is_stored_first:
            _ = stored.write_bytes(b"content")

        disk_storage = LocalDiskFileStorage(Path(storage))
        disk_storage.delete(filename)
        disk_storage.delete(filename)

        assert not stored.exists()


@settings(max_examples=25, deadline=None)
@given(deleted_name=_FILENAMES, kept_name=_FILENAMES)
def test_delete_property_spares_every_other_file(
    deleted_name: str, kept_name: str
) -> None:
    with tempfile.TemporaryDirectory() as storage:
        kept = Path(storage) / f"kept-{kept_name}"
        _ = kept.write_bytes(b"content")

        LocalDiskFileStorage(Path(storage)).delete(deleted_name)

        assert kept.exists()


@settings(max_examples=25, deadline=None)
@given(filename=_FILENAMES, content=_CONTENT)
def test_provide_file_storage_property_stores_in_the_files_directory(
    filename: str, content: bytes
) -> None:
    with tempfile.TemporaryDirectory() as storage, mock.patch.object(
        local_disk_file_storage, "_FILES_DIRECTORY", storage
    ):
        provide_file_storage().save(io.BytesIO(content), filename)

        assert (Path(storage) / filename).read_bytes() == content


@settings(max_examples=10, deadline=None)
@given(st.integers(min_value=1, max_value=3))
def test_create_files_directory_property_is_safe_to_repeat(runs: int) -> None:
    with tempfile.TemporaryDirectory() as root:
        files_directory = Path(root) / "files"

        with mock.patch.object(
            local_disk_file_storage, "_FILES_DIRECTORY", str(files_directory)
        ):
            for _ in range(runs):
                create_files_directory()

        assert files_directory.is_dir()
        assert list(files_directory.iterdir()) == []


@settings(max_examples=25, deadline=None)
@given(filename=_FILENAMES, content=_CONTENT)
def test_size_of_property_reads_the_stored_byte_count(
    filename: str, content: bytes
) -> None:
    with tempfile.TemporaryDirectory() as storage:
        disk_storage = LocalDiskFileStorage(Path(storage))
        disk_storage.save(io.BytesIO(content), filename)

        assert disk_storage.size_of(filename) == len(content)


@settings(max_examples=25, deadline=None)
@given(filename=_FILENAMES)
def test_size_of_property_reports_a_missing_file_as_no_size(
    filename: str,
) -> None:
    with tempfile.TemporaryDirectory() as storage:
        disk_storage = LocalDiskFileStorage(Path(storage))

        assert disk_storage.size_of(filename) is None


@settings(max_examples=25, deadline=None)
@given(filename=_FILENAMES, content=_CONTENT)
def test_provide_file_sizes_property_measures_the_files_directory(
    filename: str, content: bytes
) -> None:
    with tempfile.TemporaryDirectory() as storage, mock.patch.object(
        local_disk_file_storage, "_FILES_DIRECTORY", storage
    ):
        _ = (Path(storage) / filename).write_bytes(content)

        assert provide_file_sizes().size_of(filename) == len(content)


@settings(max_examples=25, deadline=None)
@given(filename=_FILENAMES, content=_CONTENT)
def test_contents_of_property_reads_back_the_saved_bytes(
    filename: str, content: bytes
) -> None:
    with tempfile.TemporaryDirectory() as storage:
        disk_storage = LocalDiskFileStorage(Path(storage))
        disk_storage.save(io.BytesIO(content), filename)

        assert disk_storage.contents_of(filename) == content


@settings(max_examples=25, deadline=None)
@given(filename=_FILENAMES)
def test_contents_of_property_refuses_a_missing_file(filename: str) -> None:
    with tempfile.TemporaryDirectory() as storage:
        disk_storage = LocalDiskFileStorage(Path(storage))

        with pytest.raises(FileNotFoundError):
            _ = disk_storage.contents_of(filename)


@settings(max_examples=25, deadline=None)
@given(filename=_FILENAMES, content=_CONTENT)
def test_provide_file_contents_property_reads_the_files_directory(
    filename: str, content: bytes
) -> None:
    with tempfile.TemporaryDirectory() as storage, mock.patch.object(
        local_disk_file_storage, "_FILES_DIRECTORY", storage
    ):
        _ = (Path(storage) / filename).write_bytes(content)

        assert provide_file_contents().contents_of(filename) == content
