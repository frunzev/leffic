from typing import cast

import pytest
from fastapi.testclient import TestClient
from pytest_bdd import given, parsers, then, when

from features.account import provider_key_router, spending_router
from tests.requirements.session_steps import access_headers, reply_body

_PROVIDERS = {"OpenAI": "openai", "Gemini": "gemini"}
_SPENDING = "/account/provider-keys/{provider}/spending"
_BUDGET = "/account/provider-keys/{provider}/budget"
_PROVIDER_KEYS = "/account/provider-keys"
_FAR_FUTURE_MONTH = "2999-01"
_RECORD_STEP = (
    "the app records {cents:d} cents of {provider_name} spending for me"
)
_RECORDED_STEP = (
    "the app recorded {cents:d} cents of {provider_name} spending for me"
)

SavedKey = dict[str, object]


def _far_future_month() -> str:
    return _FAR_FUTURE_MONTH


def _can_spend(account_client: TestClient, provider_name: str) -> object:
    budget_path = _BUDGET.format(provider=_PROVIDERS[provider_name])
    reply = account_client.get(
        budget_path, headers=access_headers(account_client)
    )

    return reply_body(reply)["can_spend"]


@when(parsers.parse(_RECORD_STEP))
@given(parsers.parse(_RECORDED_STEP))
def record_spending(
    account_client: TestClient, cents: int, provider_name: str
) -> None:
    spending_path = _SPENDING.format(provider=_PROVIDERS[provider_name])
    reply = account_client.post(
        spending_path,
        json={"cents": cents},
        headers=access_headers(account_client),
    )
    _ = reply.raise_for_status()


@when("a new month begins")
def begin_new_month(monkeypatch: pytest.MonkeyPatch) -> None:
    for router_module in (provider_key_router, spending_router):
        monkeypatch.setattr(router_module, "current_month", _far_future_month)


@then(parsers.parse("my {provider_name} key shows {cents:d} cents spent"))
def check_spent(
    account_client: TestClient, provider_name: str, cents: int
) -> None:
    reply = account_client.get(
        _PROVIDER_KEYS, headers=access_headers(account_client)
    )
    saved_keys = cast("list[SavedKey]", reply_body(reply)["provider_keys"])
    spent_by_provider: dict[object, object] = {}

    for saved_key in saved_keys:
        spent_by_provider[saved_key["provider"]] = saved_key["spent_cents"]

    assert spent_by_provider[_PROVIDERS[provider_name]] == cents


@then(parsers.parse("I may not spend more on {provider_name}"))
def check_budget_closed(
    account_client: TestClient, provider_name: str
) -> None:
    assert _can_spend(account_client, provider_name) is False


@then(parsers.parse("I may still spend on {provider_name}"))
def check_budget_open(account_client: TestClient, provider_name: str) -> None:
    assert _can_spend(account_client, provider_name) is True
