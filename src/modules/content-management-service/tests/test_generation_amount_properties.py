import uuid
from collections.abc import Callable
from typing import cast
from unittest import mock

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st
from pydantic import ValidationError
from sqlalchemy.orm import Session

from features.study_units_generation import generation_router
from features.study_units_generation.generation_request import (
    FlashcardsMetadata,
    GenerationRequest,
    TestMetadata,
)
from features.study_units_generation.generation_router import (
    _queued_flashcards,
    _queued_test,
)
from features.study_units_generation.study_unit_source import (
    StudyUnitSource,
)
from features.study_units_generation.task_token_contracts import (
    TaskTokenSigner,
)
from tests.folder_seeding import seeded_folder
from tests.property_fakes import RecordingQueuedTask
from tests.property_support import property_world
from tests.support import authorization, in_memory_sessions
from tests.task_token_support import TASK_TOKENS

type TypeAmounts = dict[str, int]
type QueuedJobs = Callable[
    [GenerationRequest, str, Session, StudyUnitSource, TaskTokenSigner],
    dict[str, object],
]

_UNPROCESSABLE = 422
_DEFAULT_TEST_AMOUNT = 10
_FLASHCARDS_TASK = "generate_flashcards_of_type_task"
_TEST_TASK = "generate_test_items_of_type_task"
_CLIENT, _ = property_world()
_SESSIONS = in_memory_sessions()
_NO_SOURCE = StudyUnitSource(kind=None, reference=None)
_FLASHCARD_TYPE_NAMES = ("basic", "cloze", "feynman", "list")
_TEST_ITEM_TYPE_NAMES = ("multiple_choice", "true_or_false", "short_answer")
_TEST_ITEM_TYPES = st.sampled_from(_TEST_ITEM_TYPE_NAMES)
_KIND_TASKS = {
    "flashcards": (_FLASHCARD_TYPE_NAMES, _FLASHCARDS_TASK),
    "test": (_TEST_ITEM_TYPE_NAMES, _TEST_TASK),
}
_KINDS = st.sampled_from(sorted(_KIND_TASKS))
_AMOUNTS = st.integers(min_value=1, max_value=200)


@st.composite
def _types_with_amounts(
    draw: st.DrawFn, type_names: tuple[str, ...]
) -> tuple[list[str], TypeAmounts]:
    types = draw(
        st.lists(st.sampled_from(type_names), min_size=1, unique=True)
    )
    amounts: TypeAmounts = {}

    for type_name in types:
        amount = draw(st.none() | _AMOUNTS)

        if amount is not None:
            amounts[type_name] = amount

    return types, amounts


@st.composite
def _kind_with_unrequested_amount(
    draw: st.DrawFn,
) -> tuple[str, list[str], TypeAmounts]:
    kind = draw(_KINDS)
    type_names, _task_name = _KIND_TASKS[kind]
    types: list[str] = draw(
        st.lists(
            st.sampled_from(type_names),
            max_size=len(type_names) - 1,
            unique=True,
        )
    )
    unnamed_types = [name for name in type_names if name not in types]
    unrequested_type = draw(st.sampled_from(unnamed_types))
    amounts = {type_name: draw(_AMOUNTS) for type_name in types}
    amounts[unrequested_type] = draw(_AMOUNTS)

    return kind, types, amounts


def _queued_calls(
    queue_jobs: QueuedJobs,
    task_name: str,
    request_data: GenerationRequest,
    owner: uuid.UUID,
) -> list[dict[str, object]]:
    queued_task = RecordingQueuedTask("queued")

    with _SESSIONS() as session:
        folder_id = seeded_folder(session, owner, {})

        with mock.patch.object(generation_router, task_name, queued_task):
            _ = queue_jobs(
                request_data,
                str(folder_id),
                session,
                _NO_SOURCE,
                TASK_TOKENS,
            )

    return queued_task.calls


