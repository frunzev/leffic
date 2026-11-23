from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import parsers, then, when

from tests.requirements.assessment_lookup import (
    TEST_ITEMS,
    FinishedTest,
    item_asking,
    items_of,
    option_id,
    question_of,
)
from tests.requirements.assessment_session_steps import (
    answer_request,
    question_in_its_test,
    review,
    session_results,
)
from tests.requirements.requirement_listing import HOME
from tests.requirements.requirement_lookup import (
    ReplyBody,
    Sessions,
    folder_id_named,
    reply_body,
)
from tests.support import authorization

_FOLDER_ANSWER_STEP = (
    'I answer "{question}" with "{option_text}" in the questions of '
    '"{folder_name}"'
)


def _folder_page(client: TestClient, folder_id: str) -> ReplyBody:
    reply = client.get(
        TEST_ITEMS, params={"folder_id": folder_id}, headers=authorization()
    )

    return reply_body(reply)


@when("I open the questions of home", target_fixture="folder_page")
def open_home_questions(client: TestClient) -> ReplyBody:
    return _folder_page(client, HOME)


@then(parsers.parse('I see the questions "{first}" and "{second}"'))
def check_folder_questions(
    folder_page: ReplyBody, first: str, second: str
) -> None:
    seen_questions: set[str] = set()

    for test_item in items_of(folder_page):
        seen_questions.add(question_of(test_item))

    assert seen_questions == {first, second}


@when(
    parsers.parse(
        'I answer "{question}" with "{option_text}" in the questions of home'
    )
)
def answer_in_home_questions(
    client: TestClient, question: str, option_text: str
) -> None:
    folder_page = _folder_page(client, HOME)
    test_item = item_asking(items_of(folder_page), question)
    chosen_option = option_id(test_item, option_text)
    review_request = answer_request(
        test_item, folder_page["test_session"], chosen_option
    )
    reply = review(client, authorization(), review_request)
    _ = reply.raise_for_status()


@when(parsers.parse(_FOLDER_ANSWER_STEP), target_fixture="reply")
def answer_in_folder_questions(
    client: TestClient,
    sessions: Sessions,
    question: str,
    option_text: str,
    folder_name: str,
) -> Response:
    folder_page = _folder_page(client, folder_id_named(sessions, folder_name))
    test_item = question_in_its_test(client, sessions, question)
    chosen_option = option_id(test_item, option_text)
    review_request = answer_request(
        test_item, folder_page["test_session"], chosen_option
    )

    return review(client, authorization(), review_request)


@when("I finish the questions of home", target_fixture="finished_test")
def finish_home_questions(client: TestClient) -> FinishedTest:
    folder_session = str(_folder_page(client, HOME)["test_session"])
    reply = session_results(client, folder_session)

    return FinishedTest(session=folder_session, results=reply_body(reply))


@when(
    "I ask for questions without naming a test or folder",
    target_fixture="reply",
)
def ask_for_unnamed_questions(client: TestClient) -> Response:
    return client.get(TEST_ITEMS, headers=authorization())
