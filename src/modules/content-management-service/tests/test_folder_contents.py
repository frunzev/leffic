import uuid
from datetime import datetime

import pytest
from sqlalchemy.orm import Session, sessionmaker

from features.file_system.folder_contents import ContentEntry, entries_in
from shared.models import (
    File,
    Flashcard,
    FlashcardDeck,
    Folder,
    Note,
    Test,
    TestItem,
)
from tests.access_support import QUESTION
from tests.file_storage_fakes import KnownFileSizes
from tests.support import USER_ID, in_memory_sessions

_HOME_ID = uuid.UUID(USER_ID)
_MADE_AT = datetime(2026, 8, 8, 17, 0, 0)  # noqa: DTZ001
_MADE_AT_TEXT = "2026-08-08 17:00:00"
_LATER = datetime(2026, 8, 9, 9, 30, 0)  # noqa: DTZ001
_LATER_TEXT = "2026-08-09 09:30:00"
_FAR_FUTURE = datetime(2999, 1, 1)  # noqa: DTZ001
_STORED_SIZE = 1_234_567
_NO_FILE_SIZES = KnownFileSizes({})
_FOUR_HUNDRED_WORDS = "<p>" + "word " * 400 + "</p>"


@pytest.fixture
def sessions() -> sessionmaker[Session]:
    return in_memory_sessions()


def _home(session: Session) -> Folder:
    folder = Folder(
        id=_HOME_ID, name="Home", user_id=_HOME_ID, created_at=_MADE_AT
    )
    session.add(folder)
    session.commit()

    return folder


def _entries(
    sessions: sessionmaker[Session], file_sizes: KnownFileSizes
) -> list[ContentEntry]:
    with sessions() as session:
        return entries_in(session, str(_HOME_ID), USER_ID, file_sizes)


def test_a_subfolder_is_described_in_full(
    sessions: sessionmaker[Session],
) -> None:
    with sessions() as session:
        _ = _home(session)
        child = Folder(
            parent_id=_HOME_ID,
            name="Biology",
            user_id=_HOME_ID,
            created_at=_MADE_AT,
        )
        session.add(child)
        session.commit()
        session.add(
            Note(
                folder_id=child.id,
                name="Cells",
                content="body",
                type="general",
                created_at=_LATER,
            )
        )
        session.add(
            Folder(
                parent_id=child.id,
                name="Genes",
                user_id=_HOME_ID,
                created_at=_MADE_AT,
            )
        )
        session.commit()
        child_id = str(child.id)

    assert _entries(sessions, _NO_FILE_SIZES) == [
        {
            "id": child_id,
            "name": "Biology",
            "created_at": _MADE_AT_TEXT,
            "type": "folder",
            "item_count": 2,
            "edited_at": _LATER_TEXT,
        }
    ]


def test_a_deck_is_described_in_full(
    sessions: sessionmaker[Session],
) -> None:
    with sessions() as session:
        _ = _home(session)
        deck = FlashcardDeck(
            folder_id=_HOME_ID, name="Cells", created_at=_MADE_AT
        )
        deck.flashcards.append(Flashcard(type="basic", content={"q": "a"}))
        deck.flashcards.append(
            Flashcard(
                type="basic", content={"q": "b"}, next_review=_FAR_FUTURE
            )
        )
        session.add(deck)
        session.commit()
        deck_id = str(deck.id)

    assert _entries(sessions, _NO_FILE_SIZES) == [
        {
            "id": deck_id,
            "name": "Cells",
            "created_at": _MADE_AT_TEXT,
            "type": "flashcard_deck",
            "card_count": 2,
            "due_count": 1,
        }
    ]


def test_a_test_is_described_in_full(
    sessions: sessionmaker[Session],
) -> None:
    with sessions() as session:
        _ = _home(session)
        quiz = Test(folder_id=_HOME_ID, name="Quiz", created_at=_MADE_AT)
        quiz.test_items.append(TestItem(content=QUESTION, type="mult_choice"))
        session.add(quiz)
        session.commit()
        quiz_id = str(quiz.id)

    assert _entries(sessions, _NO_FILE_SIZES) == [
        {
            "id": quiz_id,
            "name": "Quiz",
            "created_at": _MADE_AT_TEXT,
            "type": "test",
            "question_count": 1,
            "due_count": 1,
        }
    ]


def test_a_file_is_described_in_full(
    sessions: sessionmaker[Session],
) -> None:
    with sessions() as session:
        _ = _home(session)
        stored = File(
            folder_id=_HOME_ID,
            name="notes",
            extension="pdf",
            created_at=_MADE_AT,
        )
        session.add(stored)
        session.commit()
        file_id = str(stored.id)

    file_sizes = KnownFileSizes({f"{file_id}.pdf": _STORED_SIZE})

    assert _entries(sessions, file_sizes) == [
        {
            "id": file_id,
            "name": "notes",
            "created_at": _MADE_AT_TEXT,
            "extension": "pdf",
            "type": "file",
            "size_bytes": _STORED_SIZE,
        }
    ]


def test_a_file_missing_from_storage_has_no_size(
    sessions: sessionmaker[Session],
) -> None:
    with sessions() as session:
        _ = _home(session)
        session.add(File(folder_id=_HOME_ID, name="gone", extension="pdf"))
        session.commit()

    assert _entries(sessions, _NO_FILE_SIZES)[0]["size_bytes"] is None


def test_a_note_is_described_in_full(
    sessions: sessionmaker[Session],
) -> None:
    with sessions() as session:
        _ = _home(session)
        note = Note(
            folder_id=_HOME_ID,
            name="Intro",
            content=_FOUR_HUNDRED_WORDS,
            type="general",
            created_at=_MADE_AT,
        )
        session.add(note)
        session.commit()
        note_id = str(note.id)

    assert _entries(sessions, _NO_FILE_SIZES) == [
        {
            "id": note_id,
            "name": "Intro",
            "created_at": _MADE_AT_TEXT,
            "type": "note",
            "reading_minutes": 2,
        }
    ]
