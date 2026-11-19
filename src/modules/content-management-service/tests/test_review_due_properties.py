import uuid

from hypothesis import given, settings
from hypothesis import strategies as st
from sqlalchemy import select

from shared.models import Flashcard, TestItem
from shared.review_due import (
    due_flashcard_condition,
    mastered_question_condition,
)
from tests.folder_seeding import seeded_folder
from tests.support import in_memory_sessions
from tests.unit_details_seeding import (
    DAY_OFFSETS,
    ITEM_ACCURACIES,
    DayOffset,
    count_due_cards,
    is_mastered,
    seeded_deck_with_cards,
    seeded_test_with_items,
)

_SESSIONS = in_memory_sessions()


@settings(max_examples=25, deadline=None)
@given(st.lists(DAY_OFFSETS, max_size=6))
def test_due_flashcard_condition_property_picks_cards_due_by_today(
    day_offsets: list[DayOffset],
) -> None:
    with _SESSIONS() as session:
        folder_id = seeded_folder(session, uuid.uuid4(), {})
        deck_id = seeded_deck_with_cards(session, folder_id, day_offsets)
        due_cards = session.execute(
            select(Flashcard.id).where(
                Flashcard.deck_id == deck_id, due_flashcard_condition()
            )
        ).all()

    assert len(due_cards) == count_due_cards(day_offsets)


@settings(max_examples=25, deadline=None)
@given(st.lists(ITEM_ACCURACIES, max_size=5))
def test_mastered_question_condition_property_needs_nine_tenths_on_average(
    accuracies_per_item: list[list[float]],
) -> None:
    with _SESSIONS() as session:
        folder_id = seeded_folder(session, uuid.uuid4(), {})
        test_id = seeded_test_with_items(
            session, folder_id, accuracies_per_item
        )
        mastery = (
            session.execute(
                select(mastered_question_condition())
                .where(TestItem.test_id == test_id)
                .order_by(TestItem.id)
            )
            .scalars()
            .all()
        )

    expected_mastery: list[bool] = []

    for accuracies in accuracies_per_item:
        expected_mastery.append(is_mastered(accuracies))

    assert list(mastery) == expected_mastery
