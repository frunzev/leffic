from collections.abc import Callable
from dataclasses import dataclass

import pytest
from fastapi.testclient import TestClient
from pytest_bdd import given, parsers, when

from features.study_units_generation import generation_router, generation_tasks
from tests.account_service_fakes import FakeAccountService
from tests.requirements.import_steps import (
    ALL_STUDY_UNITS,
    requested_import,
)
from tests.requirements.requirement_listing import HOME
from tests.requirements.requirement_lookup import Sessions

AiAnswer = dict[str, object]
TaskRunner = Callable[..., dict[str, object]]

_FINISHED_TASK_ID = "finished-generation"
_GENERATED_BACK = "A generated answer."
_NOTE_ONLY = ("note",)
_GENERATED_NOTE_STEP = (
    'the AI writes the note "{note_name}" saying "{sentence}"'
)
_PRICED_NOTE_STEP = _GENERATED_NOTE_STEP + " for {dollars:f} dollars"
_GENERATED_TEST_STEP = (
    'the AI writes the test "{test_name}" asking "{question}" '
    'with "{right_option}" right and "{wrong_option}" wrong'
)


@dataclass(frozen=True)
class ScriptedGeneration:
    ai_answer: AiAnswer
    dollars: float | None


class FinishedTask:
    def __init__(self, task_id: str) -> None:
        self.id: str = task_id


class EagerTask:
    def __init__(self, run_task: TaskRunner) -> None:
        self._run_task: TaskRunner = run_task

    def delay(self, **task_arguments: object) -> FinishedTask:
        _ = self._run_task(**task_arguments)

        return FinishedTask(_FINISHED_TASK_ID)


class ScriptedAnswerer:
    def __init__(self, scripted_generation: ScriptedGeneration) -> None:
        self._scripted_generation: ScriptedGeneration = scripted_generation

    def get_ai_res(
        self, system_prompt: str, user_prompt: str
    ) -> tuple[AiAnswer, float | None]:
        _ = (system_prompt, user_prompt)
        scripted = self._scripted_generation

        return scripted.ai_answer, scripted.dollars


class ScriptedAiFactory:
    def __init__(self, scripted_generation: ScriptedGeneration) -> None:
        self._answerer: ScriptedAnswerer = ScriptedAnswerer(
            scripted_generation
        )

    def get_ai(self, model: str | None = None) -> ScriptedAnswerer:
        _ = model

        return self._answerer


def _generate_eagerly(
    monkeypatch: pytest.MonkeyPatch,
    sessions: Sessions,
    scripted_generation: ScriptedGeneration,
) -> None:
    eager_tasks = {
        "generate_note_task": EagerTask(generation_tasks._generate_note_task),
        "generate_flashcards_of_type_task": EagerTask(
            generation_tasks._generate_flashcards_of_type_task
        ),
        "generate_test_items_of_type_task": EagerTask(
            generation_tasks._generate_test_items_of_type_task
        ),
    }

    for task_name, eager_task in eager_tasks.items():
        monkeypatch.setattr(generation_router, task_name, eager_task)

    scripted_factory = ScriptedAiFactory(scripted_generation)
    monkeypatch.setattr(
        generation_tasks, "chosen_ai_factory", scripted_factory
    )
    monkeypatch.setattr(generation_tasks, "SessionLocal", sessions)


@given(
    parsers.parse(
        'the AI writes the deck "{deck_name}" with the card "{card_front}"'
    ),
    target_fixture="scripted_generation",
)
def script_generated_deck(
    deck_name: str, card_front: str
) -> ScriptedGeneration:
    generated_card = {"front": card_front, "back": _GENERATED_BACK}
    ai_answer: AiAnswer = {
        "deck_name": deck_name,
        "basic_flashcards": [generated_card],
    }

    return ScriptedGeneration(ai_answer=ai_answer, dollars=None)


@given(
    parsers.parse(_GENERATED_TEST_STEP),
    target_fixture="scripted_generation",
)
def script_generated_test(
    test_name: str, question: str, right_option: str, wrong_option: str
) -> ScriptedGeneration:
    generated_question = {
        "question": question,
        "true_option": right_option,
        "false_options": [wrong_option],
    }

    ai_answer: AiAnswer = {
        "test_name": test_name,
        "multiple_choice_test_items": [generated_question],
    }

    return ScriptedGeneration(ai_answer=ai_answer, dollars=None)


def _generated_note(note_name: str, sentence: str) -> AiAnswer:
    return {"note_name": note_name, "note_content": f"<p>{sentence}</p>"}


@given(
    parsers.parse(_GENERATED_NOTE_STEP),
    target_fixture="scripted_generation",
)
def script_generated_note(note_name: str, sentence: str) -> ScriptedGeneration:
    ai_answer = _generated_note(note_name, sentence)

    return ScriptedGeneration(ai_answer=ai_answer, dollars=None)


@given(
    parsers.parse(_PRICED_NOTE_STEP),
    target_fixture="scripted_generation",
)
def script_priced_note(
    account_service: FakeAccountService,
    note_name: str,
    sentence: str,
    dollars: float,
) -> ScriptedGeneration:
    _ = account_service
    ai_answer = _generated_note(note_name, sentence)

    return ScriptedGeneration(ai_answer=ai_answer, dollars=dollars)


def _import_eagerly(
    client: TestClient,
    text: str,
    study_units: tuple[str, ...],
) -> None:
    reply = requested_import(client, HOME, text, study_units)
    _ = reply.raise_for_status()


@when(parsers.parse('I import "{text}" into home and it is generated'))
def import_and_generate(
    client: TestClient,
    sessions: Sessions,
    monkeypatch: pytest.MonkeyPatch,
    scripted_generation: ScriptedGeneration,
    text: str,
) -> None:
    _generate_eagerly(monkeypatch, sessions, scripted_generation)
    _import_eagerly(client, text, ALL_STUDY_UNITS)


@when(
    parsers.parse('I import "{text}" into home and only a note is generated')
)
def import_and_generate_note(
    client: TestClient,
    sessions: Sessions,
    monkeypatch: pytest.MonkeyPatch,
    scripted_generation: ScriptedGeneration,
    text: str,
) -> None:
    _generate_eagerly(monkeypatch, sessions, scripted_generation)
    _import_eagerly(client, text, _NOTE_ONLY)
