import json

import pytest
from claude_agent_sdk import AssistantMessage, TextBlock
from fastapi.testclient import TestClient
from httpx import Request
from openai import APIConnectionError
from pytest_bdd import given, parsers, then

from shared import chosen_ai_engine
from shared.ai_manager import AIFactory, AIManager, create_openai_factory
from shared.chosen_ai_engine import CLAUDE_CODE_ENGINE, ChosenAiFactory
from tests.account_service_fakes import FakeAccountService
from tests.claude_code_fakes import ScriptedQuery, result_message
from tests.openai_fakes import FakeClient, FakeResponse, FakeUsage, as_openai
from tests.requirements.requirement_listing import (
    HOME,
    NOTE_ENTRY,
    entry_names,
)

_OPENAI_URL = "https://api.openai.com/v1/responses"
_THINKING = "Reading the text first."
_CLAUDE_MODEL = "claude"
_TOKEN_STEP = (
    'OpenAI writes the note "{note_name}" saying "{sentence}" using '
    "{input_tokens:d} input tokens, {cached_tokens:d} of them cached, "
    "and {output_tokens:d} output tokens"
)


class FakeOpenAiGeneration:
    def __init__(self, answers: list[object]) -> None:
        self.client: FakeClient = FakeClient(answers)
        self._factory: AIFactory = create_openai_factory(
            as_openai(self.client)
        )

    def get_ai(self, model: str | None = None) -> AIManager:
        return self._factory.get_ai(model)


def _note_text(note_name: str, sentence: str) -> str:
    generated_note = {
        "note_name": note_name,
        "note_content": f"<p>{sentence}</p>",
    }

    return json.dumps(generated_note)


def _unreachable_openai() -> APIConnectionError:
    return APIConnectionError(request=Request("POST", _OPENAI_URL))


@given(parsers.parse(_TOKEN_STEP), target_fixture="generation_ai")
def script_tokened_note(
    account_service: FakeAccountService,
    note_name: str,
    sentence: str,
    input_tokens: int,
    cached_tokens: int,
    output_tokens: int,
) -> FakeOpenAiGeneration:
    _ = account_service
    usage = FakeUsage(input_tokens, output_tokens, cached_tokens)
    answer = FakeResponse(_note_text(note_name, sentence), usage)

    return FakeOpenAiGeneration([answer])


@given(
    parsers.parse(
        (
            'OpenAI wraps the note "{note_name}" saying "{sentence}" '
            "in other words"
        )
    ),
    target_fixture="generation_ai",
)
def script_wrapped_note(note_name: str, sentence: str) -> FakeOpenAiGeneration:
    wrapped_text = (
        f"Here is your note:\n{_note_text(note_name, sentence)}\nEnjoy!"
    )

    return FakeOpenAiGeneration([FakeResponse(wrapped_text)])


@given(
    parsers.parse(
        (
            'OpenAI fails once and then writes the note "{note_name}" '
            'saying "{sentence}"'
        )
    ),
    target_fixture="generation_ai",
)
def script_note_after_failure(
    note_name: str, sentence: str
) -> FakeOpenAiGeneration:
    answer = FakeResponse(_note_text(note_name, sentence))

    return FakeOpenAiGeneration([_unreachable_openai(), answer])


@given("OpenAI fails every time", target_fixture="generation_ai")
def script_failing_openai() -> FakeOpenAiGeneration:
    return FakeOpenAiGeneration([_unreachable_openai(), _unreachable_openai()])


@given(
    parsers.parse('OpenAI answers the import with "{answer_text}"'),
    target_fixture="generation_ai",
)
def script_plain_answer(answer_text: str) -> FakeOpenAiGeneration:
    return FakeOpenAiGeneration([FakeResponse(answer_text)])


@given(
    parsers.parse(
        (
            'Claude Code is the chosen engine and writes the note "{note_name}" '
            'saying "{sentence}"'
        )
    ),
    target_fixture="generation_ai",
)
def script_claude_code_note(
    monkeypatch: pytest.MonkeyPatch, note_name: str, sentence: str
) -> ChosenAiFactory:
    thinking = AssistantMessage(
        content=[TextBlock(text=_THINKING)], model=_CLAUDE_MODEL
    )
    final_answer = result_message(
        _note_text(note_name, sentence), is_error=False
    )
    monkeypatch.setattr(
        chosen_ai_engine, "query", ScriptedQuery([thinking, final_answer])
    )

    return ChosenAiFactory(CLAUDE_CODE_ENGINE)


@given(
    "Claude Code is the chosen engine and returns no text",
    target_fixture="generation_ai",
)
def script_silent_claude_code(
    monkeypatch: pytest.MonkeyPatch,
) -> ChosenAiFactory:
    silent_answer = result_message(None, is_error=False)
    monkeypatch.setattr(
        chosen_ai_engine, "query", ScriptedQuery([silent_answer])
    )

    return ChosenAiFactory(CLAUDE_CODE_ENGINE)


@then(parsers.parse("OpenAI was asked {request_count:d} times"))
def check_openai_requests(
    generation_ai: FakeOpenAiGeneration, request_count: int
) -> None:
    assert len(generation_ai.client.responses.calls) == request_count


@then("home contains no note")
def check_home_has_no_note(client: TestClient) -> None:
    assert entry_names(client, HOME, NOTE_ENTRY) == []


@then("no OpenAI spending was recorded for me")
def check_nothing_recorded(account_service: FakeAccountService) -> None:
    assert account_service.recorded == []
