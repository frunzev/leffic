import pytest
import requests

ACCOUNT_SERVICE_URL = "http://accounts.test"
ACCOUNT_SERVICE_VARIABLE = "ACCOUNT_SERVICE_URL"


class FakeAccountReply:
    def __init__(self, body: dict[str, object]) -> None:
        self._body: dict[str, object] = body

    def raise_for_status(self) -> None:
        return None

    def json(self) -> dict[str, object]:
        return self._body


class FakeAccountService:
    def __init__(self, *, is_open: bool) -> None:
        self.is_open: bool = is_open
        self.asked_urls: list[str] = []
        self.recorded: list[tuple[str, object]] = []
        self.tokens: list[str] = []

    def _remember_token(self, headers: dict[str, str]) -> None:
        self.tokens.append(headers["Authorization"].removeprefix("Bearer "))

    def get(
        self, url: str, *, headers: dict[str, str], timeout: float
    ) -> FakeAccountReply:
        _ = timeout
        self.asked_urls.append(url)
        self._remember_token(headers)

        return FakeAccountReply({"can_spend": self.is_open})

    def post(
        self,
        url: str,
        *,
        json: dict[str, object],
        headers: dict[str, str],
        timeout: float,
    ) -> FakeAccountReply:
        _ = timeout
        self.recorded.append((url, json["cents"]))
        self._remember_token(headers)

        return FakeAccountReply({"can_spend": self.is_open})


def install_account_service(
    monkeypatch: pytest.MonkeyPatch, account_service: FakeAccountService
) -> None:
    monkeypatch.setenv(ACCOUNT_SERVICE_VARIABLE, ACCOUNT_SERVICE_URL)
    monkeypatch.setattr(requests, "get", account_service.get)
    monkeypatch.setattr(requests, "post", account_service.post)
