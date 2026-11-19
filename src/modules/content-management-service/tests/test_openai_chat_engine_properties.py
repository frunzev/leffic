from typing import override

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st
from openai import OpenAIError

from features.chatbot.chat_engine import ChatEngineUnavailableError
from features.chatbot.openai_chat_engine import OpenAIChatEngine
from shared.ai_manager import AiMessage

_TEXT = st.text(min_size=1, max_size=40)
_TURNS = st.lists(
    st.fixed_dictionaries(
        {"role": st.sampled_from(["user", "assistant"]), "content": _TEXT}
    ),
    min_size=1,
    max_size=6,
)
_USER_ID = "8f5d2a9e-3c1b-4f6a-9d7e-2b4c6a8e0f13"


class ScriptedAi:
    def __init__(self, answer: str) -> None:
        self.answer: str = answer
        self.histories: list[list[AiMessage]] = []

    def get_ai_res_hist(
        self, system_prompt: str, history: list[AiMessage]
    ) -> str:
        _ = system_prompt
        self.histories.append(history)

        return self.answer


class FailingAi(ScriptedAi):
    @override
    def get_ai_res_hist(
        self, system_prompt: str, history: list[AiMessage]
    ) -> str:
        _ = (system_prompt, history)

        raise OpenAIError(self.answer)


class ScriptedFactory:
    def __init__(self, ai: ScriptedAi) -> None:
        self.ai: ScriptedAi = ai

    def get_ai(self, model: str | None = None) -> ScriptedAi:
        _ = model

        return self.ai


@settings(max_examples=25)
@given(_TURNS, _TEXT)
def test_answer_property_hands_back_the_model_reply_for_the_conversation(
    conversation: list[dict[str, str]], reply: str
) -> None:
    ai = ScriptedAi(reply)
    engine = OpenAIChatEngine(ScriptedFactory(ai))

    assert engine.answer(conversation, _USER_ID) == reply
    assert ai.histories == [conversation]


@settings(max_examples=25)
@given(_TURNS, _TEXT)
def test_answer_property_reports_an_unreachable_model(
    conversation: list[dict[str, str]], failure: str
) -> None:
    engine = OpenAIChatEngine(ScriptedFactory(FailingAi(failure)))

    with pytest.raises(ChatEngineUnavailableError):
        _ = engine.answer(conversation, _USER_ID)


class KeylessFactory:
    def get_ai(self, model: str | None = None) -> ScriptedAi:
        _ = model

        raise OpenAIError("The api_key client option must be set")


@settings(max_examples=10)
@given(_TURNS)
def test_answer_property_reports_a_missing_key_as_unavailable(
    conversation: list[dict[str, str]],
) -> None:
    engine = OpenAIChatEngine(KeylessFactory())

    with pytest.raises(ChatEngineUnavailableError, match="Settings"):
        _ = engine.answer(conversation, _USER_ID)
