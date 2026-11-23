from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from tests.broker_fakes import FakeChannel
from tests.requirements.session_steps import (
    NEW_PHRASE,
    SIGN_UP_PHRASE,
    WRONG_PHRASE,
    access_headers,
    reply_body,
)

_ACCOUNT = "/account"
_USERNAME = "/account/username"
_PHRASE_CHANGE = "/account/password"
_THEME = "/account/theme"


def _changed_phrase(
    account_client: TestClient, current_phrase: str, new_phrase: str
) -> Response:
    phrase_request = {
        "current_password": current_phrase,
        "new_password": new_phrase,
    }

    return account_client.patch(
        _PHRASE_CHANGE,
        json=phrase_request,
        headers=access_headers(account_client),
    )


def _deleted_account(account_client: TestClient, phrase: str) -> Response:
    return account_client.request(
        "DELETE",
        _ACCOUNT,
        json={"password": phrase},
        headers=access_headers(account_client),
    )


@when(
    parsers.parse('I change my username to "{username}"'),
    target_fixture="reply",
)
def change_username(account_client: TestClient, username: str) -> Response:
    return account_client.patch(
        _USERNAME,
        json={"username": username},
        headers=access_headers(account_client),
    )


@when("I change my password")
@given("I changed my password")
def change_password(account_client: TestClient) -> None:
    reply = _changed_phrase(account_client, SIGN_UP_PHRASE, NEW_PHRASE)
    _ = reply.raise_for_status()


@when(
    parsers.parse('I change my password to "{new_phrase}"'),
    target_fixture="reply",
)
def change_password_to(
    account_client: TestClient, new_phrase: str
) -> Response:
    return _changed_phrase(account_client, SIGN_UP_PHRASE, new_phrase)


@when(
    "I change my password giving a wrong current password",
    target_fixture="reply",
)
def change_password_wrongly(account_client: TestClient) -> Response:
    return _changed_phrase(account_client, WRONG_PHRASE, NEW_PHRASE)


@when("I delete my account")
def delete_account(
    account_client: TestClient, event_broker: FakeChannel
) -> None:
    _ = event_broker
    reply = _deleted_account(account_client, SIGN_UP_PHRASE)
    _ = reply.raise_for_status()


@when("I try to delete my account", target_fixture="reply")
def try_to_delete_account(account_client: TestClient) -> Response:
    return _deleted_account(account_client, SIGN_UP_PHRASE)


@when("I delete my account with a wrong password", target_fixture="reply")
def delete_account_wrongly(account_client: TestClient) -> Response:
    return _deleted_account(account_client, WRONG_PHRASE)


@when(parsers.parse('I choose the "{theme}" theme'), target_fixture="reply")
def choose_theme(account_client: TestClient, theme: str) -> Response:
    return account_client.patch(
        _THEME, json={"theme": theme}, headers=access_headers(account_client)
    )


@then(parsers.parse('my account uses the "{theme}" theme'))
def check_theme(account_client: TestClient, theme: str) -> None:
    reply = account_client.get(
        _ACCOUNT, headers=access_headers(account_client)
    )

    assert reply_body(reply)["theme"] == theme
