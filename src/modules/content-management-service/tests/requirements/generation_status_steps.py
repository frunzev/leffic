import pytest
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from features.study_units_generation import task_status_router
from tests.property_fakes import FakeAsyncResult
from tests.requirements.requirement_lookup import ReplyBody, reply_body
from tests.requirements.stranger_steps import stranger_headers
from tests.support import authorization

_NOTE_TASK_STATUS = "/note-task-status/{task_id}"
_STILL_RUNNING = "PENDING"
_SUCCEEDED = "SUCCESS"
_GENERATED_NOTE_ID = "6f1c7d4e-0000-4000-8000-0000000000c1"


def _checked_note_generation(
    client: TestClient, queued_import: ReplyBody, headers: dict[str, str]
) -> Response:
    task_path = _NOTE_TASK_STATUS.format(task_id=queued_import["note_task_id"])

    return client.get(task_path, headers=headers)


@given("the note generation is still running")
def keep_generation_running(monkeypatch: pytest.MonkeyPatch) -> None:
    running = FakeAsyncResult(_STILL_RUNNING, None, finished=False)
    monkeypatch.setattr(task_status_router, "AsyncResult", running)


@given(
    parsers.parse('the note generation finished with the note "{note_name}"')
)
def finish_generation(monkeypatch: pytest.MonkeyPatch, note_name: str) -> None:
    generated_note = {"note_id": _GENERATED_NOTE_ID, "note_name": note_name}
    finished = FakeAsyncResult(_SUCCEEDED, generated_note, finished=True)
    monkeypatch.setattr(task_status_router, "AsyncResult", finished)


@when("I check on the note generation", target_fixture="reply")
def check_note_generation(
    client: TestClient, queued_import: ReplyBody
) -> Response:
    return _checked_note_generation(client, queued_import, authorization())


@when("another user checks on the note generation", target_fixture="reply")
def check_note_generation_as_stranger(
    client: TestClient, queued_import: ReplyBody
) -> Response:
    return _checked_note_generation(client, queued_import, stranger_headers())


@then(parsers.parse('it is reported as "{status}"'))
def check_generation_status(reply: Response, status: str) -> None:
    assert reply_body(reply)["status"] == status


@then(parsers.parse('it reports the note "{note_name}"'))
def check_generated_note(reply: Response, note_name: str) -> None:
    generation_report = reply_body(reply)

    assert generation_report["status"] == _SUCCEEDED
    assert generation_report["name"] == note_name
