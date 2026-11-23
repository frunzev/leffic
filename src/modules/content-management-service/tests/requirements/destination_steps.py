import uuid
from typing import cast

import pytest
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import parsers, then, when

from features.study_units_generation import generation_router, generation_tasks
from features.study_units_generation.assessment_writer import MissingTestError
from features.study_units_generation.flashcard_deck_writer import (
    MissingDeckError,
)
from features.study_units_generation.generation_tasks import (
    FlashcardGenerationSettings,
    GenerationRequester,
)
from features.study_units_generation.study_unit_writer import (
    MissingFolderError,
)
from tests.property_fakes import RecordingQueuedTask
from tests.requirements.eager_generation import GenerationAi, generate_eagerly
from tests.requirements.requirement_listing import HOME
from tests.requirements.requirement_lookup import Sessions
from tests.support import USER_ID, authorization

_EXTRACTED_TEXT = "Cells are the unit of life."
_CARD_TYPE = "basic"
_QUESTION_TYPE = "multiple_choice"
_QUESTION_AMOUNT = 5
_GENERATE_STUDY_UNITS = "/generate-study-units"
_QUEUED_TASK_ID = "queued-generation"
_REQUESTER = GenerationRequester(user_id=USER_ID, ai_model=None)
_SETTINGS = FlashcardGenerationSettings(
    comprehensiveness="medium", verbosity="low", amount=None
)

JobSettings = dict[str, object]


def _deleted_id() -> str:
    return str(uuid.uuid4())


@when(
    "the card generation finishes for a deck that was deleted meanwhile",
    target_fixture="generation_failure",
)
def finish_cards_for_deleted_deck(
    monkeypatch: pytest.MonkeyPatch,
    sessions: Sessions,
    generation_ai: GenerationAi,
) -> str:
    generate_eagerly(monkeypatch, sessions, generation_ai)

    with pytest.raises(MissingDeckError) as refused:
        _ = generation_tasks._generate_flashcards_of_type_task(
            requester=_REQUESTER,
            extracted_text=_EXTRACTED_TEXT,
            deck_id=_deleted_id(),
            flashcard_type=_CARD_TYPE,
            settings=_SETTINGS,
        )

    return str(refused.value)


@when(
    "the question generation finishes for a test that was deleted meanwhile",
    target_fixture="generation_failure",
)
def finish_questions_for_deleted_test(
    monkeypatch: pytest.MonkeyPatch,
    sessions: Sessions,
    generation_ai: GenerationAi,
) -> str:
    generate_eagerly(monkeypatch, sessions, generation_ai)

    with pytest.raises(MissingTestError) as refused:
        _ = generation_tasks._generate_test_items_of_type_task(
            requester=_REQUESTER,
            extracted_text=_EXTRACTED_TEXT,
            test_id=_deleted_id(),
            item_type=_QUESTION_TYPE,
            amount=_QUESTION_AMOUNT,
        )

    return str(refused.value)


@when(
    "the note generation finishes for a folder that was deleted meanwhile",
    target_fixture="generation_failure",
)
def finish_note_for_deleted_folder(
    monkeypatch: pytest.MonkeyPatch,
    sessions: Sessions,
    generation_ai: GenerationAi,
) -> str:
    generate_eagerly(monkeypatch, sessions, generation_ai)

    with pytest.raises(MissingFolderError) as refused:
        _ = generation_tasks._generate_note_task(
            requester=_REQUESTER,
            extracted_text=_EXTRACTED_TEXT,
            folder_id=_deleted_id(),
            source_kind=None,
            source_reference=None,
        )

    return str(refused.value)


@then(parsers.parse('the generation fails because "{reason}"'))
def check_generation_failure(generation_failure: str, reason: str) -> None:
    assert generation_failure == reason


def _card_import(
    client: TestClient, text: str, amounts: dict[str, int]
) -> Response:
    import_request: dict[str, object] = {
        "text": text,
        "folder_id": HOME,
        "flashcards": {"types": [_CARD_TYPE], "amounts": amounts},
    }

    return client.post(
        _GENERATE_STUDY_UNITS, json=import_request, headers=authorization()
    )


@when(
    parsers.parse(
        'I import "{text}" into home asking for {amount:d} basic cards'
    ),
    target_fixture="card_jobs",
)
def import_counted_cards(
    client: TestClient, monkeypatch: pytest.MonkeyPatch, text: str, amount: int
) -> RecordingQueuedTask:
    card_jobs = RecordingQueuedTask(_QUEUED_TASK_ID)
    monkeypatch.setattr(
        generation_router, "generate_flashcards_of_type_task", card_jobs
    )
    reply = _card_import(client, text, {_CARD_TYPE: amount})
    _ = reply.raise_for_status()

    return card_jobs


@when(
    parsers.parse(
        (
            'I import "{text}" into home asking for basic cards '
            "but {amount:d} cloze cards"
        )
    ),
    target_fixture="reply",
)
def import_unasked_amount(
    client: TestClient, text: str, amount: int
) -> Response:
    return _card_import(client, text, {"cloze": amount})


@then(parsers.parse("the basic cards are asked for {amount:d} at a time"))
def check_card_amount(card_jobs: RecordingQueuedTask, amount: int) -> None:
    queued_job = card_jobs.calls[0]
    job_settings = cast("JobSettings", queued_job["settings"])

    assert queued_job["flashcard_type"] == _CARD_TYPE
    assert job_settings["amount"] == amount
