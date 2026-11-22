from fastapi.testclient import TestClient
from pytest_bdd import parsers, then, when

from tests.requirements.assessment_lookup import (
    FinishedTest,
    item_asking,
    items_of,
    opened_test,
    option_id,
    question_of,
)
from tests.requirements.requirement_lookup import (
    ReplyBody,
    Sessions,
    reply_body,
    stored_question,
)
from tests.support import authorization

_REVIEW_TEST_ITEM = "/review-test-item"
_SESSION_RESULTS = "/test-session-results"
_ANSWER_STEP = (
    'I answer "{question}" with "{option_text}" in the test "{test_name}"'
)
_TYPE_STEP = (
    'I type "{typed_answer}" for "{question}" in the test "{test_name}"'
)
_RETRY_STEP = (
    'retrying the missed questions of "{test_name}" asks only "{question}"'
)
_NO_PAGE_QUERY: dict[str, str | int] = {}


def _answered(
    client: TestClient, test_page: ReplyBody, item_id: object, answer: object
) -> None:
    review_request = {
        "test_item_id": item_id,
        "test_session": test_page["test_session"],
        "answers": [answer],
    }
    reply = client.post(
        _REVIEW_TEST_ITEM, json=review_request, headers=authorization()
    )
    _ = reply.raise_for_status()


def _retried_questions(
    client: TestClient,
    sessions: Sessions,
    finished_test: FinishedTest,
    test_name: str,
) -> list[str]:
    retry_query: dict[str, str | int] = {
        "missed_in_session": finished_test.session
    }
    retry_page = opened_test(client, sessions, test_name, retry_query)
    retried_questions: list[str] = []

    for test_item in items_of(retry_page):
        retried_questions.append(question_of(test_item))

    return retried_questions


@when(parsers.parse(_ANSWER_STEP))
def answer_question(
    client: TestClient,
    sessions: Sessions,
    question: str,
    option_text: str,
    test_name: str,
) -> None:
    test_page = opened_test(client, sessions, test_name, _NO_PAGE_QUERY)
    test_item = item_asking(items_of(test_page), question)
    chosen_option = option_id(test_item, option_text)
    _answered(client, test_page, test_item["id"], chosen_option)


@when(parsers.parse(_TYPE_STEP))
def type_answer(
    client: TestClient,
    sessions: Sessions,
    typed_answer: str,
    question: str,
    test_name: str,
) -> None:
    test_page = opened_test(client, sessions, test_name, _NO_PAGE_QUERY)
    test_item = item_asking(items_of(test_page), question)
    _answered(client, test_page, test_item["id"], typed_answer)


@when(
    parsers.parse('I finish the test "{test_name}"'),
    target_fixture="finished_test",
)
def finish_test(
    client: TestClient, sessions: Sessions, test_name: str
) -> FinishedTest:
    test_page = opened_test(client, sessions, test_name, _NO_PAGE_QUERY)
    test_session = str(test_page["test_session"])
    reply = client.get(
        _SESSION_RESULTS,
        params={"test_session": test_session},
        headers=authorization(),
    )

    return FinishedTest(session=test_session, results=reply_body(reply))


@when(
    parsers.parse('I open the test "{test_name}" again'),
    target_fixture="reopened_test",
)
def reopen_test(
    client: TestClient, sessions: Sessions, test_name: str
) -> ReplyBody:
    return opened_test(client, sessions, test_name, _NO_PAGE_QUERY)


@then(parsers.parse("I got {correct_count:d} answer right and missed none"))
def check_score(finished_test: FinishedTest, correct_count: int) -> None:
    assert finished_test.results["correct"] == correct_count
    assert finished_test.results["missed_item_ids"] == []


@then(
    parsers.parse(
        'I got {correct_count:d} answers right and missed "{question}"'
    )
)
def check_missed_score(
    sessions: Sessions,
    finished_test: FinishedTest,
    correct_count: int,
    question: str,
) -> None:
    missed_item = stored_question(sessions, question)

    assert finished_test.results["correct"] == correct_count
    assert finished_test.results["missed_item_ids"] == [missed_item.id]


@then(parsers.parse('"{question}" still shows my answer "{option_text}"'))
def check_answer_kept(
    reopened_test: ReplyBody, question: str, option_text: str
) -> None:
    test_item = item_asking(items_of(reopened_test), question)

    assert test_item["last_answers"] == [option_id(test_item, option_text)]


@then(parsers.parse('"{question}" has no answer yet'))
def check_no_answer(reopened_test: ReplyBody, question: str) -> None:
    test_item = item_asking(items_of(reopened_test), question)

    assert not test_item["last_answers"]


@then(parsers.parse(_RETRY_STEP))
def check_retry_asks_missed(
    client: TestClient,
    sessions: Sessions,
    finished_test: FinishedTest,
    test_name: str,
    question: str,
) -> None:
    retried = _retried_questions(client, sessions, finished_test, test_name)

    assert retried == [question]


@then(
    parsers.parse(
        'retrying the missed questions of "{test_name}" asks nothing'
    )
)
def check_retry_asks_nothing(
    client: TestClient,
    sessions: Sessions,
    finished_test: FinishedTest,
    test_name: str,
) -> None:
    retried = _retried_questions(client, sessions, finished_test, test_name)

    assert retried == []
