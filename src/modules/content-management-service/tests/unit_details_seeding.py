import uuid
from collections.abc import Callable
from datetime import UTC, datetime, timedelta

from hypothesis import strategies as st
from sqlalchemy.orm import Session

from shared.models import (
    File,
    Flashcard,
    FlashcardDeck,
    Folder,
    Note,
    Test,
    TestItem,
    TestItemReview,
    TestSession,
)
from shared.models.mixins import FolderContent

DayOffset = int | None
DatedChild = tuple[str, datetime]
ChildBuilder = Callable[
    [uuid.UUID, uuid.UUID, datetime], "Folder | FolderContent"
]

MASTERED_ACCURACY = 0.9
DAY_OFFSETS = st.one_of(st.none(), st.integers(min_value=-30, max_value=30))
ITEM_ACCURACIES = st.lists(
    st.sampled_from([0.0, 0.25, 0.5, 0.75, 1.0]), max_size=4
)
MOMENTS = st.datetimes(
    min_value=datetime(2020, 1, 1),  # noqa: DTZ001
    max_value=datetime(2030, 1, 1),  # noqa: DTZ001
)
FOLDER_NAMES = st.text(alphabet="abcdefgh ", min_size=1, max_size=8)

_DONE = "done"
_QUESTION: dict[str, object] = {
    "question": "Which is a mammal?",
    "true_option": "whale",
    "false_options": ["shark", "trout"],
}


def count_due_cards(day_offsets: list[DayOffset]) -> int:
    due_cards = 0

    for day_offset in day_offsets:
        if day_offset is None or day_offset <= 0:
            due_cards += 1

    return due_cards


def is_mastered(accuracies: list[float]) -> bool:
    if not accuracies:
        return False

    return sum(accuracies) / len(accuracies) >= MASTERED_ACCURACY


def count_unmastered_items(accuracies_per_item: list[list[float]]) -> int:
    unmastered_items = 0

    for accuracies in accuracies_per_item:
        if not is_mastered(accuracies):
            unmastered_items += 1

    return unmastered_items


def _review_moment(day_offset: DayOffset) -> datetime | None:
    if day_offset is None:
        return None

    return datetime.now(UTC) + timedelta(days=day_offset)


def seeded_deck_with_cards(
    session: Session, folder_id: uuid.UUID, day_offsets: list[DayOffset]
) -> uuid.UUID:
    deck = FlashcardDeck(
        id=uuid.uuid4(),
        name="Deck",
        folder_id=folder_id,
        created_at=datetime.now(UTC),
        public=False,
    )

    for day_offset in day_offsets:
        deck.flashcards.append(
            Flashcard(
                type="basic",
                content={"front": "question"},
                next_review=_review_moment(day_offset),
                created_at=datetime.now(UTC),
            )
        )

    session.add(deck)
    session.commit()

    return deck.id


def seeded_test_with_items(
    session: Session,
    folder_id: uuid.UUID,
    accuracies_per_item: list[list[float]],
) -> uuid.UUID:
    quiz = Test(
        id=uuid.uuid4(),
        name="Quiz",
        folder_id=folder_id,
        created_at=datetime.now(UTC),
        public=False,
    )
    test_session = TestSession(
        id=uuid.uuid4(),
        origin_id=quiz.id,
        status=_DONE,
        user_id=uuid.uuid4(),
    )

    for accuracies in accuracies_per_item:
        item = TestItem(content=_QUESTION, type="mult_choice")

        for accuracy in accuracies:
            item.test_item_reviews.append(
                TestItemReview(
                    test_session=test_session.id,
                    accuracy=accuracy,
                    answers=[],
                )
            )

        quiz.test_items.append(item)

    session.add_all([quiz, test_session])
    session.commit()

    return quiz.id


def seeded_folder_chain(
    session: Session, owner: uuid.UUID, names: list[str]
) -> list[uuid.UUID]:
    chain: list[uuid.UUID] = []
    parent_id: uuid.UUID | None = None

    for name in names:
        folder = Folder(
            id=owner if parent_id is None else uuid.uuid4(),
            name=name,
            user_id=owner,
            parent_id=parent_id,
        )
        session.add(folder)
        session.flush()
        chain.append(folder.id)
        parent_id = folder.id

    session.commit()

    return chain


def seeded_dated_children(
    session: Session,
    owner: uuid.UUID,
    folder_id: uuid.UUID,
    dated_children: list[DatedChild],
) -> None:
    for kind, created_at in dated_children:
        build_child = _CHILD_BUILDERS[kind]
        session.add(build_child(owner, folder_id, created_at))

    session.commit()


def _child_folder(
    owner: uuid.UUID, folder_id: uuid.UUID, created_at: datetime
) -> Folder | FolderContent:
    return Folder(
        name="child",
        user_id=owner,
        parent_id=folder_id,
        created_at=created_at,
    )


def _child_deck(
    _owner: uuid.UUID, folder_id: uuid.UUID, created_at: datetime
) -> Folder | FolderContent:
    return FlashcardDeck(
        name="deck", folder_id=folder_id, created_at=created_at
    )


def _child_test(
    _owner: uuid.UUID, folder_id: uuid.UUID, created_at: datetime
) -> Folder | FolderContent:
    return Test(name="quiz", folder_id=folder_id, created_at=created_at)


def _child_note(
    _owner: uuid.UUID, folder_id: uuid.UUID, created_at: datetime
) -> Folder | FolderContent:
    return Note(
        name="note",
        folder_id=folder_id,
        content="body",
        type="summary",
        created_at=created_at,
    )


def _child_file(
    _owner: uuid.UUID, folder_id: uuid.UUID, created_at: datetime
) -> Folder | FolderContent:
    return File(
        name="file",
        folder_id=folder_id,
        extension="pdf",
        created_at=created_at,
    )


_CHILD_BUILDERS: dict[str, ChildBuilder] = {
    "folder": _child_folder,
    "flashcard_deck": _child_deck,
    "test": _child_test,
    "note": _child_note,
    "file": _child_file,
}

CHILD_KINDS = st.sampled_from(list(_CHILD_BUILDERS))
