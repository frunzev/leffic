
import pytest
from openai import OpenAIError

from shared.ai_manager import OpenAIManager, RequestCost
from shared.model_rates import GPT_4_1_NANO, MODEL_RATES
from tests.openai_fakes import (
    FakeClient,
    FakeResponse,
    FakeUsage,
    as_response,
    openai_manager,
)

_SYSTEM_PROMPT = "You are helpful"
_USER_PROMPT = "Summarise this"
_EXPECTED_RETRY_CALL_COUNT = 2


def _manager(
    answers: list[object], rates_for: str | None = None
) -> tuple[OpenAIManager, FakeClient]:
    rates = MODEL_RATES.get(rates_for) if rates_for else None

    return openai_manager(answers, "gpt-5-mini", rates)


def test_returns_a_parsed_object_for_json_answers() -> None:
    manager, _ = _manager([FakeResponse('{"answer": 42}')])

    parsed, cost = manager.get_ai_res(_SYSTEM_PROMPT, _USER_PROMPT)

    assert parsed == {"answer": 42}
    assert cost is None


def test_retries_once_after_a_provider_error() -> None:
    manager, client = _manager(
        [OpenAIError("boom"), FakeResponse('{"ok": true}')]
    )

    parsed, _ = manager.get_ai_res(_SYSTEM_PROMPT, _USER_PROMPT)

    assert parsed == {"ok": True}
    assert len(client.responses.calls) == _EXPECTED_RETRY_CALL_COUNT


def test_raises_when_every_attempt_fails() -> None:
    manager, _ = _manager([OpenAIError("one"), OpenAIError("two")])

    with pytest.raises(RuntimeError, match="did not answer"):
        _ = manager.get_ai_res(_SYSTEM_PROMPT, _USER_PROMPT)


def test_computes_a_cost_when_rates_are_known() -> None:
    usage = FakeUsage(input_tokens=1000, output_tokens=500, cached_tokens=100)
    manager, _ = _manager(
        [FakeResponse('{"a": 1}', usage)], rates_for=GPT_4_1_NANO
    )

    _, cost = manager.get_ai_res(_SYSTEM_PROMPT, _USER_PROMPT)
    rates = MODEL_RATES[GPT_4_1_NANO]
    expected = (
        900 * rates.input_token_cost
        + 500 * rates.output_token_cost
        + 100 * rates.cached_token_cost
    )

    assert cost == expected


def test_reports_no_cost_without_usage() -> None:
    rates = MODEL_RATES[GPT_4_1_NANO]

    assert RequestCost(rates).of(as_response(FakeResponse("x"))) is None


def test_reports_no_cost_without_rates() -> None:
    usage = FakeUsage(input_tokens=1, output_tokens=1, cached_tokens=0)

    assert RequestCost(None).of(as_response(FakeResponse("x", usage))) is None


def test_history_answers_prepend_the_system_prompt() -> None:
    manager, client = _manager([FakeResponse("hello there")])

    answer, _cost = manager.get_ai_res_hist(
        _SYSTEM_PROMPT, [{"role": "user", "content": "hi"}]
    )

    assert answer == "hello there"
    assert len(client.responses.calls) == 1
