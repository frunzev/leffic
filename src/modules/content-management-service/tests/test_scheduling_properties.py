from datetime import UTC, datetime

from fsrs import Card, Scheduler
from hypothesis import given, settings
from hypothesis import strategies as st

from shared.flashcard_scheduling import (
    RATING_MAP,
    _preview_scheduler,
    _restored_card,
    get_ratings_times,
    schedule_flashcard_fsrs,
)

_RATINGS = st.integers(min_value=1, max_value=4)
_REVIEW_HISTORIES = st.lists(_RATINGS, max_size=4)


def _reviewed_card(ratings: list[int]) -> Card:
    scheduler = Scheduler()
    card = Card()

    for rating in ratings:
        card, _ = scheduler.review_card(card, RATING_MAP[rating])

    return card


@settings(max_examples=25)
@given(_REVIEW_HISTORIES)
def test__restored_card_property_round_trips_a_serialised_card(
    ratings: list[int],
) -> None:
    card = _reviewed_card(ratings)

    assert _restored_card(card.to_dict()).to_dict() == card.to_dict()


@settings(max_examples=25)
@given(_REVIEW_HISTORIES, _RATINGS)
def test__preview_scheduler_property_previews_one_review_identically(
    ratings: list[int], rating: int
) -> None:
    card = _reviewed_card(ratings)
    reviewed_at = datetime.now(UTC)

    first, _ = _preview_scheduler().review_card(
        card, RATING_MAP[rating], review_datetime=reviewed_at
    )
    second, _ = _preview_scheduler().review_card(
        card, RATING_MAP[rating], review_datetime=reviewed_at
    )

    assert first.due == second.due


@settings(max_examples=25, deadline=None)
@given(_REVIEW_HISTORIES, _RATINGS)
def test_schedule_flashcard_fsrs_property_never_schedules_into_the_past(
    ratings: list[int], rating: int
) -> None:
    reviewed_at = datetime.now(UTC)
    card, _ = schedule_flashcard_fsrs(
        _reviewed_card(ratings).to_dict(), rating
    )

    assert Card.from_dict(card).due >= reviewed_at


@settings(max_examples=25, deadline=None)
@given(_REVIEW_HISTORIES)
def test_get_ratings_times_property_never_returns_a_negative_wait(
    ratings: list[int],
) -> None:
    times = get_ratings_times(_reviewed_card(ratings).to_dict())

    assert sorted(times) == [1, 2, 3, 4]
    assert all(seconds >= 0 for seconds in times.values())


@settings(max_examples=60, deadline=None)
@given(_REVIEW_HISTORIES)
def test_get_ratings_times_property_never_brings_a_harder_rating_back_later(
    ratings: list[int],
) -> None:
    times = get_ratings_times(_reviewed_card(ratings).to_dict())
    waits_from_hardest_to_easiest = [times[1], times[2], times[3], times[4]]

    assert waits_from_hardest_to_easiest == sorted(
        waits_from_hardest_to_easiest
    )
