from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import parsers, then, when

from shared.models import FlashcardDeck, Test
from tests.requirements.requirement_listing import DECK_ENTRY, FOLDER_ENTRY
from tests.requirements.requirement_lookup import (
    Sessions,
    folder_id_named,
    home_folder_id,
    is_unit_named,
    unit_id_named,
)
from tests.support import authorization

_RENAME_UNIT = "/rename-unit"
_MOVE_UNIT = "/move-unit"
_DELETE_FOLDER = "/delete-folder/"
_DELETE_DECK = "/delete-deck/"
_DELETE_TEST = "/delete-test/"


def _renamed_unit(
    client: TestClient, unit_id: str, unit_type: str, new_name: str
) -> Response:
    rename_request = {
        "unit_id": unit_id,
        "unit_type": unit_type,
        "name": new_name,
    }

    return client.patch(
        _RENAME_UNIT, json=rename_request, headers=authorization()
    )


def _moved_unit(
    client: TestClient, unit_id: str, unit_type: str, destination_id: str
) -> Response:
    move_request = {
        "unit_id": unit_id,
        "unit_type": unit_type,
        "folder_id": destination_id,
    }

    return client.patch(_MOVE_UNIT, json=move_request, headers=authorization())


def _deleted(
    client: TestClient, path: str, parameter: dict[str, str]
) -> Response:
    return client.delete(path, params=parameter, headers=authorization())


@when(
    parsers.parse('I rename the folder "{folder_name}" to "{new_name}"'),
    target_fixture="reply",
)
def rename_folder(
    client: TestClient, sessions: Sessions, folder_name: str, new_name: str
) -> Response:
    folder_id = folder_id_named(sessions, folder_name)

    return _renamed_unit(client, folder_id, FOLDER_ENTRY, new_name)


@when(
    parsers.parse('I rename the deck "{deck_name}" to "{new_name}"'),
    target_fixture="reply",
)
def rename_deck(
    client: TestClient, sessions: Sessions, deck_name: str, new_name: str
) -> Response:
    deck_id = unit_id_named(sessions, FlashcardDeck, deck_name)

    return _renamed_unit(client, deck_id, DECK_ENTRY, new_name)


@when(parsers.parse('I move the deck "{deck_name}" into "{folder_name}"'))
def move_deck(
    client: TestClient, sessions: Sessions, deck_name: str, folder_name: str
) -> None:
    deck_id = unit_id_named(sessions, FlashcardDeck, deck_name)
    destination_id = folder_id_named(sessions, folder_name)
    reply = _moved_unit(client, deck_id, DECK_ENTRY, destination_id)
    _ = reply.raise_for_status()


@when(
    parsers.parse(
        'I move the folder "{folder_name}" into "{destination_name}"'
    ),
    target_fixture="reply",
)
def move_folder(
    client: TestClient,
    sessions: Sessions,
    folder_name: str,
    destination_name: str,
) -> Response:
    folder_id = folder_id_named(sessions, folder_name)
    destination_id = folder_id_named(sessions, destination_name)

    return _moved_unit(client, folder_id, FOLDER_ENTRY, destination_id)


@when(parsers.parse('I delete the folder "{folder_name}"'))
def delete_folder(
    client: TestClient, sessions: Sessions, folder_name: str
) -> None:
    folder_id = folder_id_named(sessions, folder_name)
    reply = _deleted(client, _DELETE_FOLDER, {"folder_id": folder_id})
    _ = reply.raise_for_status()


@when("I delete home", target_fixture="reply")
def delete_home(client: TestClient, sessions: Sessions) -> Response:
    home_id = home_folder_id(sessions)

    return _deleted(client, _DELETE_FOLDER, {"folder_id": home_id})


@when(parsers.parse('I delete the deck "{deck_name}"'))
def delete_deck(
    client: TestClient, sessions: Sessions, deck_name: str
) -> None:
    deck_id = unit_id_named(sessions, FlashcardDeck, deck_name)
    reply = _deleted(client, _DELETE_DECK, {"deck_id": deck_id})
    _ = reply.raise_for_status()


@when(parsers.parse('I delete the test "{test_name}"'))
def delete_test(
    client: TestClient, sessions: Sessions, test_name: str
) -> None:
    test_id = unit_id_named(sessions, Test, test_name)
    reply = _deleted(client, _DELETE_TEST, {"test_id": test_id})
    _ = reply.raise_for_status()


@then(parsers.parse('the deck "{deck_name}" does not exist'))
def check_deck_gone(sessions: Sessions, deck_name: str) -> None:
    assert not is_unit_named(sessions, FlashcardDeck, deck_name)


@then(parsers.parse('the test "{test_name}" does not exist'))
def check_test_gone(sessions: Sessions, test_name: str) -> None:
    assert not is_unit_named(sessions, Test, test_name)
