import uuid

from hypothesis import given, settings
from hypothesis import strategies as st
from sqlalchemy import func, select

from features.file_system.review_counts import (
    NOTHING_TO_REVIEW,
    ReviewCounts,
    _counts_by_unit,
    assessment_review_counts,
    deck_review_counts,
)
from shared.models import Flashcard
from tests.folder_seeding import seeded_folder
from tests.support import in_memory_sessions
from tests.unit_details_seeding import (
    DAY_OFFSETS,
    ITEM_ACCURACIES,
    DayOffset,
    count_due_cards,
    count_unmastered_items,
    seeded_deck_with_cards,
    seeded_test_with_items,
)

_SESSIONS = in_memory_sessions()
_CARDS_PER_DECK = st.lists(st.lists(DAY_OFFSETS, max_size=4), max_size=3)
_ITEMS_PER_TEST = st.lists(st.lists(ITEM_ACCURACIES, max_size=4), max_size=3)


@settings(max_examples=25, deadline=None)
@given(_CARDS_PER_DECK)
def test_deck_review_counts_property_counts_every_card_and_every_due_card(
    cards_per_deck: list[list[DayOffset]],
) -> None:
    with _SESSIONS() as session:
        folder_id = seeded_folder(session, uuid.uuid4(), {})
        deck_ids: list[uuid.UUID] = []

        for day_offsets in cards_per_deck:
            deck_ids.append(
                seeded_deck_with_cards(session, folder_id, day_offsets)
            )

        counts = deck_review_counts(session, str(folder_id))

    assert set(counts) <= set(deck_ids)

    for deck_id, day_offsets in zip(deck_ids, cards_per_deck, strict=True):
        expected = ReviewCounts(
            total=len(day_offsets), due=count_due_cards(day_offsets)
        )

        assert counts.get(deck_id, NOTHING_TO_REVIEW) == expected


@settings(max_examples=25, deadline=None)
@given(_ITEMS_PER_TEST)
def test_assessment_review_counts_property_counts_unmastered_items_as_due(
    items_per_test: list[list[list[float]]],
) -> None:
    with _SESSIONS() as session:
        folder_id = seeded_folder(session, uuid.uuid4(), {})
        test_ids: list[uuid.UUID] = []

        for accuracies_per_item in items_per_test:
            test_ids.append(
                seeded_test_with_items(session, folder_id, accuracies_per_item)
            )

        counts = assessment_review_counts(session, str(folder_id))

    assert set(counts) <= set(test_ids)

    for test_id, accuracies_per_item in zip(
        test_ids, items_per_test, strict=True
    ):
        expected = ReviewCounts(
            total=len(accuracies_per_item),
            due=count_unmastered_items(accuracies_per_item),
        )

        assert counts.get(test_id, NOTHING_TO_REVIEW) == expected


@settings(max_examples=25, deadline=None)
@given(st.lists(st.integers(min_value=1, max_value=4), max_size=3))
def test__counts_by_unit_property_keeps_one_entry_per_grouped_unit(
    card_counts: list[int],
) -> None:
    with _SESSIONS() as session:
        folder_id = seeded_folder(session, uuid.uuid4(), {})
        deck_ids: list[uuid.UUID] = []

        for card_count in card_counts:
            deck_ids.append(
                seeded_deck_with_cards(session, folder_id, [None] * card_count)
            )

        statement = (
            select(
                Flashcard.deck_id,
                func.count(Flashcard.id),
                func.count(Flashcard.id),
            )
            .where(Flashcard.deck_id.in_(deck_ids))
            .group_by(Flashcard.deck_id)
        )
        counts = _counts_by_unit(session, statement)

    expected: dict[uuid.UUID, ReviewCounts] = {}

    for deck_id, card_count in zip(deck_ids, card_counts, strict=True):
        expected[deck_id] = ReviewCounts(total=card_count, due=card_count)

    assert counts == expected
