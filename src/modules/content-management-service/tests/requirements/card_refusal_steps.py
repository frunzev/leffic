from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import parsers, when

from tests.requirements.card_lookup import due_card_id
from tests.requirements.requirement_lookup import Sessions, folder_id_named
from tests.requirements.stranger_steps import stranger_headers
from tests.support import authorization

_RATING_INTERVALS = "/rating-intervals"
_REVIEW_FLASHCARD = "/review-flashcard"
_FLASHCARDS = "/flashcards"
_FLASHCARDS_STATS = "/flashcards-stats"
_RATINGS = {"Again": 1, "Hard": 2, "Good": 3, "Easy": 4}
_UNREADABLE_CARD: dict[str, object] = {
    "card_id": 1,
    "state": 1,
    "step": 0,
    "stability": None,
    "difficulty": None,
    "due": "not a date",
    "last_review": None,
}


@when(
    "I ask when an unreadable card comes back for each rating",
    target_fixture="reply",
)
def ask_unreadable_card_intervals(client: TestClient) -> Response:
    return client.post(
        _RATING_INTERVALS,
        json={"card": _UNREADABLE_CARD},
        headers=authorization(),
    )


@when(
    parsers.parse(
        'another user rates the card "{card_front}" as "{rating_name}"'
    ),
    target_fixture="reply",
)
def rate_card_as_stranger(
    client: TestClient, card_front: str, rating_name: str
) -> Response:
    review_request = {
        "flashcard_id": due_card_id(client, card_front),
        "rating": _RATINGS[rating_name],
    }

    return client.post(
        _REVIEW_FLASHCARD, json=review_request, headers=stranger_headers()
    )


@when(
    "I ask for the cards due without naming a folder", target_fixture="reply"
)
def ask_due_cards_unnamed(client: TestClient) -> Response:
    return client.get(_FLASHCARDS, headers=authorization())


@when(
    parsers.parse('I ask how many cards are due in "{folder_name}"'),
    target_fixture="reply",
)
def ask_folder_card_counts(
    client: TestClient, sessions: Sessions, folder_name: str
) -> Response:
    folder_id = folder_id_named(sessions, folder_name)

    return client.get(
        _FLASHCARDS_STATS,
        params={"folder_id": folder_id},
        headers=authorization(),
    )
