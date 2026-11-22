from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient
from pytest_bdd import given, parsers, when

from features.study_units_generation import generation_router, generation_tasks
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
_GENERATED_TEST_STEP = (
    'the AI writes the test "{test_name}" asking "{question}" '
    'with "{right_option}" right and "{wrong_option}" wrong'
)


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
    def __init__(self, ai_answer: AiAnswer) -> None:
        self._ai_answer: AiAnswer = ai_answer

    def get_ai_res(
        self, system_prompt: str, user_prompt: str
    ) -> tuple[AiAnswer, float | None]:
        _ = (system_prompt, user_prompt)

        return self._ai_answer, None


class ScriptedAiFactory:
    def __init__(self, ai_answer: AiAnswer) -> None:
        self._answerer: ScriptedAnswerer = ScriptedAnswerer(ai_answer)

    def get_ai(self, model: str | None = None) -> ScriptedAnswerer:
        _ = model

        return self._answerer


def _generate_eagerly(
    monkeypatch: pytest.MonkeyPatch, sessions: Sessions, ai_answer: AiAnswer
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

    monkeypatch.setattr(
        generation_tasks, "chosen_ai_factory", ScriptedAiFactory(ai_answer)
    )
    monkeypatch.setattr(generation_tasks, "SessionLocal", sessions)


@given(
    parsers.parse(
        'the AI writes the deck "{deck_name}" with the card "{card_front}"'
    ),
    target_fixture="ai_answer",
)
def script_generated_deck(deck_name: str, card_front: str) -> AiAnswer:
    generated_card = {"front": card_front, "back": _GENERATED_BACK}

    return {"deck_name": deck_name, "basic_flashcards": [generated_card]}


@given(parsers.parse(_GENERATED_TEST_STEP), target_fixture="ai_answer")
def script_generated_test(
    test_name: str, question: str, right_option: str, wrong_option: str
) -> AiAnswer:
    generated_question = {
        "question": question,
        "true_option": right_option,
        "false_options": [wrong_option],
    }

    return {
        "test_name": test_name,
        "multiple_choice_test_items": [generated_question],
    }


@given(
    parsers.parse('the AI writes the note "{note_name}" saying "{sentence}"'),
    target_fixture="ai_answer",
)
def script_generated_note(note_name: str, sentence: str) -> AiAnswer:
    return {"note_name": note_name, "note_content": f"<p>{sentence}</p>"}


@when(parsers.parse('I import "{text}" into home and it is generated'))
def import_and_generate(
    client: TestClient,
    sessions: Sessions,
    monkeypatch: pytest.MonkeyPatch,
    ai_answer: AiAnswer,
    text: str,
) -> None:
    _generate_eagerly(monkeypatch, sessions, ai_answer)
    reply = requested_import(client, HOME, text, ALL_STUDY_UNITS)
    _ = reply.raise_for_status()
