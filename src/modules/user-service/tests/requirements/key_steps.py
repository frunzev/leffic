from typing import cast

from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from tests.requirements.session_steps import (
    NEW_PHRASE,
    SIGN_UP_PHRASE,
    WRONG_PHRASE,
    access_headers,
    reply_body,
)

_PROVIDER_KEYS = "/account/provider-keys"
_OPEN_KEY = "/account/provider-keys/{provider}/open"
_REMOVE_KEY = "/account/provider-keys/{provider}"
_PROVIDERS = {"OpenAI": "openai", "Gemini": "gemini"}
_ANY_KEY = "sk-live-000000000000000007Xa2"
_BLANK_KEY = "   "
_SAVE_KEY_STEP = 'I save the {provider_name} key "{provider_key}"'
_SAVED_KEY_STEP = 'I saved the {provider_name} key "{provider_key}"'
_SAVED_AGAIN_STEP = (
    'I saved the {provider_name} key "{provider_key}" '
    "again with my new password"
)
_LIMITED_SAVED_KEY_STEP = (
    'I saved the {provider_name} key "{provider_key}" '
    "with a monthly limit of {limit_cents:d} cents"
)
_LIMITED_KEY_STEP = (
    'I save the {provider_name} key "{provider_key}" '
    "with a monthly limit of {limit_cents:d} cents"
)

SavedKey = dict[str, object]


def _attempted_key_save(
    account_client: TestClient, key_request: dict[str, object]
) -> Response:
    return account_client.put(
        _PROVIDER_KEYS,
        json=key_request,
        headers=access_headers(account_client),
    )


def _saved_key(
    account_client: TestClient, key_request: dict[str, object]
) -> None:
    reply = _attempted_key_save(account_client, key_request)
    _ = reply.raise_for_status()


def _key_request(
    provider_name: str, provider_key: str, phrase: str
) -> dict[str, object]:
    return {
        "provider": _PROVIDERS[provider_name],
        "key": provider_key,
        "password": phrase,
    }


def _opened_key(
    account_client: TestClient, provider_name: str, phrase: str
) -> Response:
    open_path = _OPEN_KEY.format(provider=_PROVIDERS[provider_name])

    return account_client.post(
        open_path,
        json={"password": phrase},
        headers=access_headers(account_client),
    )


def _saved_keys(account_client: TestClient) -> list[SavedKey]:
    reply = account_client.get(
        _PROVIDER_KEYS, headers=access_headers(account_client)
    )

    return cast("list[SavedKey]", reply_body(reply)["provider_keys"])


@when(parsers.parse(_SAVE_KEY_STEP), target_fixture="saved_provider_key")
@given(parsers.parse(_SAVED_KEY_STEP))
def save_key(
    account_client: TestClient, provider_name: str, provider_key: str
) -> str:
    key_request = _key_request(provider_name, provider_key, SIGN_UP_PHRASE)
    _saved_key(account_client, key_request)

    return provider_key


@given(parsers.parse(_SAVED_AGAIN_STEP))
def save_key_again(
    account_client: TestClient, provider_name: str, provider_key: str
) -> None:
    key_request = _key_request(provider_name, provider_key, NEW_PHRASE)
    _saved_key(account_client, key_request)


@when(parsers.parse(_LIMITED_KEY_STEP))
@given(parsers.parse(_LIMITED_SAVED_KEY_STEP))
def save_limited_key(
    account_client: TestClient,
    provider_name: str,
    provider_key: str,
    limit_cents: int,
) -> None:
    key_request = _key_request(provider_name, provider_key, SIGN_UP_PHRASE)
    key_request["monthly_limit_cents"] = limit_cents
    _saved_key(account_client, key_request)


@then(parsers.parse('my saved keys show "{hint}" but never the key itself'))
def check_key_hidden(
    account_client: TestClient, saved_provider_key: str, hint: str
) -> None:
    reply = account_client.get(
        _PROVIDER_KEYS, headers=access_headers(account_client)
    )
    saved_keys = cast("list[SavedKey]", reply_body(reply)["provider_keys"])

    assert saved_keys[0]["hint"] == hint
    assert saved_provider_key not in reply.text


@when(
    parsers.parse("I open my {provider_name} key with my password"),
    target_fixture="reply",
)
def open_key(account_client: TestClient, provider_name: str) -> Response:
    return _opened_key(account_client, provider_name, SIGN_UP_PHRASE)


@when(
    parsers.parse("I open my {provider_name} key with a wrong password"),
    target_fixture="reply",
)
def open_key_wrongly(
    account_client: TestClient, provider_name: str
) -> Response:
    return _opened_key(account_client, provider_name, WRONG_PHRASE)


@when(
    parsers.parse("I open my {provider_name} key with my new password"),
    target_fixture="reply",
)
def open_key_after_change(
    account_client: TestClient, provider_name: str
) -> Response:
    return _opened_key(account_client, provider_name, NEW_PHRASE)


@then(parsers.parse('I get the key "{provider_key}"'))
def check_key_opened(reply: Response, provider_key: str) -> None:
    assert reply_body(reply)["key"] == provider_key


@when(parsers.parse("I remove my {provider_name} key"), target_fixture="reply")
def remove_key(account_client: TestClient, provider_name: str) -> Response:
    remove_path = _REMOVE_KEY.format(provider=_PROVIDERS[provider_name])

    return account_client.delete(
        remove_path, headers=access_headers(account_client)
    )


@then("I have no saved keys")
def check_no_keys(account_client: TestClient) -> None:
    assert _saved_keys(account_client) == []


@then(
    parsers.parse(
        "my {provider_name} key has a monthly limit of {limit_cents:d} cents"
    )
)
def check_key_limit(
    account_client: TestClient, provider_name: str, limit_cents: int
) -> None:
    saved_key = _saved_keys(account_client)[0]

    assert saved_key["provider"] == _PROVIDERS[provider_name]
    assert saved_key["monthly_limit_cents"] == limit_cents


@then(parsers.parse("my {provider_name} key has no monthly limit"))
def check_key_unlimited(
    account_client: TestClient, provider_name: str
) -> None:
    saved_key = _saved_keys(account_client)[0]

    assert saved_key["provider"] == _PROVIDERS[provider_name]
    assert saved_key["monthly_limit_cents"] is None


@when(
    parsers.parse('I save a key for the provider "{provider}"'),
    target_fixture="reply",
)
def save_key_for_unknown_provider(
    account_client: TestClient, provider: str
) -> Response:
    key_request: dict[str, object] = {
        "provider": provider,
        "key": _ANY_KEY,
        "password": SIGN_UP_PHRASE,
    }

    return _attempted_key_save(account_client, key_request)


@when(
    parsers.parse("I save a blank {provider_name} key"),
    target_fixture="reply",
)
def save_blank_key(account_client: TestClient, provider_name: str) -> Response:
    key_request = _key_request(provider_name, _BLANK_KEY, SIGN_UP_PHRASE)

    return _attempted_key_save(account_client, key_request)
