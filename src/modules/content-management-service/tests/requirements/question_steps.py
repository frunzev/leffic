from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from shared.models import Test
from tests.requirements.assessment_lookup import (
    items_of,
    opened_test,
    question_of,
)
from tests.requirements.requirement_listing import HOME
from tests.requirements.requirement_lookup import (
    ReplyBody,
    Sessions,
    home_folder_id,
    reply_body,
    stored_question,
    unit_id_named,
)
from tests.requirements.requirement_seeding import (
    seeded_question,
    seeded_short_answer,
    seeded_statement,
    seeded_test,
)
from tests.support import authorization

_UPDATE_TEST_ITEM = "/update-test-item"
_TEST_ITEMS_STATS = "/test-items-stats"
_NUMBERED_QUESTION = "Question number {number}"
_NUMBERED_RIGHT_OPTION = "right"
_NUMBERED_WRONG_OPTION = "wrong"
_QUESTION_STEP = (
    '"{test_name}" asks "{question}" '
    'with "{right_option}" right and "{wrong_option}" wrong'
)
_PAGE_STEP = (
    'I open page {page:d} of the test "{test_name}" '
    "with {per_page:d} questions per page"
)
_NO_PAGE_QUERY: dict[str, str | int] = {}


def _updated_question(
    client: TestClient, item_id: int, question_content: dict[str, object]
) -> None:
    update_request = {"test_item_id": item_id, "content": question_content}
    reply = client.patch(
        _UPDATE_TEST_ITEM, json=update_request, headers=authorization()
    )
    _ = reply.raise_for_status()


@given(parsers.parse('I have the test "{test_name}" in home'))
def create_test_in_home(sessions: Sessions, test_name: str) -> None:
    seeded_test(sessions, home_folder_id(sessions), test_name)


@given(parsers.parse(_QUESTION_STEP))
def add_question(
    sessions: Sessions,
    test_name: str,
    question: str,
    right_option: str,
    wrong_option: str,
) -> None:
    test_id = unit_id_named(sessions, Test, test_name)
    seeded_question(sessions, test_id, question, (right_option, wrong_option))


@given(parsers.parse('"{test_name}" states "{statement}" which is true'))
def add_true_statement(
    sessions: Sessions, test_name: str, statement: str
) -> None:
    test_id = unit_id_named(sessions, Test, test_name)
    seeded_statement(sessions, test_id, statement, is_true=True)


@given(parsers.parse('"{test_name}" asks "{question}" expecting "{answer}"'))
def add_short_answer_question(
    sessions: Sessions, test_name: str, question: str, answer: str
) -> None:
    test_id = unit_id_named(sessions, Test, test_name)
    seeded_short_answer(sessions, test_id, question, answer)


@given(parsers.parse('"{test_name}" has {question_count:d} questions'))
def add_numbered_questions(
    sessions: Sessions, test_name: str, question_count: int
) -> None:
    test_id = unit_id_named(sessions, Test, test_name)
    options = (_NUMBERED_RIGHT_OPTION, _NUMBERED_WRONG_OPTION)

    for number in range(1, question_count + 1):
        question = _NUMBERED_QUESTION.format(number=number)
        seeded_question(sessions, test_id, question, options)


@when(parsers.parse('I reword "{question}" as "{new_question}"'))
def reword_question(
    client: TestClient, sessions: Sessions, question: str, new_question: str
) -> None:
    stored_item = stored_question(sessions, question)
    question_content = {**stored_item.content, "question": new_question}
    _updated_question(client, stored_item.id, question_content)


@when(parsers.parse('I change the right answer of "{question}" to "{answer}"'))
def change_right_answer(
    client: TestClient, sessions: Sessions, question: str, answer: str
) -> None:
    stored_item = stored_question(sessions, question)
    question_content = {**stored_item.content, "true_option": answer}
    _updated_question(client, stored_item.id, question_content)


@then(parsers.parse('the test "{test_name}" asks "{question}"'))
def check_test_asks(
    client: TestClient, sessions: Sessions, test_name: str, question: str
) -> None:
    test_page = opened_test(client, sessions, test_name, _NO_PAGE_QUERY)
    asked_questions: list[str] = []

    for test_item in items_of(test_page):
        asked_questions.append(question_of(test_item))

    assert question in asked_questions


@when(parsers.parse(_PAGE_STEP), target_fixture="reopened_test")
def open_test_page(
    client: TestClient,
    sessions: Sessions,
    page: int,
    test_name: str,
    per_page: int,
) -> ReplyBody:
    page_query: dict[str, str | int] = {"page": page, "per_page": per_page}

    return opened_test(client, sessions, test_name, page_query)


@then(parsers.parse("I see {shown_count:d} of {total_count:d} questions"))
def check_page_size(
    reopened_test: ReplyBody, shown_count: int, total_count: int
) -> None:
    assert len(items_of(reopened_test)) == shown_count
    assert reopened_test["total_items"] == total_count


@when(
    "I ask how many questions I have mastered in home",
    target_fixture="reply",
)
def ask_mastered_counts(client: TestClient) -> Response:
    return client.get(
        _TEST_ITEMS_STATS, params={"folder_id": HOME}, headers=authorization()
    )


@then(
    parsers.parse(
        "home has {mastered_count:d} of {total_count:d} questions mastered"
    )
)
def check_mastered_counts(
    reply: Response, mastered_count: int, total_count: int
) -> None:
    question_counts = reply_body(reply)

    assert question_counts["correct"] == mastered_count
    assert question_counts["total"] == total_count
