import uuid
from datetime import datetime

from hypothesis import given, settings
from hypothesis import strategies as st
from sqlalchemy import select

from features.file_system.child_summaries import (
    ChildSummary,
    _children_of,
    child_summaries,
)
from shared.models import Folder
from tests.folder_seeding import KINDS, seeded_folder
from tests.support import in_memory_sessions
from tests.unit_details_seeding import (
    CHILD_KINDS,
    MOMENTS,
    DatedChild,
    seeded_dated_children,
)

_SESSIONS = in_memory_sessions()
_DATED_CHILDREN = st.lists(st.tuples(CHILD_KINDS, MOMENTS), max_size=5)
_COUNTS = st.fixed_dictionaries(
    {kind: st.integers(min_value=0, max_value=2) for kind in KINDS}
)


def _newest_of(dated_children: list[DatedChild]) -> datetime:
    newest = dated_children[0][1]

    for _, created_at in dated_children:
        newest = max(newest, created_at)

    return newest


@settings(max_examples=25, deadline=None)
@given(st.lists(_DATED_CHILDREN, max_size=3))
def test_child_summaries_property_counts_and_dates_every_direct_child(
    children_per_subfolder: list[list[DatedChild]],
) -> None:
    owner = uuid.uuid4()

    with _SESSIONS() as session:
        parent_id = seeded_folder(session, owner, {})
        subfolder_ids: list[uuid.UUID] = []

        for dated_children in children_per_subfolder:
            subfolder_id = seeded_folder(
                session, owner, {}, parent_id=parent_id
            )
            seeded_dated_children(session, owner, subfolder_id, dated_children)
            subfolder_ids.append(subfolder_id)

        summaries = child_summaries(session, str(parent_id))

    for subfolder_id, dated_children in zip(
        subfolder_ids, children_per_subfolder, strict=True
    ):
        if not dated_children:
            assert subfolder_id not in summaries
            continue

        assert summaries[subfolder_id] == ChildSummary(
            item_count=len(dated_children),
            newest_created_at=_newest_of(dated_children),
        )


@settings(max_examples=25, deadline=None)
@given(_COUNTS, _COUNTS)
def test_child_summaries_property_never_counts_grandchildren(
    child_counts: dict[str, int], grandchild_counts: dict[str, int]
) -> None:
    owner = uuid.uuid4()

    with _SESSIONS() as session:
        parent_id = seeded_folder(session, owner, {})
        subfolder_id = seeded_folder(
            session, owner, child_counts, parent_id=parent_id
        )
        _ = seeded_folder(
            session, owner, grandchild_counts, parent_id=subfolder_id
        )
        summaries = child_summaries(session, str(parent_id))

    assert set(summaries) == {subfolder_id}
    assert summaries[subfolder_id].item_count == (
        sum(child_counts.values()) + 1
    )


@settings(max_examples=25, deadline=None)
@given(_COUNTS)
def test__children_of_property_yields_one_row_per_direct_child(
    counts: dict[str, int],
) -> None:
    owner = uuid.uuid4()

    with _SESSIONS() as session:
        folder_id = seeded_folder(session, owner, counts)
        listed_folder = select(Folder.id).where(Folder.id == folder_id)
        children = session.execute(_children_of(listed_folder)).all()

    assert len(children) == sum(counts.values())
