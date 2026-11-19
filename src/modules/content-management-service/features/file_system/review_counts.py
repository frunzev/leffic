import uuid
from typing import NamedTuple

from sqlalchemy import Select, func, not_, select
from sqlalchemy.orm import Session

from shared.models import Flashcard, FlashcardDeck, Test, TestItem
from shared.review_due import (
    due_flashcard_condition,
    mastered_question_condition,
)

CountsStatement = Select[tuple[uuid.UUID, int, int]]


class ReviewCounts(NamedTuple):
    total: int
    due: int


NOTHING_TO_REVIEW = ReviewCounts(total=0, due=0)


def deck_review_counts(
    db: Session, folder_id: str
) -> dict[uuid.UUID, ReviewCounts]:
    due_cards = func.count(Flashcard.id).filter(due_flashcard_condition())
    statement = (
        select(Flashcard.deck_id, func.count(Flashcard.id), due_cards)
        .join(FlashcardDeck, FlashcardDeck.id == Flashcard.deck_id)
        .where(FlashcardDeck.folder_id == folder_id)
        .group_by(Flashcard.deck_id)
    )

    return _counts_by_unit(db, statement)


def assessment_review_counts(
    db: Session, folder_id: str
) -> dict[uuid.UUID, ReviewCounts]:
    unmastered = not_(mastered_question_condition())
    due_items = func.count(TestItem.id).filter(unmastered)
    statement = (
        select(TestItem.test_id, func.count(TestItem.id), due_items)
        .join(Test, Test.id == TestItem.test_id)
        .where(Test.folder_id == folder_id)
        .group_by(TestItem.test_id)
    )

    return _counts_by_unit(db, statement)


def _counts_by_unit(
    db: Session, statement: CountsStatement
) -> dict[uuid.UUID, ReviewCounts]:
    counts: dict[uuid.UUID, ReviewCounts] = {}

    for unit_id, total, due in db.execute(statement).tuples():
        counts[unit_id] = ReviewCounts(total=total, due=due)

    return counts
