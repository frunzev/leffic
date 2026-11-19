from sqlalchemy import ColumnElement, func, or_, select

from shared.clock import utc_today
from shared.models import Flashcard, TestItem, TestItemReview

_MASTERED_ACCURACY = 0.9
_UNANSWERED_ACCURACY = 0.0


def due_flashcard_condition() -> ColumnElement[bool]:
    return or_(
        func.date(Flashcard.next_review) <= utc_today(),
        Flashcard.next_review.is_(None),
    )


def mastered_question_condition() -> ColumnElement[bool]:
    average_accuracy = (
        select(
            func.coalesce(
                func.avg(TestItemReview.accuracy), _UNANSWERED_ACCURACY
            )
        )
        .where(TestItemReview.test_item_id == TestItem.id)
        .correlate(TestItem)
        .scalar_subquery()
    )

    return average_accuracy >= _MASTERED_ACCURACY
