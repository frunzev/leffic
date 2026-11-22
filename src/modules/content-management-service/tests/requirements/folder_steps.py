from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from tests.requirements.requirement_listing import (
    DECK_ENTRY,
    FOLDER_ENTRY,
    HOME,
    NOTE_ENTRY,
    entry_names,
    opened_folder,
)
from tests.requirements.requirement_lookup import (
    Sessions,
    folder_id_named,
    is_folder_named,
    reply_body,
)
from tests.support import USER_ID, authorization

_CREATE_FOLDER = "/create-folder"


def created_folder(
    client: TestClient,
    parent_folder_id: str,
    folder_name: str,
    headers: dict[str, str],
) -> None:
    folder_request = {
        "parent_folder_id": parent_folder_id,
        "folder_name": folder_name,
    }
    reply = client.post(_CREATE_FOLDER, json=folder_request, headers=headers)
    _ = reply.raise_for_status()


@when("I open home", target_fixture="reply")
@given("I opened home")
def open_home(client: TestClient) -> Response:
    return opened_folder(client, HOME, authorization())


@then(parsers.parse('I see the folder "{folder_name}"'))
def check_folder_shown(reply: Response, folder_name: str) -> None:
    assert reply_body(reply)["parent_folder_name"] == folder_name


@then("it is empty")
def check_folder_empty(reply: Response) -> None:
    assert reply_body(reply)["content"] == []


@given(parsers.parse('I have the folder "{folder_name}" in home'))
@when(parsers.parse('I create the folder "{folder_name}" in home'))
def create_folder_in_home(client: TestClient, folder_name: str) -> None:
    created_folder(client, HOME, folder_name, authorization())


@given(parsers.parse('I have the folder "{folder_name}" in "{parent_name}"'))
@when(parsers.parse('I create the folder "{folder_name}" in "{parent_name}"'))
def create_folder_in_parent(
    client: TestClient, sessions: Sessions, folder_name: str, parent_name: str
) -> None:
    parent_id = folder_id_named(sessions, parent_name)
    created_folder(client, parent_id, folder_name, authorization())


@then(parsers.parse('"{parent_name}" contains the folder "{folder_name}"'))
def check_parent_has_folder(
    client: TestClient, sessions: Sessions, parent_name: str, folder_name: str
) -> None:
    parent_id = folder_id_named(sessions, parent_name)

    assert folder_name in entry_names(client, parent_id, FOLDER_ENTRY)


@then(parsers.parse('"{folder_name}" contains the deck "{deck_name}"'))
def check_folder_has_deck(
    client: TestClient, sessions: Sessions, folder_name: str, deck_name: str
) -> None:
    folder_id = folder_id_named(sessions, folder_name)

    assert deck_name in entry_names(client, folder_id, DECK_ENTRY)


@then(parsers.parse('home contains the folder "{folder_name}"'))
def check_home_has_folder(client: TestClient, folder_name: str) -> None:
    assert folder_name in entry_names(client, HOME, FOLDER_ENTRY)


@then(
    parsers.parse(
        'home contains the folders "{first_name}" and "{second_name}"'
    )
)
def check_home_has_folders(
    client: TestClient, first_name: str, second_name: str
) -> None:
    folder_names = entry_names(client, HOME, FOLDER_ENTRY)

    assert sorted(folder_names) == sorted([first_name, second_name])


@then(parsers.parse('home contains the deck "{deck_name}"'))
def check_home_has_deck(client: TestClient, deck_name: str) -> None:
    assert deck_name in entry_names(client, HOME, DECK_ENTRY)


@then(parsers.parse('home contains the note "{note_name}"'))
def check_home_has_note(client: TestClient, note_name: str) -> None:
    assert note_name in entry_names(client, HOME, NOTE_ENTRY)


@then(parsers.parse('the folder "{folder_name}" does not exist'))
def check_folder_gone(sessions: Sessions, folder_name: str) -> None:
    assert not is_folder_named(sessions, folder_name, USER_ID)
