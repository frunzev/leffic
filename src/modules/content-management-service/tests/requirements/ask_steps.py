import pytest
from claude_agent_sdk import Message
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from features.chatbot import chatbot
from shared.chosen_ai_engine import CLAUDE_CODE_ENGINE
from tests.claude_code_fakes import (
    MissingClaudeCode,
    ScriptedQuery,
    result_message,
)
from tests.requirements.requirement_lookup import Sessions, reply_body
from tests.support import authorization

_CHAT = "/chat"
_USER_ROLE = "user"
_ASSISTANT_ROLE = "assistant"
_EARLIER_ANSWER = "An earlier answer."
_TWO_QUESTIONS_STEP = (
    'I ask two questions, "{first_question}" then "{second_question}"'
)

ClaudeCode = ScriptedQuery | MissingClaudeCode
Conversation = list[dict[str, str]]


def use_claude_code(
    monkeypatch: pytest.MonkeyPatch,
    sessions: Sessions,
    claude_code: object,
) -> None:
    monkeypatch.setattr(chatbot, "CHOSEN_AI_ENGINE", CLAUDE_CODE_ENGINE)
    monkeypatch.setattr(chatbot, "SessionLocal", sessions)
    monkeypatch.setattr(chatbot, "query", claude_code)


def _scripted(messages: list[Message]) -> ScriptedQuery:
    return ScriptedQuery(messages)


def _asked(client: TestClient, conversation: Conversation) -> Response:
    return client.post(
        _CHAT, json={"conversation": conversation}, headers=authorization()
    )


@given(
    parsers.parse('Claude Code answers "{answer}"'),
    target_fixture="claude_code",
)
def script_claude_code(
    monkeypatch: pytest.MonkeyPatch, sessions: Sessions, answer: str
) -> ClaudeCode:
    claude_code = _scripted([result_message(answer, is_error=False)])
    use_claude_code(monkeypatch, sessions, claude_code)

    return claude_code


@given("Claude Code is not installed")
def remove_claude_code(
    monkeypatch: pytest.MonkeyPatch, sessions: Sessions
) -> None:
    use_claude_code(monkeypatch, sessions, MissingClaudeCode())


@given("Claude Code fails")
def break_claude_code(
    monkeypatch: pytest.MonkeyPatch, sessions: Sessions
) -> None:
    failing_claude_code = _scripted([result_message(None, is_error=True)])
    use_claude_code(monkeypatch, sessions, failing_claude_code)


@when(parsers.parse('I ask "{question}"'), target_fixture="reply")
def ask_question(client: TestClient, question: str) -> Response:
    return _asked(client, [{"role": _USER_ROLE, "content": question}])


@when(parsers.parse(_TWO_QUESTIONS_STEP), target_fixture="reply")
def ask_two_questions(
    client: TestClient, first_question: str, second_question: str
) -> Response:
    conversation = [
        {"role": _USER_ROLE, "content": first_question},
        {"role": _ASSISTANT_ROLE, "content": _EARLIER_ANSWER},
        {"role": _USER_ROLE, "content": second_question},
    ]

    return _asked(client, conversation)


@then(parsers.parse('I get the answer "{answer}"'))
def check_answer(reply: Response, answer: str) -> None:
    assert reply_body(reply)["answer"] == answer


@then(
    parsers.parse(
        'Claude Code was shown "{first_question}" and "{second_question}"'
    )
)
def check_conversation_shown(
    claude_code: ScriptedQuery, first_question: str, second_question: str
) -> None:
    shown_prompt = claude_code.prompts[0]

    assert first_question in shown_prompt
    assert second_question in shown_prompt


@then(parsers.parse('the answer mentions "{expected_text}"'))
def check_answer_mentions(reply: Response, expected_text: str) -> None:
    assert expected_text in str(reply_body(reply)["answer"])


@then(parsers.parse('the answer does not mention "{unexpected_text}"'))
def check_answer_omits(reply: Response, unexpected_text: str) -> None:
    assert unexpected_text not in str(reply_body(reply)["answer"])
