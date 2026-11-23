import pytest
from httpx import Request
from openai import APIConnectionError
from pytest_bdd import given, parsers

from features.chatbot import chatbot
from shared.ai_manager import AIFactory, create_openai_factory
from shared.chosen_ai_engine import OPENAI_ENGINE
from tests.account_service_fakes import FakeAccountService
from tests.openai_fakes import FakeClient, FakeResponse, as_openai

_OPENAI_KEY_VARIABLE = "OPENAI_API_KEY"
_OPENAI_URL = "https://api.openai.com/v1/responses"


class ScriptedConversationModel:
    def __init__(self, answer: str, cost: float | None) -> None:
        self._answer: str = answer
        self._cost: float | None = cost

    def get_ai_res_hist(
        self, system_prompt: str, history: list[object]
    ) -> tuple[str, float | None]:
        _ = (system_prompt, history)

        return self._answer, self._cost


class PricedOpenAi:
    def __init__(self, answer: str, cost: float) -> None:
        self._model: ScriptedConversationModel = ScriptedConversationModel(
            answer, cost
        )

    def get_ai(self, model: str | None = None) -> ScriptedConversationModel:
        _ = model

        return self._model


def _use_openai(
    monkeypatch: pytest.MonkeyPatch, openai: AIFactory | PricedOpenAi
) -> None:
    monkeypatch.setattr(chatbot, "CHOSEN_AI_ENGINE", OPENAI_ENGINE)
    monkeypatch.setattr(chatbot, "ai_factory", openai)


def _openai_answering(answers: list[object]) -> AIFactory:
    return create_openai_factory(as_openai(FakeClient(answers)))


@given(parsers.parse('OpenAI is chosen and answers "{answer}"'))
def script_openai(monkeypatch: pytest.MonkeyPatch, answer: str) -> None:
    _use_openai(monkeypatch, _openai_answering([FakeResponse(answer)]))


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
    _use_openai(monkeypatch, PricedOpenAi(answer, dollars))


@given("OpenAI is chosen without a key")
def remove_openai_key(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv(_OPENAI_KEY_VARIABLE, raising=False)
    _use_openai(monkeypatch, create_openai_factory())


@given("OpenAI is chosen but cannot be reached")
def make_openai_unreachable(monkeypatch: pytest.MonkeyPatch) -> None:
    unreachable = APIConnectionError(request=Request("POST", _OPENAI_URL))
    _use_openai(monkeypatch, _openai_answering([unreachable]))
