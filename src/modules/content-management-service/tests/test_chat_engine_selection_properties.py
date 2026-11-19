from functools import partial
from typing import override
from unittest import mock

from fastapi.testclient import TestClient
from hypothesis import given, settings
from hypothesis import strategies as st

from app_factory import create_app
from features.chatbot import chatbot as chatbot_module
from features.chatbot.chat_engine import (
    ChatEngine,
    ChatEngineUnavailableError,
    Conversation,
)
from features.chatbot.claude_code_chat_engine import ClaudeCodeChatEngine
from features.chatbot.openai_chat_engine import OpenAIChatEngine
from tests.support import authorization

_CLAUDE_CODE = "claude-code"
_UNAVAILABLE = 503
_OTHER_ENGINE_NAMES = st.text(max_size=12).filter(
    lambda name: name != _CLAUDE_CODE
)


class UnavailableEngine(ChatEngine):
    def __init__(self, reason: str) -> None:
        self.reason: str = reason

    @override
    def answer(self, conversation: Conversation, user_id: str) -> str:
        _ = (conversation, user_id)

        raise ChatEngineUnavailableError(self.reason)


@settings(max_examples=5)
@given(st.just(_CLAUDE_CODE))
def test_provide_chat_engine_property_picks_claude_code_when_configured(
    engine_name: str,
) -> None:
    with mock.patch.object(chatbot_module, "CHAT_ENGINE", engine_name):
        engine = chatbot_module.provide_chat_engine()

    assert isinstance(engine, ClaudeCodeChatEngine)


@settings(max_examples=25)
@given(_OTHER_ENGINE_NAMES)
def test_provide_chat_engine_property_falls_back_to_openai(
    engine_name: str,
) -> None:
    with mock.patch.object(chatbot_module, "CHAT_ENGINE", engine_name):
        engine = chatbot_module.provide_chat_engine()

    assert isinstance(engine, OpenAIChatEngine)


@settings(max_examples=10, deadline=None)
@given(st.text(alphabet="abcdefgh ", min_size=1, max_size=20))
def test_chat_property_reports_an_unavailable_engine_with_its_reason(
    reason: str,
) -> None:
    application = create_app()
    unavailable_engine = partial(UnavailableEngine, reason)
    overrides = application.dependency_overrides
    overrides[chatbot_module.provide_chat_engine] = unavailable_engine

    with TestClient(application) as client:
        response = client.post(
            "/chat",
            json={"conversation": [{"role": "user", "content": "x"}]},
            headers=authorization(),
        )

    assert response.status_code == _UNAVAILABLE
    assert response.json()["detail"] == reason
