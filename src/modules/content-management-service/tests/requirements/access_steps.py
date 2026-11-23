import uuid
from dataclasses import dataclass

import jwt
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import parsers, then, when

from shared.jwt_secret import ALGORITHM, SECRET_KEY
from tests.requirements.requirement_listing import HOME, opened_folder
from tests.support import USER_ID

_UNTRUSTED_SIGNING_KEY = "a secret this server never issued tokens with"
_MALFORMED_USER_ID = "not-a-user-id"
_NOT_SIGNED_IN = 401

TokenClaims = dict[str, object]


@dataclass(frozen=True)
class SignInShape:
    claims: TokenClaims
    signing_key: str
    scheme: str


_SIGN_IN_SHAPES = {
    "a forged sign-in": SignInShape(
        {"user_id": USER_ID}, _UNTRUSTED_SIGNING_KEY, "Bearer"
    ),
    "a sign-in lacking the bearer scheme": SignInShape(
        {"user_id": USER_ID}, SECRET_KEY, "Token"
    ),
    "a sign-in that names no user": SignInShape(
        {"sub": str(uuid.uuid4())}, SECRET_KEY, "Bearer"
    ),
    "a sign-in that names a malformed user": SignInShape(
        {"user_id": _MALFORMED_USER_ID}, SECRET_KEY, "Bearer"
    ),
}


@when("someone opens home without signing in", target_fixture="reply")
def open_home_signed_out(client: TestClient) -> Response:
    return opened_folder(client, HOME, {})


@when(
    parsers.parse("someone opens home with {sign_in_kind}"),
    target_fixture="reply",
)
def open_home_with_sign_in(client: TestClient, sign_in_kind: str) -> Response:
    shape = _SIGN_IN_SHAPES[sign_in_kind]
    token = jwt.encode(shape.claims, shape.signing_key, algorithm=ALGORITHM)
    headers = {"Authorization": f"{shape.scheme} {token}"}

    return opened_folder(client, HOME, headers)


@then("they are refused as not signed in")
def check_refused_signed_out(reply: Response) -> None:
    assert reply.status_code == _NOT_SIGNED_IN
