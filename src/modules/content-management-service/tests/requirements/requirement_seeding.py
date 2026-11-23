import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session, sessionmaker

from shared.models import Flashcard, FlashcardDeck, Note, Test, TestItem

NOTE_BODY = "<p>Cells are the unit of life.</p>"

_BASIC_CARD = "basic"
_CARD_BACK = "An answer worth remembering."
_NOTE_TYPE = "general"
_MULTIPLE_CHOICE = "mult_choice"
_TRUE_OR_FALSE = "true_or_false"
_SHORT_ANSWER = "short_answer"

Sessions = sessionmaker[Session]


def _card(card_front: str) -> Flashcard:
    card_content: dict[str, object] = {
        "front": card_front,
        "back": _CARD_BACK,
    }

    return Flashcard(type=_BASIC_CARD, content=card_content)


def seeded_deck(
    sessions: Sessions, folder_id: str, deck_name: str, card_front: str
) -> None:
    deck = FlashcardDeck(folder_id=uuid.UUID(folder_id), name=deck_name)
    deck.flashcards.append(_card(card_front))

    with sessions() as session:
        session.add(deck)
        session.commit()


def seeded_card(sessions: Sessions, deck_name: str, card_front: str) -> None:
    query = select(FlashcardDeck).where(FlashcardDeck.name == deck_name)

    with sessions() as session:
        deck = session.execute(query).scalar_one()
        deck.flashcards.append(_card(card_front))
        session.commit()


def seeded_note(
    sessions: Sessions, folder_id: str, note_name: str, note_body: str
) -> None:
    note = Note(
        folder_id=uuid.UUID(folder_id),
        name=note_name,
        content=note_body,
        type=_NOTE_TYPE,
    )

    with sessions() as session:
        session.add(note)
        session.commit()


def seeded_test(sessions: Sessions, folder_id: str, test_name: str) -> None:
    with sessions() as session:
        session.add(Test(folder_id=uuid.UUID(folder_id), name=test_name))
        session.commit()


def _seeded_item(
    sessions: Sessions,
    test_id: str,
    item_type: str,
    item_content: dict[str, object],
) -> None:
    test_item = TestItem(
        test_id=uuid.UUID(test_id), content=item_content, type=item_type
    )

    with sessions() as session:
        session.add(test_item)
        session.commit()


def seeded_question(
    sessions: Sessions,
    test_id: str,
    question: str,
    options: tuple[str, str],
) -> None:
    right_option, wrong_option = options
    question_content: dict[str, object] = {
        "question": question,
        "true_option": right_option,
        "false_options": [wrong_option],
    }
    _seeded_item(sessions, test_id, _MULTIPLE_CHOICE, question_content)


def seeded_statement(
    sessions: Sessions, test_id: str, statement: str, *, is_true: bool
) -> None:
    statement_content: dict[str, object] = {
        "statement": statement,
        "is_true": is_true,
    }
    _seeded_item(sessions, test_id, _TRUE_OR_FALSE, statement_content)


def seeded_short_answer(
    sessions: Sessions, test_id: str, question: str, answer: str
) -> None:
    short_answer_content: dict[str, object] = {
        "question": question,
        "answer": answer,
    }
    _seeded_item(sessions, test_id, _SHORT_ANSWER, short_answer_content)


def seed_item(
    sessions: Sessions, test_id: str, item_content: dict[str, object]
) -> None:
    _seeded_item(sessions, test_id, _MULTIPLE_CHOICE, item_content)
