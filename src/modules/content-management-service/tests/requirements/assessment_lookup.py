from typing import NamedTuple, cast

from fastapi.testclient import TestClient

from shared.models import Test
from tests.requirements.requirement_lookup import (
    ReplyBody,
    Sessions,
    reply_body,
    unit_id_named,
)
from tests.support import authorization

TEST_ITEMS = "/test-items"

TestItemPayload = dict[str, object]


class FinishedTest(NamedTuple):
    session: str
    results: ReplyBody


def opened_test(
    client: TestClient,
    sessions: Sessions,
    test_name: str,
    page_query: dict[str, str | int],
) -> ReplyBody:
    test_query: dict[str, str | int] = {
        "test_id": unit_id_named(sessions, Test, test_name),
        **page_query,
    }
    reply = client.get(TEST_ITEMS, params=test_query, headers=authorization())

    return reply_body(reply)


def items_of(test_page: ReplyBody) -> list[TestItemPayload]:
    return cast("list[TestItemPayload]", test_page["test_items"])


def question_of(test_item: TestItemPayload) -> str:
    content = cast("dict[str, object]", test_item["content"])

    return str(content["question"])


def item_asking(
    test_items: list[TestItemPayload], question: str
) -> TestItemPayload:
    for test_item in test_items:
        if question_of(test_item) == question:
            return test_item

    message = f"No question asks {question!r}"
    raise LookupError(message)


def option_id(test_item: TestItemPayload, option_text: str) -> int:
    content = cast("dict[str, object]", test_item["content"])
    options = cast("list[dict[str, object]]", content["shuffled_options"])

    for option in options:
        if option["option"] == option_text:
            return cast("int", option["id"])

    message = f"No option reads {option_text!r}"
    raise LookupError(message)
