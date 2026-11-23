from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import parsers, when

from shared.models import FlashcardDeck
from tests.requirements.requirement_lookup import (
    Sessions,
    folder_id_named,
    unit_id_named,
)
from tests.requirements.stranger_steps import stranger_headers
from tests.support import authorization

_CREATE_FOLDER = "/create-folder"
_ACCESS_FOLDER = "/access-folder/"
_RENAME_UNIT = "/rename-unit"
_NOTE = "/note"
_GENERATE_STUDY_UNITS = "/generate-study-units"


@when(
    parsers.parse('I create the folder "{folder_name}" without a parent'),
    target_fixture="reply",
)
def create_folder_without_parent(
    client: TestClient, folder_name: str
) -> Response:
    folder_request = {"name": folder_name, "parent_folder_id": None}

    return client.post(
        _CREATE_FOLDER, json=folder_request, headers=authorization()
    )


@when("I open a folder without naming it", target_fixture="reply")
def open_unnamed_folder(client: TestClient) -> Response:
    return client.get(_ACCESS_FOLDER, headers=authorization())


@when(
    parsers.parse('I open the folder with the id "{folder_id}"'),
    target_fixture="reply",
)
def open_folder_by_id(client: TestClient, folder_id: str) -> Response:
    return client.get(
        _ACCESS_FOLDER,
        params={"folder_id": folder_id},
        headers=authorization(),
    )


@when(
    parsers.parse(
        'I rename the deck "{deck_name}" as a "{unit_type}" to "{new_name}"'
    ),
    target_fixture="reply",
)
def rename_deck_as(
    client: TestClient,
    sessions: Sessions,
    deck_name: str,
    unit_type: str,
    new_name: str,
) -> Response:
    rename_request = {
        "unit_id": unit_id_named(sessions, FlashcardDeck, deck_name),
        "unit_type": unit_type,
        "name": new_name,
    }

    return client.patch(
        _RENAME_UNIT, json=rename_request, headers=authorization()
    )


@when(
    parsers.parse('I open the note with the id "{note_id}"'),
    target_fixture="reply",
)
def open_note_by_id(client: TestClient, note_id: str) -> Response:
    return client.get(
        _NOTE, params={"note_id": note_id}, headers=authorization()
    )


@when(
    parsers.parse(
        'another user imports "{text}" into the folder "{folder_name}"'
    ),
    target_fixture="reply",
)
def import_as_stranger(
    client: TestClient, sessions: Sessions, text: str, folder_name: str
) -> Response:
    import_request: dict[str, object] = {
        "text": text,
        "folder_id": folder_id_named(sessions, folder_name),
        "note": {},
    }

    return client.post(
        _GENERATE_STUDY_UNITS, json=import_request, headers=stranger_headers()
    )
