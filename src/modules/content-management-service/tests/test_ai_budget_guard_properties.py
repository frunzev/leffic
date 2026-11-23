import pytest
from fastapi import HTTPException, status
from hypothesis import HealthCheck, given, settings
from hypothesis import strategies as st

from shared.ai_budget import AiBudgetExhaustedError
from shared.ai_budget_guard import ensure_ai_budget
from tests.account_service_fakes import (
    FakeAccountService,
    install_account_service,
)

_USER_IDS = st.uuids().map(str)
_PROVIDERS = st.sampled_from(["openai", "claude-code"])
_PATCHED_SETTINGS = settings(
    max_examples=25,
    suppress_health_check=[HealthCheck.function_scoped_fixture],
)


@_PATCHED_SETTINGS
@given(user_id=_USER_IDS, provider=_PROVIDERS, is_open=st.booleans())
def test_ensure_ai_budget_property_refuses_payment_only_when_exhausted(
    monkeypatch: pytest.MonkeyPatch, user_id: str, provider: str, is_open: bool
) -> None:
    install_account_service(monkeypatch, FakeAccountService(is_open=is_open))

    if is_open:
        ensure_ai_budget(user_id, provider)

        return

    with pytest.raises(HTTPException) as refusal:
        ensure_ai_budget(user_id, provider)

    assert refusal.value.status_code == status.HTTP_402_PAYMENT_REQUIRED
    assert refusal.value.detail == str(AiBudgetExhaustedError(provider))
