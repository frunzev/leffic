from typing import cast

from fastapi.testclient import TestClient
from httpx import Response

from tests.requirements.requirement_lookup import reply_body
from tests.support import authorization

HOME = "home"
FOLDER_ENTRY = "folder"
DECK_ENTRY = "flashcard_deck"
TEST_ENTRY = "test"
FILE_ENTRY = "file"
NOTE_ENTRY = "note"

_ACCESS_FOLDER = "/access-folder/"

FolderEntry = dict[str, object]


def opened_folder(
    client: TestClient, folder_id: str, headers: dict[str, str]
) -> Response:
    return client.get(
        _ACCESS_FOLDER, params={"folder_id": folder_id}, headers=headers
    )


def entries_of_type(
    client: TestClient, folder_id: str, entry_type: str
) -> list[FolderEntry]:
    listing = reply_body(opened_folder(client, folder_id, authorization()))
    entries = cast("list[FolderEntry]", listing["content"])
    matching_entries: list[FolderEntry] = []

    for entry in entries:
        if entry["type"] == entry_type:
            matching_entries.append(entry)

    return matching_entries


def entry_names(
    client: TestClient, folder_id: str, entry_type: str
) -> list[str]:
    names: list[str] = []

    for entry in entries_of_type(client, folder_id, entry_type):
        names.append(str(entry["name"]))

    return names
