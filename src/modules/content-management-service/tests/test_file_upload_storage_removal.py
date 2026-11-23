import tempfile
from pathlib import Path

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

from features.file_upload import file_uploader as uploader_module
from shared.local_disk_file_storage import LocalDiskFileStorage
from tests.file_storage_fakes import RecordingFileStorage
from tests.file_upload_support import (
    EXTENSIONS,
    emptied,
    names_in,
    numbered_filenames,
    stored_uploads,
)
from tests.hostile_identifiers import SINGLE_SEGMENT_IDENTIFIERS

_PROPERTY_STORAGE = Path(tempfile.mkdtemp())


def _named_after(extensions: list[str]) -> tuple[str, ...]:
    return tuple(
        f"notes-{index}.{extension}"
        for index, extension in enumerate(extensions)
    )


def test__remove_uploaded_files_from_storage_deletes_every_name(
    tmp_path: Path,
) -> None:
    uploaded = stored_uploads(tmp_path, ("a.pdf", "b.docx", "c"))

    assert len(names_in(tmp_path)) == len(uploaded)

    disk_storage = LocalDiskFileStorage(tmp_path)

    uploader_module._remove_uploaded_files_from_storage(
        disk_storage, uploaded
    )

    assert names_in(tmp_path) == set()


def test__remove_uploaded_files_from_storage_uses_the_storage_port(
    tmp_path: Path,
) -> None:
    uploaded = stored_uploads(tmp_path, ("a.pdf", "b.docx"))
    written = names_in(tmp_path)

    recording_storage = RecordingFileStorage()

    uploader_module._remove_uploaded_files_from_storage(
        recording_storage, uploaded
    )

    assert set(recording_storage.deleted) == written


def test_removing_the_same_uploads_twice_raises_nothing(
    tmp_path: Path,
) -> None:
    uploaded = stored_uploads(tmp_path, ("a.pdf",))

    disk_storage = LocalDiskFileStorage(tmp_path)

    uploader_module._remove_uploaded_files_from_storage(
        disk_storage, uploaded
    )

    uploader_module._remove_uploaded_files_from_storage(
        disk_storage, uploaded
    )

    assert names_in(tmp_path) == set()


def test_removing_uploads_leaves_unrelated_files_alone(
    tmp_path: Path,
) -> None:
    keeper = tmp_path / "someone-elses.pdf"
    _ = keeper.write_bytes(b"payload")
    uploaded = stored_uploads(tmp_path, ("a.pdf",))

    disk_storage = LocalDiskFileStorage(tmp_path)

    uploader_module._remove_uploaded_files_from_storage(
        disk_storage, uploaded
    )

    assert names_in(tmp_path) == {keeper.name}


def test_removing_an_empty_upload_list_deletes_nothing(
    tmp_path: Path,
) -> None:
    keeper = tmp_path / "someone-elses.pdf"
    _ = keeper.write_bytes(b"payload")

    disk_storage = LocalDiskFileStorage(tmp_path)

    uploader_module._remove_uploaded_files_from_storage(
        disk_storage, []
    )

    assert names_in(tmp_path) == {keeper.name}


@pytest.mark.parametrize("hostile", SINGLE_SEGMENT_IDENTIFIERS)
def test_removing_a_hostile_upload_name_raises_nothing(
    tmp_path: Path, hostile: str
) -> None:
    uploaded = [
        {"file_id": hostile, "extension": hostile, "name": hostile}
    ]

    disk_storage = LocalDiskFileStorage(tmp_path)

    uploader_module._remove_uploaded_files_from_storage(
        disk_storage, uploaded
    )

    assert names_in(tmp_path) == set()


def test_removing_a_duplicated_upload_entry_raises_nothing(
    tmp_path: Path,
) -> None:
    uploaded = stored_uploads(tmp_path, ("a.pdf",))

    disk_storage = LocalDiskFileStorage(tmp_path)

    uploader_module._remove_uploaded_files_from_storage(
        disk_storage, [*uploaded, *uploaded]
    )

    assert names_in(tmp_path) == set()


def test_removing_a_long_upload_list_clears_every_file(
    tmp_path: Path,
) -> None:
    uploaded = stored_uploads(tmp_path, numbered_filenames(60, "pdf"))

    disk_storage = LocalDiskFileStorage(tmp_path)

    uploader_module._remove_uploaded_files_from_storage(
        disk_storage, uploaded
    )

    assert names_in(tmp_path) == set()


@settings(max_examples=25, deadline=None)
@given(st.lists(EXTENSIONS, min_size=0, max_size=5))
def test__remove_uploaded_files_from_storage_property_leaves_no_name_behind(
    extensions: list[str],
) -> None:
    directory = emptied(_PROPERTY_STORAGE)
    uploaded = stored_uploads(directory, _named_after(extensions))

    disk_storage = LocalDiskFileStorage(directory)

    uploader_module._remove_uploaded_files_from_storage(
        disk_storage, uploaded
    )

    uploader_module._remove_uploaded_files_from_storage(
        disk_storage, uploaded
    )

    assert names_in(directory) == set()


@settings(max_examples=25, deadline=None)
@given(st.lists(EXTENSIONS, min_size=1, max_size=4), EXTENSIONS)
def test__remove_uploaded_files_from_storage_property_spares_other_files(
    extensions: list[str], kept_extension: str
) -> None:
    directory = emptied(_PROPERTY_STORAGE)
    kept = directory / f"kept.{kept_extension}"
    _ = kept.write_bytes(b"payload")
    uploaded = stored_uploads(directory, _named_after(extensions))

    disk_storage = LocalDiskFileStorage(directory)

    uploader_module._remove_uploaded_files_from_storage(
        disk_storage, uploaded
    )

    assert names_in(directory) == {kept.name}
