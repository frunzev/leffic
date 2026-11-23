import uuid
from dataclasses import dataclass

import jwt
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from shared.jwt_secret import ALGORITHM, SECRET_KEY
from tests.requirements.session_steps import access_headers

_ACCOUNT = "/account"
_REFRESH_COOKIE = "refresh_token"
_UNTRUSTED_SIGNING_KEY = "a secret this server never issued tokens with"
_MALFORMED_USER_ID = "not-a-user-id"
_NOT_SIGNED_IN = 401

TokenClaims = dict[str, object]


@dataclass(frozen=True)
class SignInShape:
    claims: TokenClaims
    signing_key: str
    scheme: str


def _signed_token(claims: TokenClaims, signing_key: str) -> str:
    return jwt.encode(claims, signing_key, algorithm=ALGORITHM)


def _some_user() -> TokenClaims:
    return {"user_id": str(uuid.uuid4())}


_SIGN_IN_SHAPES = {
    "a forged sign-in": SignInShape(
        _some_user(), _UNTRUSTED_SIGNING_KEY, "Bearer"
    ),
    "a sign-in lacking the bearer scheme": SignInShape(
        _some_user(), SECRET_KEY, "Token"
    ),
    "a sign-in that names no user": SignInShape({}, SECRET_KEY, "Bearer"),
    "a sign-in that names a malformed user": SignInShape(
        {"user_id": _MALFORMED_USER_ID}, SECRET_KEY, "Bearer"
    ),
}


@when("someone opens an account without signing in", target_fixture="reply")
def open_account_signed_out(account_client: TestClient) -> Response:
    return account_client.get(_ACCOUNT)


@when(
    parsers.parse("someone opens an account with {sign_in_kind}"),
    target_fixture="reply",
)
def open_account_with_sign_in(
    account_client: TestClient, sign_in_kind: str
) -> Response:
    shape = _SIGN_IN_SHAPES[sign_in_kind]
    token = _signed_token(shape.claims, shape.signing_key)
    headers = {"Authorization": f"{shape.scheme} {token}"}

    return account_client.get(_ACCOUNT, headers=headers)


@then("they are refused as not signed in")
def check_refused_signed_out(reply: Response) -> None:
    assert reply.status_code == _NOT_SIGNED_IN


def _replace_session_cookie(account_client: TestClient, token: str) -> None:
    account_client.cookies.clear()
    account_client.cookies.set(_REFRESH_COOKIE, token)


@given("my session cookie is forged")
def forge_session_cookie(account_client: TestClient) -> None:
    forged_token = _signed_token(_some_user(), _UNTRUSTED_SIGNING_KEY)
    _replace_session_cookie(account_client, forged_token)


@given("my session cookie names no user")
def remove_user_from_session_cookie(account_client: TestClient) -> None:
    anonymous_token = _signed_token({}, SECRET_KEY)
    _replace_session_cookie(account_client, anonymous_token)


@given("I kept my sign-in", target_fixture="kept_sign_in")
def keep_sign_in(account_client: TestClient) -> dict[str, str]:
    return access_headers(account_client)


@when("I open my account with the sign-in I kept", target_fixture="reply")
def open_account_with_kept_sign_in(
    account_client: TestClient, kept_sign_in: dict[str, str]
) -> Response:
    return account_client.get(_ACCOUNT, headers=kept_sign_in)
