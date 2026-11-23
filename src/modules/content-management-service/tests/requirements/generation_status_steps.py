from typing import cast

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
_CARD_TASK_STATUS = "/flashcards-status/{task_id}"
_QUESTION_TASK_STATUS = "/test-task-status/{task_id}"
_SIGNATURE_SEPARATOR = "."
_FORGED_SIGNATURE = "0" * 64
_CARD_TYPE = "basic"
_QUESTION_TYPE = "multiple_choice"
_STILL_RUNNING = "PENDING"
_SUCCEEDED = "SUCCESS"
_GENERATED_NOTE_ID = "6f1c7d4e-0000-4000-8000-0000000000c1"


def _checked_note_generation(
    client: TestClient, queued_import: ReplyBody, headers: dict[str, str]
) -> Response:
    task_path = _NOTE_TASK_STATUS.format(task_id=queued_import["note_task_id"])

    return client.get(task_path, headers=headers)


@given(parsers.parse("the {generation_kind} generation is still running"))
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


def _first_task_token(queued_import: ReplyBody, task_ids_key: str) -> str:
    task_tokens = cast("list[str]", queued_import[task_ids_key])

    return task_tokens[0]


def _finish_with(
    monkeypatch: pytest.MonkeyPatch, generated: dict[str, object]
) -> None:
    finished = FakeAsyncResult(_SUCCEEDED, generated, finished=True)
    monkeypatch.setattr(task_status_router, "AsyncResult", finished)


@given(
    parsers.parse(
        (
            "the card generation finished writing {card_count:d} cards "
            "into the imported deck"
        )
    )
)
def finish_card_generation(
    monkeypatch: pytest.MonkeyPatch,
    queued_import: ReplyBody,
    card_count: int,
) -> None:
    generated_cards: dict[str, object] = {
        "flashcard_deck_id": queued_import["flashcard_deck_id"],
        "type": _CARD_TYPE,
        "written": card_count,
    }
    _finish_with(monkeypatch, generated_cards)


@given(
    parsers.parse(
        (
            "the question generation finished writing {question_count:d} "
            "questions into the imported test"
        )
    )
)
def finish_question_generation(
    monkeypatch: pytest.MonkeyPatch,
    queued_import: ReplyBody,
    question_count: int,
) -> None:
    generated_questions: dict[str, object] = {
        "test_id": queued_import["test_id"],
        "type": _QUESTION_TYPE,
        "written": question_count,
    }
    _finish_with(monkeypatch, generated_questions)


@when("I check on the card generation", target_fixture="reply")
def check_card_generation(
    client: TestClient, queued_import: ReplyBody
) -> Response:
    task_token = _first_task_token(queued_import, "flashcard_task_ids")
    task_path = _CARD_TASK_STATUS.format(task_id=task_token)

    return client.get(task_path, headers=authorization())


@when("I check on the question generation", target_fixture="reply")
def check_question_generation(
    client: TestClient, queued_import: ReplyBody
) -> Response:
    task_token = _first_task_token(queued_import, "test_task_ids")
    task_path = _QUESTION_TASK_STATUS.format(task_id=task_token)

    return client.get(task_path, headers=authorization())


@then(
    parsers.parse(
        "it reports {card_count:d} cards written into the imported deck"
    )
)
def check_card_report(
    reply: Response, queued_import: ReplyBody, card_count: int
) -> None:
    card_report = reply_body(reply)

    assert card_report["status"] == _SUCCEEDED
    assert card_report["written"] == card_count
    assert (
        card_report["flashcard_deck_id"] == queued_import["flashcard_deck_id"]
    )
    assert isinstance(card_report["name"], str)


@then(
    parsers.parse(
        "it reports {question_count:d} questions written into the imported test"
    )
)
def check_question_report(
    reply: Response, queued_import: ReplyBody, question_count: int
) -> None:
    question_report = reply_body(reply)

    assert question_report["status"] == _SUCCEEDED
    assert question_report["written"] == question_count
    assert question_report["test_id"] == queued_import["test_id"]
    assert isinstance(question_report["name"], str)


@when(
    parsers.parse('I check on the generation "{task_token}"'),
    target_fixture="reply",
)
def check_made_up_generation(client: TestClient, task_token: str) -> Response:
    task_path = _NOTE_TASK_STATUS.format(task_id=task_token)

    return client.get(task_path, headers=authorization())


@when(
    "I check on the note generation with a forged signature",
    target_fixture="reply",
)
def check_forged_generation(
    client: TestClient, queued_import: ReplyBody
) -> Response:
    task_token = str(queued_import["note_task_id"])
    signed_part = task_token.rsplit(_SIGNATURE_SEPARATOR, 1)[0]
    forged_token = f"{signed_part}{_SIGNATURE_SEPARATOR}{_FORGED_SIGNATURE}"
    task_path = _NOTE_TASK_STATUS.format(task_id=forged_token)

    return client.get(task_path, headers=authorization())
