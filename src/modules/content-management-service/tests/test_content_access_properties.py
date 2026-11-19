import asyncio
import json
import uuid
from typing import cast

import pytest
from fastapi import HTTPException
from hypothesis import given, settings
from hypothesis import strategies as st

from features.scheduling.rating_intervals_router import (
    RatingIntervalsRequest,
    rating_intervals,
)
from shared.content_access import owned_content
from shared.file_access import owned_file
from shared.models import File
from tests.property_support import property_world, seeded_file

_NOT_FOUND = 404
_MISSING = "File does not exist!"
_CLIENT, _SESSIONS = property_world()


@settings(max_examples=25, deadline=None)
@given(st.uuids(), st.uuids())
def test_owned_content_property_never_reaches_a_strangers_unit(
    owner: uuid.UUID, stranger: uuid.UUID
) -> None:
    with _SESSIONS() as session:
        file_id = seeded_file(session, owner)
        mine = owned_content(session, str(owner), File, str(file_id), _MISSING)

        assert mine.id == file_id

        with pytest.raises(HTTPException) as raised:
            _ = owned_content(
                session, str(stranger), File, str(file_id), _MISSING
            )

    assert raised.value.status_code == _NOT_FOUND


@settings(max_examples=25, deadline=None)
@given(st.uuids(), st.uuids())
def test_owned_file_property_never_reaches_a_strangers_file(
    owner: uuid.UUID, stranger: uuid.UUID
) -> None:
    with _SESSIONS() as session:
        file_id = seeded_file(session, owner)

        assert owned_file(session, str(owner), str(file_id)).id == file_id

        with pytest.raises(HTTPException) as raised:
            _ = owned_file(session, str(stranger), str(file_id))

    assert raised.value.status_code == _NOT_FOUND


@settings(max_examples=25, deadline=None)
@given(st.uuids())
def test_rating_intervals_property_answers_with_every_rating(
    user_id: uuid.UUID,
) -> None:
    response = asyncio.run(
        rating_intervals(RatingIntervalsRequest(card=None), str(user_id))
    )
    intervals = cast("dict[str, int]", json.loads(bytes(response.body)))

    assert sorted(int(rating) for rating in intervals) == [1, 2, 3, 4]
    assert all(seconds >= 0 for seconds in intervals.values())
