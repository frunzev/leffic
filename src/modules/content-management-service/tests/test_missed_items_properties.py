import uuid
from typing import cast

from hypothesis import given, settings
from hypothesis import strategies as st

from features.study_units.assessment_queries import missed_item_ids
from tests.assessment_seeding import seeded_test
from tests.property_support import property_world
from tests.session_ownership_support import (
    CORRECT_ANSWER,
    MISSING_SESSION_DETAIL,
    NO_TEST_STATS_DETAIL,
    NOT_FOUND,
    OK,
    WRONG_ANSWER,
)
from tests.study_unit_access_support import opened_test_session
from tests.support import authorization

_CLIENT, _SESSIONS = property_world()
_ANSWER_PLANS = st.lists(
    st.one_of(st.none(), st.booleans()), min_size=1, max_size=4
)

ItemsBody = dict[str, object]


def _answered_session(
    owner: uuid.UUID, answer_plan: list[bool | None]
) -> tuple[uuid.UUID, uuid.UUID, list[int]]:
    with _SESSIONS() as session:
        _, test_id, item_ids = seeded_test(session, owner, len(answer_plan))
        session_id = opened_test_session(session, owner, test_id)

    for item_id, is_right in zip(item_ids, answer_plan, strict=True):
        if is_right is None:
            continue

        answers = CORRECT_ANSWER if is_right else WRONG_ANSWER
        _ = _CLIENT.post(
            "/review-test-item",
            json={
                "test_item_id": item_id,
                "test_session": str(session_id),
                "answers": answers,
            },
            headers=authorization(str(owner)),
        )

    return test_id, session_id, item_ids


def _wrongly_answered(
    item_ids: list[int], answer_plan: list[bool | None]
) -> list[int]:
    wrong_ids: list[int] = []

    for item_id, is_right in zip(item_ids, answer_plan, strict=True):
        if is_right is False:
            wrong_ids.append(item_id)

    return wrong_ids


def _session_results(
    owner: uuid.UUID, session_id: uuid.UUID
) -> tuple[int, ItemsBody]:
    response = _CLIENT.get(
        "/test-session-results",
        params={"test_session": str(session_id)},
        headers=authorization(str(owner)),
    )

    return response.status_code, cast("ItemsBody", response.json())


def _missed_items(
    owner: uuid.UUID, test_id: uuid.UUID, finished_session: str
) -> tuple[int, ItemsBody]:
    response = _CLIENT.get(
        "/test-items",
        params={
            "test_id": str(test_id),
            "missed_in_session": finished_session,
            "per_page": 10,
        },
        headers=authorization(str(owner)),
    )

    return response.status_code, cast("ItemsBody", response.json())


def _item_ids_of(body: ItemsBody) -> list[int]:
    listed_ids: list[int] = []

    for item in cast("list[dict[str, int]]", body["test_items"]):
        listed_ids.append(item["id"])

    return listed_ids


@settings(max_examples=25, deadline=None)
@given(st.uuids(), _ANSWER_PLANS)
def test_missed_item_ids_property_lists_exactly_the_wrong_answers(
    owner: uuid.UUID, answer_plan: list[bool | None]
) -> None:
    _, session_id, item_ids = _answered_session(owner, answer_plan)

    with _SESSIONS() as session:
        listed = list(session.scalars(missed_item_ids(session_id)).all())

    assert listed == _wrongly_answered(item_ids, answer_plan)


@settings(max_examples=25, deadline=None)
@given(st.uuids(), _ANSWER_PLANS)
def test_test_session_results_property_reports_every_wrong_answer(
    owner: uuid.UUID, answer_plan: list[bool | None]
) -> None:
    _, session_id, item_ids = _answered_session(owner, answer_plan)
    wrong_ids = _wrongly_answered(item_ids, answer_plan)
    right_count = answer_plan.count(True)

    code, body = _session_results(owner, session_id)

    if right_count == 0 and not wrong_ids:
        assert code == NOT_FOUND
        assert body == {"msg": NO_TEST_STATS_DETAIL}
    else:
        assert code == OK
        assert body == {"correct": right_count, "missed_item_ids": wrong_ids}


@settings(max_examples=25, deadline=None)
@given(st.uuids(), _ANSWER_PLANS)
def test_get_test_items_property_reviews_only_the_missed_items(
    owner: uuid.UUID, answer_plan: list[bool | None]
) -> None:
    test_id, session_id, item_ids = _answered_session(owner, answer_plan)
    _ = _session_results(owner, session_id)

    code, body = _missed_items(owner, test_id, str(session_id))
    wrong_ids = _wrongly_answered(item_ids, answer_plan)

    assert code == OK
    assert body["total_items"] == len(wrong_ids)
    assert _item_ids_of(body) == wrong_ids
    assert body["test_session"] != str(session_id)


@settings(max_examples=25, deadline=None)
@given(st.uuids(), st.uuids(), st.sampled_from(["", "not-a-uuid", "home"]))
def test__requested_items_property_refuses_a_session_it_cannot_read(
    owner: uuid.UUID, stranger: uuid.UUID, unreadable: str
) -> None:
    with _SESSIONS() as session:
        _, test_id, _ = seeded_test(session, owner, 1)
        _, other_test_id, _ = seeded_test(session, owner, 1)
        foreign_session = opened_test_session(session, stranger, test_id)
        other_origin_session = opened_test_session(
            session, owner, other_test_id
        )

    refused_sessions = (
        str(foreign_session),
        str(other_origin_session),
        str(uuid.uuid4()),
        unreadable,
    )

    for refused_session in refused_sessions:
        code, body = _missed_items(owner, test_id, refused_session)

        assert code == NOT_FOUND
        assert body == {"detail": MISSING_SESSION_DETAIL}