def _posted_status(
    owner: uuid.UUID, kind: str, wanted: dict[str, object]
) -> tuple[int, list[dict[str, object]]]:
    _type_names, task_name = _KIND_TASKS[kind]
    queued_task = RecordingQueuedTask("queued")

    with mock.patch.object(generation_router, task_name, queued_task):
        response = _CLIENT.post(
            "/generate-study-units",
            json={"text": "material", "folder_id": "home", kind: wanted},
            headers=authorization(str(owner)),
        )

    return response.status_code, queued_task.calls


@settings(max_examples=25, deadline=None)
@given(st.uuids(), _types_with_amounts(_FLASHCARD_TYPE_NAMES))
def test__queued_flashcards_property_gives_every_type_its_own_amount(
    owner: uuid.UUID, wanted: tuple[list[str], TypeAmounts]
) -> None:
    types, amounts = wanted
    request_data = GenerationRequest(
        text="material",
        flashcards=FlashcardsMetadata.model_validate(
            {"types": types, "amounts": amounts}
        ),
    )

    calls = _queued_calls(
        _queued_flashcards, _FLASHCARDS_TASK, request_data, owner
    )
    sent_amounts = [
        cast("dict[str, object]", call["settings"])["amount"]
        for call in calls
    ]

    assert sent_amounts == [amounts.get(name) for name in types]


@settings(max_examples=25, deadline=None)
@given(st.uuids(), _types_with_amounts(_TEST_ITEM_TYPE_NAMES))
def test__queued_test_property_gives_every_type_its_own_amount(
    owner: uuid.UUID, wanted: tuple[list[str], TypeAmounts]
) -> None:
    types, amounts = wanted
    request_data = GenerationRequest(
        text="material",
        test=TestMetadata.model_validate(
            {"types": types, "amounts": amounts}
        ),
    )

    calls = _queued_calls(_queued_test, _TEST_TASK, request_data, owner)
    sent_amounts = [call["amount"] for call in calls]

    assert sent_amounts == [
        amounts.get(name, _DEFAULT_TEST_AMOUNT) for name in types
    ]


@settings(max_examples=50, deadline=None)
@given(
    st.none() | st.lists(_TEST_ITEM_TYPES, unique=True),
    st.dictionaries(_TEST_ITEM_TYPES, _AMOUNTS),
)
def test_validated_amounts_property_refuses_only_unnamed_types(
    types: list[str] | None, amounts: TypeAmounts
) -> None:
    wanted = {"types": types, "amounts": amounts}
    unrequested_types = set(amounts) - set(types or ())

    if not unrequested_types:
        validated = TestMetadata.model_validate(wanted)

        assert validated.amounts == amounts
        return

    with pytest.raises(ValidationError):
        _ = TestMetadata.model_validate(wanted)


@settings(max_examples=25, deadline=None)
@given(st.uuids(), _kind_with_unrequested_amount())
def test_generate_study_units_property_queues_nothing_for_unasked_types(
    owner: uuid.UUID, example: tuple[str, list[str], TypeAmounts]
) -> None:
    kind, types, amounts = example

    status, calls = _posted_status(
        owner, kind, {"types": types, "amounts": amounts}
    )

    assert status == _UNPROCESSABLE
    assert calls == []


@settings(max_examples=25, deadline=None)
@given(st.uuids(), _KINDS, st.integers(max_value=0))
def test_generate_study_units_property_refuses_an_amount_below_one(
    owner: uuid.UUID, kind: str, amount: int
) -> None:
    type_name = _KIND_TASKS[kind][0][0]

    status, calls = _posted_status(
        owner, kind, {"types": [type_name], "amounts": {type_name: amount}}
    )

    assert status == _UNPROCESSABLE
    assert calls == []


@settings(max_examples=25, deadline=None)
@given(st.uuids(), _KINDS, _AMOUNTS)
def test_generate_study_units_property_refuses_one_amount_for_a_kind(
    owner: uuid.UUID, kind: str, amount: int
) -> None:
    type_name = _KIND_TASKS[kind][0][0]

    status, calls = _posted_status(
        owner, kind, {"types": [type_name], "amount": amount}
    )

    assert status == _UNPROCESSABLE
    assert calls == []
