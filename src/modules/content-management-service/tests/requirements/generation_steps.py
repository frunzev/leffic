from dataclasses import dataclass

import pytest
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, when

from tests.account_service_fakes import FakeAccountService
from tests.requirements.eager_generation import GenerationAi, generate_eagerly
from tests.requirements.import_steps import (
    ALL_STUDY_UNITS,
    import_request_body,
    requested_import,
)
from tests.requirements.requirement_listing import HOME
from tests.requirements.requirement_lookup import Sessions
from tests.support import authorization

AiAnswer = dict[str, object]

_GENERATED_BACK = "A generated answer."
_NOTE_ONLY = ("note",)
_GENERATE_STUDY_UNITS = "/generate-study-units"
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


@given(
    parsers.parse(
        'the AI writes the deck "{deck_name}" with the card "{card_front}"'
    ),
    target_fixture="generation_ai",
)
def script_generated_deck(
    deck_name: str, card_front: str
) -> ScriptedAiFactory:
    generated_card = {"front": card_front, "back": _GENERATED_BACK}
    ai_answer: AiAnswer = {
        "deck_name": deck_name,
        "basic_flashcards": [generated_card],
    }

    return ScriptedAiFactory(ScriptedGeneration(ai_answer, None))


@given(
    parsers.parse(_GENERATED_TEST_STEP),
    target_fixture="generation_ai",
)
def script_generated_test(
    test_name: str, question: str, right_option: str, wrong_option: str
) -> ScriptedAiFactory:
    generated_question = {
        "question": question,
        "true_option": right_option,
        "false_options": [wrong_option],
    }

    ai_answer: AiAnswer = {
        "test_name": test_name,
        "multiple_choice_test_items": [generated_question],
    }

    return ScriptedAiFactory(ScriptedGeneration(ai_answer, None))


def _generated_note(note_name: str, sentence: str) -> AiAnswer:
    return {"note_name": note_name, "note_content": f"<p>{sentence}</p>"}


@given(
    parsers.parse(_GENERATED_NOTE_STEP),
    target_fixture="generation_ai",
)
def script_generated_note(note_name: str, sentence: str) -> ScriptedAiFactory:
    ai_answer = _generated_note(note_name, sentence)

    return ScriptedAiFactory(ScriptedGeneration(ai_answer, None))


@given(
    parsers.parse(_PRICED_NOTE_STEP),
    target_fixture="generation_ai",
)
def script_priced_note(
    account_service: FakeAccountService,
    note_name: str,
    sentence: str,
    dollars: float,
) -> ScriptedAiFactory:
    _ = account_service
    ai_answer = _generated_note(note_name, sentence)

    return ScriptedAiFactory(ScriptedGeneration(ai_answer, dollars))


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
    generation_ai: GenerationAi,
    text: str,
) -> None:
    generate_eagerly(monkeypatch, sessions, generation_ai)
    _import_eagerly(client, text, ALL_STUDY_UNITS)


@when(
    parsers.parse('I import "{text}" into home and only a note is generated')
)
def import_and_generate_note(
    client: TestClient,
    sessions: Sessions,
    monkeypatch: pytest.MonkeyPatch,
    generation_ai: GenerationAi,
    text: str,
) -> None:
    generate_eagerly(monkeypatch, sessions, generation_ai)
    _import_eagerly(client, text, _NOTE_ONLY)


@when(
    parsers.parse(
        (
            'I import "{text}" into home with the model "{model}" '
            "and only a note is generated"
        )
    )
)
def import_note_with_model(
    client: TestClient,
    sessions: Sessions,
    monkeypatch: pytest.MonkeyPatch,
    generation_ai: GenerationAi,
    text: str,
    model: str,
) -> None:
    generate_eagerly(monkeypatch, sessions, generation_ai)
    import_request = import_request_body(HOME, text, _NOTE_ONLY)
    import_request["ai_model"] = model
    reply = client.post(
        _GENERATE_STUDY_UNITS, json=import_request, headers=authorization()
    )
    _ = reply.raise_for_status()


@when(
    parsers.parse('I import "{text}" into home and the note generation fails'),
    target_fixture="reply",
)
def import_note_that_fails(
    client: TestClient,
    sessions: Sessions,
    monkeypatch: pytest.MonkeyPatch,
    generation_ai: GenerationAi,
    text: str,
) -> Response:
    generate_eagerly(monkeypatch, sessions, generation_ai)

    return requested_import(client, HOME, text, _NOTE_ONLY)
