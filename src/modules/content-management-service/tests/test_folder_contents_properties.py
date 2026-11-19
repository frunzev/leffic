import uuid
from datetime import datetime

from hypothesis import given, settings
from hypothesis import strategies as st

from features.file_system.child_summaries import ChildSummary
from features.file_system.folder_contents import (
    ReviewedKind,
    _files,
    _folder_entry,
    _generated_entry,
    _notes,
    _record_fields,
    _reviewed_entries,
    _rows_in_folder,
    _subfolders,
    entries_in,
)
from features.file_system.reading_time import reading_minutes
from features.file_system.review_counts import ReviewCounts
from shared.file_storage import storage_name
from shared.models import File, FlashcardDeck, Folder, Note, Test
from shared.models.mixins import FolderContent, GeneratedContent
from tests.file_storage_fakes import KnownFileSizes
from tests.folder_seeding import KINDS, seeded_folder
from tests.support import in_memory_sessions
from tests.unit_details_seeding import MOMENTS

_COUNTS = st.fixed_dictionaries(
    {kind: st.integers(min_value=0, max_value=3) for kind in KINDS}
)
_SOURCE_KINDS = st.one_of(st.none(), st.sampled_from(["file", "link"]))
_GENERATED_MODELS = (
    (FlashcardDeck, "flashcard_deck"),
    (Test, "test"),
    (Note, "note"),
)
_GENERATED_KINDS = st.sampled_from(_GENERATED_MODELS)
_CONTENT_KINDS = st.sampled_from([*_GENERATED_MODELS, (File, "file")])
_COUNTS_OR_NOTHING = st.one_of(
    st.none(),
    st.builds(
        ReviewCounts,
        total=st.integers(min_value=0, max_value=50),
        due=st.integers(min_value=0, max_value=50),
    ),
)
_SIZES = st.one_of(st.none(), st.integers(min_value=0, max_value=10**9))
_NOTE_TEXTS = st.text(alphabet="ab <p>", max_size=40)
_SESSIONS = in_memory_sessions()
_NO_FILE_SIZES = KnownFileSizes({})

ContentKind = tuple[type[FolderContent], str]
GeneratedKind = tuple[type[GeneratedContent], str]


@settings(max_examples=25, deadline=None)
@given(_COUNTS)
def test_entries_in_property_returns_every_seeded_entry_once(
    counts: dict[str, int],
) -> None:
    owner = uuid.uuid4()

    with _SESSIONS() as session:
        folder_id = seeded_folder(session, owner, counts)
        entries = entries_in(
            session, str(folder_id), str(owner), _NO_FILE_SIZES
        )

    assert len(entries) == sum(counts.values())
    assert len({entry["id"] for entry in entries}) == len(entries)


@settings(max_examples=25, deadline=None)
@given(_COUNTS, _COUNTS)
def test_entries_in_property_never_shows_another_owners_content(
    mine: dict[str, int], theirs: dict[str, int]
) -> None:
    owner = uuid.uuid4()
    stranger = uuid.uuid4()

    with _SESSIONS() as session:
        folder_id = seeded_folder(session, owner, mine)
        _ = seeded_folder(session, stranger, theirs)
        seen = entries_in(
            session, str(folder_id), str(stranger), _NO_FILE_SIZES
        )

    assert seen == []


@settings(max_examples=25, deadline=None)
@given(MOMENTS, st.text(min_size=1, max_size=8))
def test__record_fields_property_names_the_row_it_describes(
    created_at: datetime, name: str
) -> None:
    row = Folder(id=uuid.uuid4(), name=name, created_at=created_at)

    assert _record_fields(row) == {
        "id": str(row.id),
        "name": name,
        "created_at": str(created_at),
    }


@settings(max_examples=25, deadline=None)
@given(_COUNTS)
def test__subfolders_property_describes_every_child_folder_as_empty(
    counts: dict[str, int],
) -> None:
    owner = uuid.uuid4()

    with _SESSIONS() as session:
        folder_id = seeded_folder(session, owner, counts)
        rows = _subfolders(session, str(folder_id), owner)

    assert len(rows) == counts["folder"]

    for row in rows:
        assert row["type"] == "folder"
        assert row["item_count"] == 0
        assert row["edited_at"] == row["created_at"]


