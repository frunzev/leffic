import uuid
from typing import cast

from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from shared.models import Test
from tests.requirements.assessment_lookup import (
    TEST_ITEMS,
    TestItemPayload,
    item_asking,
    items_of,
    opened_test,
    option_id,
)
from tests.requirements.requirement_lookup import (
    ReplyBody,
    Sessions,
    folder_id_named,
    stored_question,
    unit_id_named,
)
from tests.requirements.requirement_seeding import seed_item, seeded_test
from tests.requirements.stranger_steps import stranger_headers
from tests.support import authorization

_REVIEW_TEST_ITEM = "/review-test-item"
_SESSION_RESULTS = "/test-session-results"
_TEST_ITEMS_STATS = "/test-items-stats"
_NO_PAGE_QUERY: dict[str, str | int] = {}
_ONLY_OPTION_STEP = (
    '"{test_name}" asks "{question}" with only "{option_text}" as an option'
)
_NUMBER_ANSWER_STEP = (
    "I send the number {number:d} as my answer to "
    '"{question}" in the test "{test_name}"'
)


def review(
    client: TestClient,
    headers: dict[str, str],
    review_request: dict[str, object],
) -> Response:
    return client.post(_REVIEW_TEST_ITEM, json=review_request, headers=headers)


def question_in_its_test(
    client: TestClient, sessions: Sessions, question: str
) -> TestItemPayload:
    stored_item = stored_question(sessions, question)
    test_name = _test_name_of(sessions, stored_item.test_id)
    test_page = opened_test(client, sessions, test_name, _NO_PAGE_QUERY)

    return item_asking(items_of(test_page), question)


def _test_name_of(sessions: Sessions, test_id: uuid.UUID) -> str:
    with sessions() as session:
        stored_test = session.get(Test, test_id)

    if stored_test is None:
        raise LookupError(test_id)

    return stored_test.name


def answer_request(
    test_item: TestItemPayload, test_session: object, answer: object
) -> dict[str, object]:
    return {
        "test_item_id": test_item["id"],
        "test_session": test_session,
        "answers": [answer],
    }


def session_results(client: TestClient, test_session: str) -> Response:
    return client.get(
        _SESSION_RESULTS,
        params={"test_session": test_session},
        headers=authorization(),
    )


@given(parsers.parse('I have the test "{test_name}" in "{folder_name}"'))
def create_test_in_folder(
    sessions: Sessions, test_name: str, folder_name: str
) -> None:
    seeded_test(sessions, folder_id_named(sessions, folder_name), test_name)


@given(parsers.parse(_ONLY_OPTION_STEP))
def add_single_option_question(
    sessions: Sessions, test_name: str, question: str, option_text: str
) -> None:
    test_id = unit_id_named(sessions, Test, test_name)
    question_content: dict[str, object] = {
        "question": question,
        "true_option": option_text,
    }
    seed_item(sessions, test_id, question_content)


@when(
    parsers.parse(
        'I open the test "{test_name}" with the session I answered in'
    ),
    target_fixture="reopened_test",
)
def reopen_with_session(
    client: TestClient, sessions: Sessions, test_name: str
) -> ReplyBody:
    test_page = opened_test(client, sessions, test_name, _NO_PAGE_QUERY)
    session_query: dict[str, str | int] = {
        "test_session": str(test_page["test_session"])
    }

    return opened_test(client, sessions, test_name, session_query)


@when(
    parsers.parse(
        'I open the test "{test_name}" with the session of "{other_test}"'
    ),
    target_fixture="reply",
)
def open_with_foreign_session(
    client: TestClient, sessions: Sessions, test_name: str, other_test: str
) -> Response:
    other_page = opened_test(client, sessions, other_test, _NO_PAGE_QUERY)
    test_query = {
        "test_id": unit_id_named(sessions, Test, test_name),
        "test_session": str(other_page["test_session"]),
    }

    return client.get(TEST_ITEMS, params=test_query, headers=authorization())


@when(
    parsers.parse(
        'I answer "{question}" with "{option_text}" in an unknown session'
    ),
    target_fixture="reply",
)
def answer_in_unknown_session(
    client: TestClient, sessions: Sessions, question: str, option_text: str
) -> Response:
    test_item = question_in_its_test(client, sessions, question)
    chosen_option = option_id(test_item, option_text)
    unknown_session = str(uuid.uuid4())
    review_request = answer_request(test_item, unknown_session, chosen_option)

    return review(client, authorization(), review_request)


@when(
    parsers.parse('another user answers "{question}" with "{option_text}"'),
    target_fixture="reply",
)
def answer_as_stranger(
    client: TestClient, sessions: Sessions, question: str, option_text: str
) -> Response:
    test_item = question_in_its_test(client, sessions, question)
    chosen_option = option_id(test_item, option_text)
    stranger_session = str(uuid.uuid4())
    review_request = answer_request(test_item, stranger_session, chosen_option)

    return review(client, stranger_headers(), review_request)


@when(
    parsers.parse(
        'I ask how many questions I have mastered in "{folder_name}"'
    ),
    target_fixture="reply",
)
def ask_folder_mastery(
    client: TestClient, sessions: Sessions, folder_name: str
) -> Response:
    folder_id = folder_id_named(sessions, folder_name)

    return client.get(
        _TEST_ITEMS_STATS,
        params={"folder_id": folder_id},
        headers=authorization(),
    )


@when(
    parsers.parse('I finish the test "{test_name}" without answering'),
    target_fixture="reply",
)
def finish_without_answering(
    client: TestClient, sessions: Sessions, test_name: str
) -> Response:
    test_page = opened_test(client, sessions, test_name, _NO_PAGE_QUERY)

    return session_results(client, str(test_page["test_session"]))


@then(parsers.parse('"{question}" offers only "{option_text}"'))
def check_only_option(
    reopened_test: ReplyBody, question: str, option_text: str
) -> None:
    test_item = item_asking(items_of(reopened_test), question)
    content = cast("dict[str, object]", test_item["content"])
    options = cast("list[dict[str, object]]", content["shuffled_options"])
    offered: list[object] = []

    for option in options:
        offered.append(option["option"])

    assert offered == [option_text]


@when(parsers.parse(_NUMBER_ANSWER_STEP))
def send_number_answer(
    client: TestClient,
    sessions: Sessions,
    number: int,
    question: str,
    test_name: str,
) -> None:
    test_page = opened_test(client, sessions, test_name, _NO_PAGE_QUERY)
    test_item = item_asking(items_of(test_page), question)
    review_request = answer_request(
        test_item, test_page["test_session"], number
    )
    reply = review(client, authorization(), review_request)
    _ = reply.raise_for_status()
