import jwt
import pytest
from pytest_bdd import given, parsers, then

from shared.chosen_ai_engine import OPENAI_ENGINE
from shared.jwt_secret import ALGORITHM, SECRET_KEY
from tests.account_service_fakes import (
    ACCOUNT_SERVICE_URL,
    FakeAccountService,
    install_account_service,
)
from tests.support import USER_ID

_OPENAI_SPENDING_URL = (
    f"{ACCOUNT_SERVICE_URL}/account/provider-keys/{OPENAI_ENGINE}/spending"
)


@pytest.fixture
def account_service(monkeypatch: pytest.MonkeyPatch) -> FakeAccountService:
    account_service = FakeAccountService(is_open=True)
    install_account_service(monkeypatch, account_service)

    return account_service


@given("my OpenAI budget is used up")
def use_up_openai_budget(account_service: FakeAccountService) -> None:
    account_service.is_open = False


@then(parsers.parse("{cents:d} cents of OpenAI spending were recorded for me"))
def check_recorded_spending(
    account_service: FakeAccountService, cents: int
) -> None:
    last_token = account_service.tokens[-1]
    token_claims = jwt.decode(last_token, SECRET_KEY, [ALGORITHM])

    assert account_service.recorded == [(_OPENAI_SPENDING_URL, cents)]
    assert token_claims["user_id"] == USER_ID