@settings(max_examples=25, deadline=None)
@given(MOMENTS, MOMENTS, st.integers(min_value=0, max_value=99))
def test__folder_entry_property_dates_the_edit_at_the_newest_moment(
    created_at: datetime, newest_child_at: datetime, item_count: int
) -> None:
    row = Folder(id=uuid.uuid4(), name="Shelf", created_at=created_at)
    summary = ChildSummary(
        item_count=item_count, newest_created_at=newest_child_at
    )
    entry = _folder_entry(row, summary)

    assert entry["item_count"] == item_count
    assert entry["edited_at"] == str(max(created_at, newest_child_at))
    assert entry["type"] == "folder"


@settings(max_examples=25, deadline=None)
@given(_SOURCE_KINDS, st.integers(min_value=0, max_value=99))
def test__generated_entry_property_keeps_its_details_and_its_source(
    source_kind: str | None, detail: int
) -> None:
    row = Test(id=uuid.uuid4(), name="Quiz", source_kind=source_kind)
    entry = _generated_entry(row, "test", {"question_count": detail})

    assert entry["type"] == "test"
    assert entry["question_count"] == detail
    assert ("source_kind" in entry) == (source_kind is not None)


@settings(max_examples=25, deadline=None)
@given(st.lists(_COUNTS_OR_NOTHING, max_size=4))
def test__reviewed_entries_property_counts_nothing_for_unknown_units(
    known_counts: list[ReviewCounts | None],
) -> None:
    rows: list[FlashcardDeck] = []
    counts: dict[uuid.UUID, ReviewCounts] = {}

    for unit_counts in known_counts:
        row = FlashcardDeck(id=uuid.uuid4(), name="Deck")
        rows.append(row)

        if unit_counts is not None:
            counts[row.id] = unit_counts

    kind = ReviewedKind(entry_type="flashcard_deck", total_field="card_count")
    entries = _reviewed_entries(rows, kind, counts)

    for entry, unit_counts in zip(entries, known_counts, strict=True):
        expected = (
            ReviewCounts(total=0, due=0)
            if unit_counts is None
            else unit_counts
        )

        assert entry["type"] == "flashcard_deck"
        assert entry["card_count"] == expected.total
        assert entry["due_count"] == expected.due


@settings(max_examples=25, deadline=None)
@given(st.lists(_NOTE_TEXTS, max_size=4))
def test__notes_property_times_the_reading_of_every_note(
    note_texts: list[str],
) -> None:
    rows: list[Note] = []

    for note_text in note_texts:
        rows.append(Note(id=uuid.uuid4(), name="Note", content=note_text))

    entries = _notes(rows)

    for entry, note_text in zip(entries, note_texts, strict=True):
        assert entry["type"] == "note"
        assert entry["reading_minutes"] == reading_minutes(note_text)


@settings(max_examples=25, deadline=None)
@given(st.lists(_SIZES, max_size=4))
def test__files_property_reports_each_stored_size_or_none(
    sizes: list[int | None],
) -> None:
    rows: list[File] = []
    known_sizes: dict[str, int] = {}

    for size in sizes:
        row = File(id=uuid.uuid4(), name="doc", extension="pdf")
        rows.append(row)

        if size is not None:
            known_sizes[storage_name(str(row.id), row.extension)] = size

    entries = _files(rows, KnownFileSizes(known_sizes))

    for entry, size in zip(entries, sizes, strict=True):
        assert entry["type"] == "file"
        assert entry["extension"] == "pdf"
        assert entry["size_bytes"] == size


@settings(max_examples=25, deadline=None)
@given(_COUNTS, _CONTENT_KINDS)
def test__rows_in_folder_property_reads_only_that_owners_folder(
    counts: dict[str, int], kind: ContentKind
) -> None:
    model, seeded_kind = kind
    owner = uuid.uuid4()
    stranger = uuid.uuid4()

    with _SESSIONS() as session:
        folder_id = seeded_folder(session, owner, counts)
        mine = _rows_in_folder(session, model, str(folder_id), owner)
        theirs = _rows_in_folder(session, model, str(folder_id), stranger)

    assert len(mine) == counts[seeded_kind]
    assert theirs == []


@settings(max_examples=25, deadline=None)
@given(_COUNTS, _GENERATED_KINDS)
def test_entries_in_property_labels_every_entry_with_its_kind(
    counts: dict[str, int], kind: GeneratedKind
) -> None:
    _, entry_type = kind
    owner = uuid.uuid4()

    with _SESSIONS() as session:
        folder_id = seeded_folder(session, owner, counts)
        entries = entries_in(
            session, str(folder_id), str(owner), _NO_FILE_SIZES
        )

    labelled = [entry for entry in entries if entry["type"] == entry_type]

    assert len(labelled) == counts[entry_type]
