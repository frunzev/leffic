import pytest
from openai import OpenAIError
from pytest_bdd import given, parsers

from features.chatbot import chatbot
from shared.ai_manager import AiMessage
from shared.chosen_ai_engine import OPENAI_ENGINE
from tests.account_service_fakes import FakeAccountService

_MISSING_KEY = "The OpenAI key is missing"


class ScriptedConversationModel:
    def __init__(self, answer: str, cost: float | None) -> None:
        self._answer: str = answer
        self._cost: float | None = cost

    def get_ai_res_hist(
        self, system_prompt: str, history: list[AiMessage]
    ) -> tuple[str, float | None]:
        _ = (system_prompt, history)

        return self._answer, self._cost


class ScriptedOpenAi:
    def __init__(self, answer: str, cost: float | None) -> None:
        self._model: ScriptedConversationModel = ScriptedConversationModel(
            answer, cost
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
    _use_openai(monkeypatch, ScriptedOpenAi(answer, None))


@given(
    parsers.parse(
        'OpenAI is chosen and answers "{answer}" for {dollars:f} dollars'
    )
)
def script_priced_openai(
    monkeypatch: pytest.MonkeyPatch,
    account_service: FakeAccountService,
    answer: str,
    dollars: float,
) -> None:
    _ = account_service
    _use_openai(monkeypatch, ScriptedOpenAi(answer, dollars))


@given("OpenAI is chosen without a key")
def remove_openai_key(monkeypatch: pytest.MonkeyPatch) -> None:
    _use_openai(monkeypatch, KeylessOpenAi())
