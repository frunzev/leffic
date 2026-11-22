from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from shared.models import FlashcardDeck, Note
from tests.requirements.folder_steps import created_folder
from tests.requirements.requirement_listing import HOME, opened_folder
from tests.requirements.requirement_lookup import (
    Sessions,
    folder_id_named,
    is_folder_named,
    stranger_home_folder_id,
    unit_id_named,
)
from tests.requirements.requirement_seeding import (
    NOTE_BODY,
    seeded_deck,
    seeded_note,
)
from tests.support import OTHER_USER_ID, authorization

_DELETE_FOLDER = "/delete-folder/"
_NOTE = "/note"
_FLASHCARDS = "/flashcards"
_STRANGER_CARD = "A card nobody else may see"


def stranger_headers() -> dict[str, str]:
    return authorization(OTHER_USER_ID)


@when("another user opens home", target_fixture="reply")
def open_home_as_stranger(client: TestClient) -> Response:
    return opened_folder(client, HOME, stranger_headers())


@when(
    parsers.parse('another user deletes the folder "{folder_name}"'),
    target_fixture="reply",
)
def delete_folder_as_stranger(
    client: TestClient, sessions: Sessions, folder_name: str
) -> Response:
    folder_id = folder_id_named(sessions, folder_name)

    return client.delete(
        _DELETE_FOLDER,
        params={"folder_id": folder_id},
        headers=stranger_headers(),
    )


@when(
    parsers.parse('another user opens the note "{note_name}"'),
    target_fixture="reply",
)
def open_note_as_stranger(
    client: TestClient, sessions: Sessions, note_name: str
) -> Response:
    note_id = unit_id_named(sessions, Note, note_name)

    return client.get(
        _NOTE, params={"note_id": note_id}, headers=stranger_headers()
    )


@when(
    parsers.parse(
        'another user asks for the cards due in the deck "{deck_name}"'
    ),
    target_fixture="reply",
)
def ask_due_cards_as_stranger(
    client: TestClient, sessions: Sessions, deck_name: str
) -> Response:
    deck_id = unit_id_named(sessions, FlashcardDeck, deck_name)

    return client.get(
        _FLASHCARDS,
        params={"flashcard_deck_id": deck_id},
        headers=stranger_headers(),
    )


@given(parsers.parse('another user has the folder "{folder_name}"'))
def create_stranger_folder(client: TestClient, folder_name: str) -> None:
    created_folder(client, HOME, folder_name, stranger_headers())


@given(parsers.parse('another user has the note "{note_name}"'))
def create_stranger_note(sessions: Sessions, note_name: str) -> None:
    home_id = stranger_home_folder_id(sessions)
    seeded_note(sessions, home_id, note_name, NOTE_BODY)


@given(parsers.parse('another user has the deck "{deck_name}"'))
def create_stranger_deck(sessions: Sessions, deck_name: str) -> None:
    home_id = stranger_home_folder_id(sessions)
    seeded_deck(sessions, home_id, deck_name, _STRANGER_CARD)


@then(parsers.parse('another user still has the folder "{folder_name}"'))
def check_stranger_folder_kept(sessions: Sessions, folder_name: str) -> None:
    assert is_folder_named(sessions, folder_name, OTHER_USER_ID)
