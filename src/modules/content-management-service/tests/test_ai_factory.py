from typing import cast

import pytest

from shared.ai_manager import (
    OpenAIManager,
    create_openai_factory,
)
from shared.model_rates import GPT_4_1_NANO, MODEL_RATES
from tests.openai_fakes import (
    FakeClient,
    FakeResponse,
    openai_manager,
)

_SYSTEM_PROMPT = "You are helpful"
_USER_PROMPT = "Summarise this"


def _manager(
    answers: list[object], rates_for: str | None = None
) -> tuple[OpenAIManager, FakeClient]:
    rates = MODEL_RATES.get(rates_for) if rates_for else None

    return openai_manager(answers, "gpt-5-mini", rates)


def test_the_factory_defaults_to_the_mini_model() -> None:
    manager = create_openai_factory().get_ai()

    assert isinstance(manager, OpenAIManager)
    assert manager.model_name == "gpt-5-mini"


def test_the_factory_honours_a_named_model() -> None:
    manager = create_openai_factory().get_ai(GPT_4_1_NANO)

    assert isinstance(manager, OpenAIManager)
    assert manager.model_name == GPT_4_1_NANO


def test_the_system_and_user_prompts_both_reach_the_model() -> None:
    manager, client = _manager([FakeResponse('{"a": 1}')])

    _ = manager.get_ai_res(_SYSTEM_PROMPT, _USER_PROMPT)

    sent = str(client.responses.calls[0])

    assert _SYSTEM_PROMPT in sent
    assert _USER_PROMPT in sent


def test_the_configured_model_reaches_the_client() -> None:
    manager, client = _manager([FakeResponse('{"a": 1}')])

    _ = manager.get_ai_res(_SYSTEM_PROMPT, _USER_PROMPT)
    sent = cast("dict[str, object]", client.responses.calls[0])

    assert sent["model"] == "gpt-5-mini"
    assert sent["input"]


def test_the_factory_reads_the_api_key_from_the_environment(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("OPENAI_API_KEY", "a-configured-key")

    manager = create_openai_factory().get_ai()

    assert isinstance(manager, OpenAIManager)
    assert manager.client.api_key == "a-configured-key"


def test_the_factory_gives_the_manager_its_own_client() -> None:
    factory = create_openai_factory()
    manager = factory.get_ai()
    another_manager = factory.get_ai()

    assert isinstance(manager, OpenAIManager)
    assert isinstance(another_manager, OpenAIManager)
    assert another_manager.client is manager.client


def test_a_known_model_gets_its_rates() -> None:
    manager = create_openai_factory().get_ai(GPT_4_1_NANO)

    assert isinstance(manager, OpenAIManager)
    assert manager.request_cost.rates == MODEL_RATES[GPT_4_1_NANO]


def test_an_unknown_model_has_no_rates() -> None:
    manager = create_openai_factory().get_ai("gpt-unknown")

    assert isinstance(manager, OpenAIManager)
    assert manager.request_cost.rates is None
