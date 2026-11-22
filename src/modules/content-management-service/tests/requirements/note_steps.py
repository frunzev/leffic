from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from shared.models import Note
from tests.requirements.requirement_listing import (
    HOME,
    NOTE_ENTRY,
    entries_of_type,
)
from tests.requirements.requirement_lookup import (
    Sessions,
    folder_id_named,
    home_folder_id,
    is_unit_named,
    reply_body,
    unit_id_named,
)
from tests.requirements.requirement_seeding import NOTE_BODY, seeded_note
from tests.support import authorization

_NOTE = "/note"
_REVIEW_NOTE = "/review-note"
_DELETE_NOTE = "/delete-note/"
_NOTES_STATS = "/notes-stats"
_FILLER_WORD = "cell"


def _opened_note(
    client: TestClient, sessions: Sessions, note_name: str
) -> Response:
    note_id = unit_id_named(sessions, Note, note_name)

    return client.get(
        _NOTE, params={"note_id": note_id}, headers=authorization()
    )


@given(parsers.parse('I have the note "{note_name}" in home'))
def create_note_in_home(sessions: Sessions, note_name: str) -> None:
    seeded_note(sessions, home_folder_id(sessions), note_name, NOTE_BODY)


@given(parsers.parse('I have the note "{note_name}" in "{folder_name}"'))
def create_note_in_folder(
    sessions: Sessions, note_name: str, folder_name: str
) -> None:
    folder_id = folder_id_named(sessions, folder_name)
    seeded_note(sessions, folder_id, note_name, NOTE_BODY)


@given(
    parsers.parse(
        'I have the note "{note_name}" of {word_count:d} words in home'
    )
)
def create_long_note_in_home(
    sessions: Sessions, note_name: str, word_count: int
) -> None:
    filler_words = [_FILLER_WORD] * word_count
    note_body = f"<p>{' '.join(filler_words)}</p>"
    seeded_note(sessions, home_folder_id(sessions), note_name, note_body)


@when(parsers.parse('I mark the note "{note_name}" as read'))
@given(parsers.parse('I marked the note "{note_name}" as read'))
def mark_note_read(
    client: TestClient, sessions: Sessions, note_name: str
) -> None:
    opened = _opened_note(client, sessions, note_name)
    _ = opened.raise_for_status()

    note_id = unit_id_named(sessions, Note, note_name)
    reviewed = client.post(
        _REVIEW_NOTE, json={"note_id": note_id}, headers=authorization()
    )
    _ = reviewed.raise_for_status()


@then(parsers.parse('the note "{note_name}" is read'))
def check_note_read(
    client: TestClient, sessions: Sessions, note_name: str
) -> None:
    reply = _opened_note(client, sessions, note_name)

    assert reply_body(reply)["read"] is True


@then(parsers.parse('the note "{note_name}" is not read yet'))
def check_note_unread(
    client: TestClient, sessions: Sessions, note_name: str
) -> None:
    reply = _opened_note(client, sessions, note_name)

    assert reply_body(reply)["read"] is False


@then(
    parsers.parse(
        'home lists the note "{note_name}" as a {minutes:d}-minute read'
    )
)
def check_reading_minutes(
    client: TestClient, note_name: str, minutes: int
) -> None:
    reading_minutes_by_note: dict[str, object] = {}

    for entry in entries_of_type(client, HOME, NOTE_ENTRY):
        reading_minutes_by_note[str(entry["name"])] = entry["reading_minutes"]

    assert reading_minutes_by_note[note_name] == minutes


@when("I ask how many notes are read in home", target_fixture="reply")
def ask_note_counts(client: TestClient) -> Response:
    return client.get(
        _NOTES_STATS, params={"folder_id": HOME}, headers=authorization()
    )


@then(
    parsers.parse(
        "home has {unread_count:d} note unread and {read_count:d} read"
    )
)
def check_note_counts(
    reply: Response, unread_count: int, read_count: int
) -> None:
    note_counts = reply_body(reply)

    assert note_counts["due"] == unread_count
    assert note_counts["read"] == read_count


@when(parsers.parse('I delete the note "{note_name}"'))
def delete_note(
    client: TestClient, sessions: Sessions, note_name: str
) -> None:
    note_id = unit_id_named(sessions, Note, note_name)
    reply = client.delete(
        _DELETE_NOTE, params={"note_id": note_id}, headers=authorization()
    )
    _ = reply.raise_for_status()


@then(parsers.parse('the note "{note_name}" does not exist'))
def check_note_gone(sessions: Sessions, note_name: str) -> None:
    assert not is_unit_named(sessions, Note, note_name)
