from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import parsers, then, when

from tests.requirements.session_steps import (
    SIGN_UP_PHRASE,
    access_headers,
    logged_in,
)

_SIGN_UP = "/sign-up"
_PHRASE_CHANGE = "/account/password"
_NUL_PHRASE = "correct horse\x00battery staple"
_PADDING_CHARACTER = "x"
_INVALID_REQUEST = 422


@when(
    parsers.parse(
        'I log in as "{email}" with a {length:d}-character password'
    ),
    target_fixture="reply",
)
def log_in_with_long_password(
    account_client: TestClient, email: str, length: int
) -> Response:
    return logged_in(account_client, email, _PADDING_CHARACTER * length)


@when(
    parsers.parse(
        (
            'I sign up as "{username}" with "{email}" '
            "using a password with a NUL character"
        )
    ),
    target_fixture="reply",
)
def sign_up_with_nul_password(
    account_client: TestClient, username: str, email: str
) -> Response:
    sign_up_request = {
        "username": username,
        "email": email,
        "password": _NUL_PHRASE,
    }

    return account_client.post(_SIGN_UP, json=sign_up_request)


@when(
    "I change my password to one with a NUL character",
    target_fixture="reply",
)
def change_to_nul_password(account_client: TestClient) -> Response:
    phrase_request = {
        "current_password": SIGN_UP_PHRASE,
        "new_password": _NUL_PHRASE,
    }

    return account_client.patch(
        _PHRASE_CHANGE,
        json=phrase_request,
        headers=access_headers(account_client),
    )


@then("the request is refused as invalid")
def check_refused_as_invalid(reply: Response) -> None:
    assert reply.status_code == _INVALID_REQUEST
