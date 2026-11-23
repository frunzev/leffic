import math
import os
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import Protocol, cast

import jwt
import requests

from shared.jwt_secret import ALGORITHM, SECRET_KEY

_ACCOUNT_SERVICE_VARIABLE = "ACCOUNT_SERVICE_URL"
_BUDGET_PATH = "/account/provider-keys/{provider}/budget"
_SPENDING_PATH = "/account/provider-keys/{provider}/spending"
_REQUEST_TIMEOUT_SECONDS = 10.0
_TOKEN_LIFETIME = timedelta(minutes=1)
_CENTS_PER_DOLLAR = 100
_PROVIDER_NAMES = {"openai": "OpenAI", "claude-code": "Claude Code"}
_EXHAUSTED = "Your monthly {provider} limit is reached."

UserTokenSigner = Callable[[str], str]


class AiBudgetExhaustedError(Exception):
    def __init__(self, provider: str) -> None:
        provider_name = _PROVIDER_NAMES.get(provider, provider)
        super().__init__(_EXHAUSTED.format(provider=provider_name))


class AiBudget(Protocol):
    def ensure_can_spend(self, user_id: str, provider: str) -> None: ...

    def record_spending(
        self, user_id: str, provider: str, dollars: float | None
    ) -> None: ...


def cents_of(dollars: float) -> int:
    spent_cents = Decimal(str(dollars)) * _CENTS_PER_DOLLAR

    return math.ceil(spent_cents)


def budget_token(user_id: str) -> str:
    expires_at = datetime.now(UTC) + _TOKEN_LIFETIME
    claims: dict[str, object] = {"user_id": user_id, "exp": expires_at}

    return jwt.encode(claims, SECRET_KEY, algorithm=ALGORITHM)


class UnlimitedAiBudget:
    def ensure_can_spend(self, user_id: str, provider: str) -> None:
        _ = (user_id, provider)

    def record_spending(
        self, user_id: str, provider: str, dollars: float | None
    ) -> None:
        _ = (user_id, provider, dollars)


class AccountServiceAiBudget:
    def __init__(
        self, account_service_url: str, sign_user_token: UserTokenSigner
    ) -> None:
        self._account_service_url: str = account_service_url
        self._sign_user_token: UserTokenSigner = sign_user_token

    def ensure_can_spend(self, user_id: str, provider: str) -> None:
        budget_url = self._url(_BUDGET_PATH, provider)
        reply = requests.get(
            budget_url,
            headers=self._headers(user_id),
            timeout=_REQUEST_TIMEOUT_SECONDS,
        )
        reply.raise_for_status()
        budget_body = cast("dict[str, object]", reply.json())

        if budget_body.get("can_spend") is not True:
            raise AiBudgetExhaustedError(provider)

    def record_spending(
        self, user_id: str, provider: str, dollars: float | None
    ) -> None:
        if dollars is None:
            return

        reply = requests.post(
            self._url(_SPENDING_PATH, provider),
            json={"cents": cents_of(dollars)},
            headers=self._headers(user_id),
            timeout=_REQUEST_TIMEOUT_SECONDS,
        )
        reply.raise_for_status()

    def _url(self, path: str, provider: str) -> str:
        return self._account_service_url + path.format(provider=provider)

    def _headers(self, user_id: str) -> dict[str, str]:
        user_token = self._sign_user_token(user_id)

        return {"Authorization": f"Bearer {user_token}"}


def provide_ai_budget() -> AiBudget:
    account_service_url = os.getenv(_ACCOUNT_SERVICE_VARIABLE, "")

    if not account_service_url:
        return UnlimitedAiBudget()

    return AccountServiceAiBudget(account_service_url, budget_token)
