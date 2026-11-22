import pytest
from openai import OpenAIError
from pytest_bdd import given, parsers

from features.chatbot import chatbot
from shared.ai_manager import AiMessage
from shared.chosen_ai_engine import OPENAI_ENGINE

_MISSING_KEY = "The OpenAI key is missing"


class ScriptedConversationModel:
    def __init__(self, answer: str) -> None:
        self._answer: str = answer

    def get_ai_res_hist(
        self, system_prompt: str, history: list[AiMessage]
    ) -> str:
        _ = (system_prompt, history)

        return self._answer


class ScriptedOpenAi:
    def __init__(self, answer: str) -> None:
        self._model: ScriptedConversationModel = ScriptedConversationModel(
            answer
        )

    def get_ai(self, model: str | None = None) -> ScriptedConversationModel:
        _ = model

        return self._model


class KeylessOpenAi:
    def get_ai(self, model: str | None = None) -> ScriptedConversationModel:
        _ = model

        raise OpenAIError(_MISSING_KEY)


def _use_openai(
    monkeypatch: pytest.MonkeyPatch, openai: ScriptedOpenAi | KeylessOpenAi
) -> None:
    monkeypatch.setattr(chatbot, "CHOSEN_AI_ENGINE", OPENAI_ENGINE)
    monkeypatch.setattr(chatbot, "ai_factory", openai)


@given(parsers.parse('OpenAI is chosen and answers "{answer}"'))
def script_openai(monkeypatch: pytest.MonkeyPatch, answer: str) -> None:
    _use_openai(monkeypatch, ScriptedOpenAi(answer))


@given("OpenAI is chosen without a key")
def remove_openai_key(monkeypatch: pytest.MonkeyPatch) -> None:
    _use_openai(monkeypatch, KeylessOpenAi())
