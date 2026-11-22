import jwt
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import then, when

from shared.jwt_secret import ALGORITHM
from tests.requirements.requirement_listing import HOME, opened_folder
from tests.support import USER_ID

_UNTRUSTED_SIGNING_KEY = "a secret this server never issued tokens with"
_NOT_SIGNED_IN = 401


@when("someone opens home without signing in", target_fixture="reply")
def open_home_signed_out(client: TestClient) -> Response:
    return opened_folder(client, HOME, {})


@when("someone opens home with a forged sign-in", target_fixture="reply")
def open_home_with_forged_token(client: TestClient) -> Response:
    forged_token = jwt.encode(
        {"user_id": USER_ID}, _UNTRUSTED_SIGNING_KEY, algorithm=ALGORITHM
    )
    forged_headers = {"Authorization": f"Bearer {forged_token}"}

    return opened_folder(client, HOME, forged_headers)


@then("they are refused as not signed in")
def check_refused_signed_out(reply: Response) -> None:
    assert reply.status_code == _NOT_SIGNED_IN
