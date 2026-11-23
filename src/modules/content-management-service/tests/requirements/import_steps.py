import pytest
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from features.study_units_generation import generation_router
from tests.property_fakes import FakeQueuedTask
from tests.requirements.requirement_listing import (
    DECK_ENTRY,
    HOME,
    TEST_ENTRY,
    entries_of_type,
    entry_names,
)
from tests.requirements.requirement_lookup import (
    ReplyBody,
    Sessions,
    folder_id_named,
    reply_body,
)
from tests.support import authorization

GENERATION_TASKS = (
    "generate_note_task",
    "generate_flashcards_of_type_task",
    "generate_test_items_of_type_task",
)

ALL_STUDY_UNITS = ("flashcards", "note", "test")

_GENERATE_STUDY_UNITS = "/generate-study-units"
_QUEUED_TASK_ID = "queued-generation"
_BLANK_TEXT = "   "
_LINK_TEXT = "Cells are the unit of life."
_LINK_SOURCE = "link"
_STUDY_UNIT_WORDING = {
    "flashcards": "flashcards",
    "a note": "note",
    "a test": "test",
}
_IMPORT_INTO_FOLDER_STEP = (
    'I import "{text}" into "{folder_name}" asking for {wanted_units}'
)


def import_request_body(
    folder_id: str, text: str, study_units: tuple[str, ...]
) -> dict[str, object]:
    import_request: dict[str, object] = {
        "text": text,
        "folder_id": folder_id,
    }

    for study_unit in study_units:
        import_request[study_unit] = {}

    return import_request


def requested_import(
    client: TestClient,
    folder_id: str,
    text: str,
    study_units: tuple[str, ...],
) -> Response:
    import_request = import_request_body(folder_id, text, study_units)

    return client.post(
        _GENERATE_STUDY_UNITS, json=import_request, headers=authorization()
    )


def _study_units_named(wanted_units: str) -> tuple[str, ...]:
    study_units: list[str] = []

    for wording, study_unit in _STUDY_UNIT_WORDING.items():
        if wording in wanted_units:
            study_units.append(study_unit)

    return tuple(study_units)


class QueuingImporter:
    def __init__(self, client: TestClient) -> None:
        self._client: TestClient = client

    def imported(
        self, folder_id: str, text: str, study_units: tuple[str, ...]
    ) -> Response:
        return requested_import(self._client, folder_id, text, study_units)

    def imported_request(self, import_request: dict[str, object]) -> Response:
        return self._client.post(
            _GENERATE_STUDY_UNITS, json=import_request, headers=authorization()
        )


@pytest.fixture
def queuing_importer(
    client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> QueuingImporter:
    for task_name in GENERATION_TASKS:
        monkeypatch.setattr(
            generation_router, task_name, FakeQueuedTask(_QUEUED_TASK_ID)
        )

    return QueuingImporter(client)


def _unit_count(client: TestClient, folder_id: str, entry_type: str) -> int:
    return len(entry_names(client, folder_id, entry_type))


@when(parsers.parse(_IMPORT_INTO_FOLDER_STEP), target_fixture="reply")
def import_text_into_folder(
    queuing_importer: QueuingImporter,
    sessions: Sessions,
    text: str,
    folder_name: str,
    wanted_units: str,
) -> Response:
    folder_id = folder_id_named(sessions, folder_name)
    study_units = _study_units_named(wanted_units)

    return queuing_importer.imported(folder_id, text, study_units)


@when(
    parsers.parse('I import "{text}" into home asking for {wanted_units}'),
    target_fixture="reply",
)
def import_text_into_home(
    queuing_importer: QueuingImporter, text: str, wanted_units: str
) -> Response:
    study_units = _study_units_named(wanted_units)

    return queuing_importer.imported(HOME, text, study_units)


@given(
    parsers.parse('I imported "{text}" into home'),
    target_fixture="queued_import",
)
def queue_import_into_home(
    queuing_importer: QueuingImporter, text: str
) -> ReplyBody:
    reply = queuing_importer.imported(HOME, text, ALL_STUDY_UNITS)
    _ = reply.raise_for_status()

    return reply_body(reply)


@when("I import nothing into home", target_fixture="reply")
def import_nothing(queuing_importer: QueuingImporter) -> Response:
    return queuing_importer.imported(HOME, _BLANK_TEXT, ALL_STUDY_UNITS)


@then(parsers.parse('"{folder_name}" contains a new deck and a new test'))
def check_folder_has_new_units(
    client: TestClient, sessions: Sessions, folder_name: str
) -> None:
    folder_id = folder_id_named(sessions, folder_name)

    assert _unit_count(client, folder_id, DECK_ENTRY) == 1
    assert _unit_count(client, folder_id, TEST_ENTRY) == 1


@then("home contains a new deck and a new test")
def check_home_has_new_units(client: TestClient) -> None:
    assert _unit_count(client, HOME, DECK_ENTRY) == 1
    assert _unit_count(client, HOME, TEST_ENTRY) == 1


@then("home contains a new deck and no test")
def check_home_has_only_deck(client: TestClient) -> None:
    assert _unit_count(client, HOME, DECK_ENTRY) == 1
    assert _unit_count(client, HOME, TEST_ENTRY) == 0


@then("home contains no deck and no test")
def check_home_has_no_units(client: TestClient) -> None:
    assert _unit_count(client, HOME, DECK_ENTRY) == 0
    assert _unit_count(client, HOME, TEST_ENTRY) == 0


@then("a note, cards and questions are being generated")
def check_generation_queued(reply: Response) -> None:
    queued = reply_body(reply)

    assert queued["note_task_id"]
    assert queued["flashcard_task_ids"]
    assert queued["test_task_ids"]


@then("only cards are being generated")
def check_only_cards_queued(reply: Response) -> None:
    queued = reply_body(reply)

    assert queued["flashcard_task_ids"]
    assert "note_task_id" not in queued
    assert "test_task_ids" not in queued


@then("only a note is being generated")
def check_only_note_queued(reply: Response) -> None:
    queued = reply_body(reply)

    assert queued["note_task_id"]
    assert "flashcard_task_ids" not in queued
    assert "test_task_ids" not in queued


@when(
    parsers.parse(
        'I import the text of the link "{link}" into home asking for flashcards'
    )
)
def import_link_text(queuing_importer: QueuingImporter, link: str) -> None:
    import_request = import_request_body(HOME, _LINK_TEXT, ("flashcards",))
    import_request["source_kind"] = _LINK_SOURCE
    import_request["source_reference"] = link
    reply = queuing_importer.imported_request(import_request)
    _ = reply.raise_for_status()


def _deck_sources(client: TestClient) -> list[tuple[object, object]]:
    deck_sources: list[tuple[object, object]] = []

    for deck_entry in entries_of_type(client, HOME, DECK_ENTRY):
        deck_source = (
            deck_entry.get("source_kind"),
            deck_entry.get("source_reference"),
        )
        deck_sources.append(deck_source)

    return deck_sources


@then(parsers.parse('home lists a deck from the link "{link}"'))
def check_deck_from_link(client: TestClient, link: str) -> None:
    assert (_LINK_SOURCE, link) in _deck_sources(client)


@then(parsers.parse('home lists the deck "{deck_name}" without a source'))
def check_deck_without_source(client: TestClient, deck_name: str) -> None:
    for deck_entry in entries_of_type(client, HOME, DECK_ENTRY):
        if deck_entry["name"] == deck_name:
            assert "source_kind" not in deck_entry
