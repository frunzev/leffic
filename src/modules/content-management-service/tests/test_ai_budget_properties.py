import math
from decimal import Decimal

import jwt
import pytest
from hypothesis import HealthCheck, given, settings
from hypothesis import strategies as st

from shared.ai_budget import (
    AccountServiceAiBudget,
    AiBudgetExhaustedError,
    UnlimitedAiBudget,
    budget_token,
    cents_of,
    provide_ai_budget,
)
from shared.jwt_secret import ALGORITHM, SECRET_KEY
from tests.account_service_fakes import (
    ACCOUNT_SERVICE_URL,
    ACCOUNT_SERVICE_VARIABLE,
    FakeAccountService,
    install_account_service,
)

_DOLLARS = st.decimals(
    min_value=Decimal(0),
    max_value=Decimal(100),
    places=6,
    allow_nan=False,
    allow_infinity=False,
)
_USER_IDS = st.uuids().map(str)
_PROVIDERS = st.sampled_from(["openai", "claude-code"])
_PATCHED_SETTINGS = settings(
    max_examples=25,
    suppress_health_check=[HealthCheck.function_scoped_fixture],
)


@given(dollars=_DOLLARS)
def test_cents_of_property_never_records_less_than_was_spent(
    dollars: Decimal,
) -> None:
    cents = cents_of(float(dollars))
    spent_cents = Decimal(str(float(dollars))) * 100

    assert cents >= spent_cents
    assert cents - spent_cents < 1
    assert cents == math.ceil(spent_cents)


@given(user_id=_USER_IDS)
def test_budget_token_property_names_the_user_for_the_account_service(
    user_id: str,
) -> None:
    claims = jwt.decode(budget_token(user_id), SECRET_KEY, [ALGORITHM])

    assert claims["user_id"] == user_id
    assert isinstance(claims["exp"], int)


@given(user_id=_USER_IDS, provider=_PROVIDERS)
def test_ensure_can_spend_property_never_limits_without_an_account_service(
    user_id: str, provider: str
) -> None:
    UnlimitedAiBudget().ensure_can_spend(user_id, provider)
    UnlimitedAiBudget().record_spending(user_id, provider, 1.0)


@_PATCHED_SETTINGS
@given(user_id=_USER_IDS, provider=_PROVIDERS, is_open=st.booleans())
def test_ensure_can_spend_property_follows_the_account_service(
    monkeypatch: pytest.MonkeyPatch, user_id: str, provider: str, is_open: bool
) -> None:
    account_service = FakeAccountService(is_open=is_open)
    install_account_service(monkeypatch, account_service)
    budget = AccountServiceAiBudget(ACCOUNT_SERVICE_URL, budget_token)

    if is_open:
        budget.ensure_can_spend(user_id, provider)
    else:
        with pytest.raises(AiBudgetExhaustedError):
            budget.ensure_can_spend(user_id, provider)

    budget_url = (
        f"{ACCOUNT_SERVICE_URL}/account/provider-keys/{provider}/budget"
    )
    token_claims = jwt.decode(
        account_service.tokens[0], SECRET_KEY, [ALGORITHM]
    )

    assert account_service.asked_urls == [budget_url]
    assert token_claims["user_id"] == user_id


@_PATCHED_SETTINGS
@given(user_id=_USER_IDS, provider=_PROVIDERS, dollars=_DOLLARS)
def test_record_spending_property_reports_every_priced_call(
    monkeypatch: pytest.MonkeyPatch,
    user_id: str,
    provider: str,
    dollars: Decimal,
) -> None:
    account_service = FakeAccountService(is_open=True)
    install_account_service(monkeypatch, account_service)
    budget = AccountServiceAiBudget(ACCOUNT_SERVICE_URL, budget_token)

    budget.record_spending(user_id, provider, float(dollars))
    budget.record_spending(user_id, provider, None)

    spending_url = (
        f"{ACCOUNT_SERVICE_URL}/account/provider-keys/{provider}/spending"
    )

    assert account_service.recorded == [
        (spending_url, cents_of(float(dollars)))
    ]


@given(provider=_PROVIDERS)
def test_ai_budget_exhausted_error_property_names_the_provider(
    provider: str,
) -> None:
    message = str(AiBudgetExhaustedError(provider))

    assert message.startswith("Your monthly ")
    assert message.endswith(" limit is reached.")


@_PATCHED_SETTINGS
@given(account_service_url=st.sampled_from(["", ACCOUNT_SERVICE_URL]))
def test_provide_ai_budget_property_needs_an_account_service_to_limit(
    monkeypatch: pytest.MonkeyPatch, account_service_url: str
) -> None:
    monkeypatch.setenv(ACCOUNT_SERVICE_VARIABLE, account_service_url)

    budget = provide_ai_budget()

    if account_service_url:
        assert isinstance(budget, AccountServiceAiBudget)
    else:
        assert isinstance(budget, UnlimitedAiBudget)


def _named_token(user_id: str) -> str:
    return f"token-for-{user_id}"


@given(
    provider=_PROVIDERS,
    path=st.sampled_from(["/budget/{provider}", "/spending/{provider}"]),
)
def test__url_property_puts_the_provider_under_the_account_service(
    provider: str, path: str
) -> None:
    budget = AccountServiceAiBudget(ACCOUNT_SERVICE_URL, _named_token)

    reached_url = budget._url(path, provider)

    assert reached_url.startswith(ACCOUNT_SERVICE_URL)
    assert reached_url.endswith(provider)


@given(user_id=_USER_IDS)
def test__headers_property_carries_the_token_signed_for_the_user(
    user_id: str,
) -> None:
    budget = AccountServiceAiBudget(ACCOUNT_SERVICE_URL, _named_token)

    headers = budget._headers(user_id)

    assert headers == {"Authorization": f"Bearer {_named_token(user_id)}"}
