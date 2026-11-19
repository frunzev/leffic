import uuid
from collections.abc import Sequence
from typing import NamedTuple

from sqlalchemy.orm import Session

from features.file_system.child_summaries import (
    ChildSummary,
    child_summaries,
)
from features.file_system.reading_time import reading_minutes
from features.file_system.review_counts import (
    NOTHING_TO_REVIEW,
    ReviewCounts,
    assessment_review_counts,
    deck_review_counts,
)
from shared.file_storage import FileSizes, storage_name
from shared.generated_source import source_fields
from shared.models import (
    File,
    FlashcardDeck,
    Folder,
    Note,
    Test,
)
from shared.models.mixins import FolderContent, GeneratedContent, NamedRecord

ContentEntry = dict[str, str | int | None]


class ReviewedKind(NamedTuple):
    entry_type: str
    total_field: str


_DECKS = ReviewedKind(entry_type="flashcard_deck", total_field="card_count")
_TESTS = ReviewedKind(entry_type="test", total_field="question_count")
_EMPTY_FOLDER_SIZE = 0


def entries_in(
    db: Session, folder_id: str, user_id: str, file_sizes: FileSizes
) -> list[ContentEntry]:
    owner_id = uuid.UUID(user_id)
    decks = _rows_in_folder(db, FlashcardDeck, folder_id, owner_id)
    tests = _rows_in_folder(db, Test, folder_id, owner_id)
    files = _rows_in_folder(db, File, folder_id, owner_id)
    notes = _rows_in_folder(db, Note, folder_id, owner_id)

    deck_counts = deck_review_counts(db, folder_id)
    test_counts = assessment_review_counts(db, folder_id)

    return [
        *_subfolders(db, folder_id, owner_id),
        *_reviewed_entries(decks, _DECKS, deck_counts),
        *_reviewed_entries(tests, _TESTS, test_counts),
        *_files(files, file_sizes),
        *_notes(notes),
    ]


def _record_fields(row: NamedRecord) -> ContentEntry:
    return {
        "id": str(row.id),
        "name": row.name,
        "created_at": str(row.created_at),
    }


def _subfolders(
    db: Session, folder_id: str, owner_id: uuid.UUID
) -> list[ContentEntry]:
    rows = (
        db.query(Folder)
        .filter(Folder.parent_id == folder_id, Folder.user_id == owner_id)
        .all()
    )
    summaries = child_summaries(db, folder_id)

    entries: list[ContentEntry] = []

    for row in rows:
        empty_folder = ChildSummary(
            item_count=_EMPTY_FOLDER_SIZE, newest_created_at=row.created_at
        )
        summary = summaries.get(row.id, empty_folder)
        entries.append(_folder_entry(row, summary))

    return entries


def _folder_entry(row: Folder, summary: ChildSummary) -> ContentEntry:
    edited_at = max(row.created_at, summary.newest_created_at)

    return {
        **_record_fields(row),
        "type": "folder",
        "item_count": summary.item_count,
        "edited_at": str(edited_at),
    }


def _rows_in_folder[ContentT: FolderContent](
    db: Session,
    model: type[ContentT],
    folder_id: str,
    owner_id: uuid.UUID,
) -> list[ContentT]:
    return (
        db.query(model)
        .join(Folder)
        .filter(Folder.id == folder_id, Folder.user_id == owner_id)
        .all()
    )


def _generated_entry(
    row: GeneratedContent, entry_type: str, details: ContentEntry
) -> ContentEntry:
    return {
        **_record_fields(row),
        "type": entry_type,
        **details,
        **source_fields(row),
    }


def _reviewed_entries(
    rows: Sequence[GeneratedContent],
    kind: ReviewedKind,
    counts: dict[uuid.UUID, ReviewCounts],
) -> list[ContentEntry]:
    entries: list[ContentEntry] = []

    for row in rows:
        unit_counts = counts.get(row.id, NOTHING_TO_REVIEW)
        details: ContentEntry = {
            kind.total_field: unit_counts.total,
            "due_count": unit_counts.due,
        }
        entries.append(_generated_entry(row, kind.entry_type, details))

    return entries


def _notes(rows: Sequence[Note]) -> list[ContentEntry]:
    entries: list[ContentEntry] = []

    for row in rows:
        details: ContentEntry = {
            "reading_minutes": reading_minutes(row.content)
        }
        entries.append(_generated_entry(row, "note", details))

    return entries


def _files(rows: Sequence[File], file_sizes: FileSizes) -> list[ContentEntry]:
    entries: list[ContentEntry] = []

    for row in rows:
        stored_name = storage_name(str(row.id), row.extension)
        entries.append(
            {
                **_record_fields(row),
                "extension": row.extension,
                "type": "file",
                "size_bytes": file_sizes.size_of(stored_name),
            }
        )

    return entries
