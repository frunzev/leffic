from datetime import UTC, datetime, timedelta
from typing import cast

from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from tests.requirements.card_lookup import (
    card_fronts,
    due_card_id,
    due_cards,
    due_cards_in_deck,
    stored_card,
)
from tests.requirements.requirement_listing import HOME
from tests.requirements.requirement_lookup import (
    Sessions,
    folder_id_named,
    home_folder_id,
    reply_body,
)
from tests.requirements.requirement_seeding import seeded_card, seeded_deck
from tests.support import authorization

_REVIEW_FLASHCARD = "/review-flashcard"
_RATING_INTERVALS = "/rating-intervals"
_FLASHCARDS_STATS = "/flashcards-stats"
_RATINGS = {"Again": 1, "Hard": 2, "Good": 3, "Easy": 4}
_DUE_DATE_FORMAT = "%Y-%m-%d %H:%M:%S"
_DECK_IN_FOLDER_STEP = (
    'I have the deck "{deck_name}" in "{folder_name}" '
    'with the card "{card_front}"'
)


@given(
    parsers.parse(
        'I have the deck "{deck_name}" in home with the card "{card_front}"'
    )
)
def create_deck_in_home(
    sessions: Sessions, deck_name: str, card_front: str
) -> None:
    seeded_deck(sessions, home_folder_id(sessions), deck_name, card_front)


@given(parsers.parse(_DECK_IN_FOLDER_STEP))
def create_deck_in_folder(
    sessions: Sessions, deck_name: str, folder_name: str, card_front: str
) -> None:
    folder_id = folder_id_named(sessions, folder_name)
    seeded_deck(sessions, folder_id, deck_name, card_front)


@given(
    parsers.parse('the deck "{deck_name}" also has the card "{card_front}"')
)
def add_card_to_deck(
    sessions: Sessions, deck_name: str, card_front: str
) -> None:
    seeded_card(sessions, deck_name, card_front)


@when(
    parsers.parse('I ask for the cards due in the deck "{deck_name}"'),
    target_fixture="reply",
)
def ask_due_cards_in_deck(
    client: TestClient, sessions: Sessions, deck_name: str
) -> Response:
    return due_cards_in_deck(client, sessions, deck_name)


@when("I ask for the cards due in home", target_fixture="reply")
def ask_due_cards_in_home(client: TestClient) -> Response:
    return due_cards(client, {"folder_id": HOME})


@when(
    parsers.parse('I ask for the cards due in the folder "{folder_name}"'),
    target_fixture="reply",
)
def ask_due_cards_in_folder(
    client: TestClient, sessions: Sessions, folder_name: str
) -> Response:
    folder_id = folder_id_named(sessions, folder_name)

    return due_cards(client, {"folder_id": folder_id})


@then(parsers.parse('I get the card "{card_front}"'))
def check_card_received(reply: Response, card_front: str) -> None:
    assert card_front in card_fronts(reply)


@then("I get no cards")
def check_no_cards_received(reply: Response) -> None:
    assert card_fronts(reply) == []


@when(
    parsers.parse('I rate the card "{card_front}" as "{rating_name}"'),
    target_fixture="reply",
)
@given(parsers.parse('I rated the card "{card_front}" as "{rating_name}"'))
def rate_card(
    client: TestClient, card_front: str, rating_name: str
) -> Response:
    review_request = {
        "flashcard_id": due_card_id(client, card_front),
        "rating": _RATINGS[rating_name],
    }
    reply = client.post(
        _REVIEW_FLASHCARD, json=review_request, headers=authorization()
    )
    _ = reply.raise_for_status()

    return reply


@then(parsers.parse("the card is put off for at least {days:d} day"))
def check_card_put_off(reply: Response, days: int) -> None:
    due_text = str(reply_body(reply)["due_date"])
    due_moment = datetime.strptime(due_text, _DUE_DATE_FORMAT).replace(
        tzinfo=UTC
    )
    earliest_allowed_due = datetime.now(UTC) + timedelta(days=days)

    assert due_moment >= earliest_allowed_due


@then(parsers.parse('the deck "{deck_name}" has no cards due today'))
def check_deck_has_nothing_due(
    client: TestClient, sessions: Sessions, deck_name: str
) -> None:
    reply = due_cards_in_deck(client, sessions, deck_name)

    assert reply_body(reply)["total_flashcards"] == 0


@then(parsers.parse('the deck "{deck_name}" has the card "{card_front}"'))
def check_deck_has_card(
    client: TestClient, sessions: Sessions, deck_name: str, card_front: str
) -> None:
    reply = due_cards_in_deck(client, sessions, deck_name)

    assert card_front in card_fronts(reply)


@when(
    "I ask when a new card comes back for each rating",
    target_fixture="reply",
)
def ask_new_card_intervals(client: TestClient) -> Response:
    return client.post(
        _RATING_INTERVALS, json={"card": None}, headers=authorization()
    )


@when(
    parsers.parse(
        'I ask when the card "{card_front}" comes back for each rating'
    ),
    target_fixture="reply",
)
def ask_card_intervals(
    client: TestClient, sessions: Sessions, card_front: str
) -> Response:
    card_state = stored_card(sessions, card_front).fsrs_card

    return client.post(
        _RATING_INTERVALS, json={"card": card_state}, headers=authorization()
    )


@then(
    parsers.parse(
        '"{harder_rating}" comes back no later than "{easier_rating}"'
    )
)
def check_interval_order(
    reply: Response, harder_rating: str, easier_rating: str
) -> None:
    seconds_until_due = reply_body(reply)
    harder_key = str(_RATINGS[harder_rating])
    easier_key = str(_RATINGS[easier_rating])
    harder_seconds = cast("int", seconds_until_due[harder_key])
    easier_seconds = cast("int", seconds_until_due[easier_key])

    assert harder_seconds <= easier_seconds


@when("I ask how many cards are due in home", target_fixture="reply")
def ask_card_counts(client: TestClient) -> Response:
    return client.get(
        _FLASHCARDS_STATS, params={"folder_id": HOME}, headers=authorization()
    )


@then(
    parsers.parse("home has {due_count:d} cards due and {done_count:d} done")
)
def check_card_counts(
    reply: Response, due_count: int, done_count: int
) -> None:
    card_counts = reply_body(reply)

    assert card_counts["due"] == due_count
    assert card_counts["done"] == done_count
