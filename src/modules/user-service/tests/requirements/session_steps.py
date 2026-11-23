from collections.abc import Iterator
from typing import cast

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app_factory import create_app
from shared.database import Base, get_db
from tests.support import SessionProvider

SIGN_UP_PHRASE = "correct horse battery staple"
NEW_PHRASE = "a much longer phrase to remember"

_IN_MEMORY_DATABASE = "sqlite://"
_SECURE_BASE_URL = "https://testserver"
WRONG_PHRASE = "not the phrase"
_SIGN_UP = "/sign-up"
_LOGIN = "/login"
_SESSION_RENEWAL = "/refresh-token"
_LOGOUT = "/logout"
_ACCOUNT = "/account"
_OK = 200

ReplyBody = dict[str, object]


@pytest.fixture
def account_app() -> FastAPI:
    engine = create_engine(
        _IN_MEMORY_DATABASE,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    app = create_app()
    app.dependency_overrides[get_db] = SessionProvider(
        sessionmaker(bind=engine)
    )

    return app


@pytest.fixture
def account_client(account_app: FastAPI) -> Iterator[TestClient]:
    with TestClient(account_app, base_url=_SECURE_BASE_URL) as test_client:
        yield test_client


def reply_body(reply: Response) -> ReplyBody:
    return cast("ReplyBody", reply.json())


def access_headers(account_client: TestClient) -> dict[str, str]:
    renewed = account_client.post(_SESSION_RENEWAL)
    _ = renewed.raise_for_status()
    access_token = reply_body(renewed)["access_token"]

    return {"Authorization": f"Bearer {access_token}"}


def logged_in(
    account_client: TestClient, email: str, password: str
) -> Response:
    return account_client.post(
        _LOGIN, json={"email": email, "password": password}
    )


@given(parsers.parse('someone signed up as "{username}" with "{email}"'))
@given(parsers.parse('I signed up as "{username}" with "{email}"'))
@when(
    parsers.parse('I sign up as "{username}" with "{email}"'),
    target_fixture="reply",
)
@when(
    parsers.parse('someone signs up as "{username}" with "{email}"'),
    target_fixture="reply",
)
def sign_up(account_client: TestClient, username: str, email: str) -> Response:
    sign_up_request = {
        "username": username,
        "email": email,
        "password": SIGN_UP_PHRASE,
    }

    return account_client.post(_SIGN_UP, json=sign_up_request)


@then(parsers.parse('I am signed in as "{username}"'))
def check_signed_in(account_client: TestClient, username: str) -> None:
    reply = account_client.get(
        _ACCOUNT, headers=access_headers(account_client)
    )

    assert reply_body(reply)["username"] == username


@then(parsers.parse('I am told the code "{code}"'))
def check_told_code(reply: Response, code: str) -> None:
    assert reply_body(reply)["code"] == code


@then(parsers.parse('I am told "{message}"'))
def check_told_message(reply: Response, message: str) -> None:
    assert reply_body(reply)["detail"] == message


@when(
    parsers.parse('I log in as "{email}" with a wrong password'),
    target_fixture="reply",
)
def log_in_wrongly(account_client: TestClient, email: str) -> Response:
    return logged_in(account_client, email, WRONG_PHRASE)


@when(
    parsers.parse('I log in as "{email}" with my password'),
    target_fixture="reply",
)
def log_in(account_client: TestClient, email: str) -> Response:
    return logged_in(account_client, email, SIGN_UP_PHRASE)


@then("the sign-up works")
def check_sign_up_works(reply: Response) -> None:
    assert reply.status_code == _OK


@when("I renew my session", target_fixture="reply")
def renew_session(account_client: TestClient) -> Response:
    return account_client.post(_SESSION_RENEWAL)


@then("I get a fresh access token")
def check_fresh_token(reply: Response) -> None:
    assert reply.status_code == _OK
    assert reply_body(reply)["access_token"]


@when("I log out")
def log_out(account_client: TestClient) -> None:
    reply = account_client.post(_LOGOUT)
    _ = reply.raise_for_status()


@then(
    parsers.parse('logging in as "{email}" with the old password is refused')
)
def check_old_password_refused(account_client: TestClient, email: str) -> None:
    assert logged_in(account_client, email, SIGN_UP_PHRASE).status_code != _OK


@then(parsers.parse('logging in as "{email}" with the new password works'))
def check_new_password_works(account_client: TestClient, email: str) -> None:
    assert logged_in(account_client, email, NEW_PHRASE).status_code == _OK


@then(parsers.parse('logging in as "{email}" with my password works'))
def check_my_password_works(account_client: TestClient, email: str) -> None:
    assert logged_in(account_client, email, SIGN_UP_PHRASE).status_code == _OK
