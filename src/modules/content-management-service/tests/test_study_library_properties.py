import uuid

import pytest
from fastapi import HTTPException
from hypothesis import given, settings
from hypothesis import strategies as st
from sqlalchemy.orm import Session, sessionmaker

from features.chatbot.study_library import StudyLibrary
from shared.models import Flashcard, Note
from tests.property_support import seeded_deck
from tests.support import in_memory_sessions

_CARD_TEXT = st.text(min_size=1, max_size=40)
_NOTE_TEXT = st.text(min_size=1, max_size=80)


def _seeded_note(
    sessions: sessionmaker[Session], folder_id: uuid.UUID, content: str
) -> uuid.UUID:
    with sessions() as session:
        note = Note(
            name="Note",
            folder_id=folder_id,
            content=content,
            type="note",
        )
        session.add(note)
        session.commit()

        return note.id


def _card_contents(
    sessions: sessionmaker[Session], deck_id: uuid.UUID
) -> list[object]:
    with sessions() as session:
        cards = session.query(Flashcard).filter_by(deck_id=deck_id).all()

        return [card.content for card in cards]


@settings(max_examples=20, deadline=None)
@given(st.integers(min_value=0, max_value=3))
def test_folder_outline_property_names_only_the_callers_own_units(
    card_count: int,
) -> None:
    sessions = in_memory_sessions()
    owner = uuid.uuid4()
    stranger = uuid.uuid4()

    with sessions() as session:
        owned_folder, owned_deck, _ = seeded_deck(session, owner, card_count)
        foreign_folder, foreign_deck, _ = seeded_deck(session, stranger, 1)

    outline = StudyLibrary(sessions, str(owner)).folder_outline()

    assert str(owned_folder) in outline
    assert str(owned_deck) in outline
    assert str(foreign_folder) not in outline
    assert str(foreign_deck) not in outline


@settings(max_examples=20, deadline=None)
@given(_NOTE_TEXT)
def test_note_content_property_hands_back_the_stored_text(
    content: str,
) -> None:
    sessions = in_memory_sessions()
    owner = uuid.uuid4()

    with sessions() as session:
        folder_id, _, _ = seeded_deck(session, owner, 0)

    note_id = _seeded_note(sessions, folder_id, content)

    library = StudyLibrary(sessions, str(owner))

    assert library.note_content(str(note_id)) == content


@settings(max_examples=20, deadline=None)
@given(_NOTE_TEXT)
def test_note_content_property_refuses_a_strangers_note(
    content: str,
) -> None:
    sessions = in_memory_sessions()

    with sessions() as session:
        folder_id, _, _ = seeded_deck(session, uuid.uuid4(), 0)

    note_id = _seeded_note(sessions, folder_id, content)
    library = StudyLibrary(sessions, str(uuid.uuid4()))

    with pytest.raises(HTTPException):
        _ = library.note_content(str(note_id))


@settings(max_examples=20, deadline=None)
@given(st.integers(min_value=0, max_value=3), _CARD_TEXT, _CARD_TEXT)
def test_append_flashcard_property_adds_exactly_the_given_card(
    card_count: int, front: str, back: str
) -> None:
    sessions = in_memory_sessions()
    owner = uuid.uuid4()

    with sessions() as session:
        _, deck_id, _ = seeded_deck(session, owner, card_count)

    StudyLibrary(sessions, str(owner)).append_flashcard(
        str(deck_id), front, back
    )
    contents = _card_contents(sessions, deck_id)

    assert len(contents) == card_count + 1
    assert {"front": front, "back": back} in contents


@settings(max_examples=20, deadline=None)
@given(_CARD_TEXT, _CARD_TEXT)
def test_append_flashcard_property_never_touches_a_strangers_deck(
    front: str, back: str
) -> None:
    sessions = in_memory_sessions()

    with sessions() as session:
        _, deck_id, _ = seeded_deck(session, uuid.uuid4(), 1)

    library = StudyLibrary(sessions, str(uuid.uuid4()))

    with pytest.raises(HTTPException):
        library.append_flashcard(str(deck_id), front, back)

    assert len(_card_contents(sessions, deck_id)) == 1


@settings(max_examples=20, deadline=None)
@given(st.lists(_NOTE_TEXT, min_size=1, max_size=3))
def test_folder_outline_property_names_every_note_in_the_folder(
    contents: list[str],
) -> None:
    sessions = in_memory_sessions()
    owner = uuid.uuid4()

    with sessions() as session:
        folder_id, _, _ = seeded_deck(session, owner, 0)

    note_ids = [
        _seeded_note(sessions, folder_id, content) for content in contents
    ]
    outline = StudyLibrary(sessions, str(owner)).folder_outline()

    for note_id in note_ids:
        assert f"note {note_id}" in outline
