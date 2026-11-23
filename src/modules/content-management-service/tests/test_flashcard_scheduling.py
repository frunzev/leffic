from fsrs import Card

from shared.flashcard_scheduling import (
    RATING_MAP,
    get_ratings_times,
    schedule_flashcard_fsrs,
)

_GOOD_RATING = 3
_EASY_RATING = 4


def test_schedules_a_brand_new_card() -> None:
    new_card, review_log = schedule_flashcard_fsrs(None, _GOOD_RATING)

    assert "due" in new_card
    assert review_log["rating"] == _GOOD_RATING


def test_schedules_an_existing_card() -> None:
    card = Card().to_dict()

    new_card, _ = schedule_flashcard_fsrs(card, _GOOD_RATING)

    assert new_card["card_id"] == card["card_id"]


def test_every_rating_gets_a_due_time() -> None:
    ratings_times = get_ratings_times(None)

    assert sorted(ratings_times) == sorted(RATING_MAP)


def test_due_times_are_never_negative() -> None:
    ratings_times = get_ratings_times(Card().to_dict())

    assert all(seconds >= 0 for seconds in ratings_times.values())


def test_harder_ratings_come_due_sooner_than_easier_ones() -> None:
    ratings_times = get_ratings_times(None)

    assert ratings_times[1] <= ratings_times[4]


def test_the_given_card_changes_the_rating_times() -> None:
    reviewed, _ = schedule_flashcard_fsrs(None, _EASY_RATING)
    reviewed, _ = schedule_flashcard_fsrs(reviewed, _EASY_RATING)

    reviewed_times = get_ratings_times(reviewed)
    new_times = get_ratings_times(None)

    assert reviewed_times[_GOOD_RATING] > new_times[_GOOD_RATING] * 2


def test_the_given_card_changes_the_schedule() -> None:
    reviewed, _ = schedule_flashcard_fsrs(None, _GOOD_RATING)
    twice, _ = schedule_flashcard_fsrs(reviewed, _GOOD_RATING)

    assert twice["due"] != reviewed["due"]
