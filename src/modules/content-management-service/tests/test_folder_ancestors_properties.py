import uuid

from hypothesis import given, settings
from hypothesis import strategies as st

from features.file_system.folder_ancestors import folder_ancestors
from tests.support import in_memory_sessions
from tests.unit_details_seeding import FOLDER_NAMES, seeded_folder_chain

_SESSIONS = in_memory_sessions()
_CHAIN_NAMES = st.lists(FOLDER_NAMES, min_size=1, max_size=5)


@settings(max_examples=25, deadline=None)
@given(_CHAIN_NAMES)
def test_folder_ancestors_property_walks_from_the_root_to_the_parent(
    names: list[str],
) -> None:
    owner = uuid.uuid4()

    with _SESSIONS() as session:
        chain = seeded_folder_chain(session, owner, names)
        crumbs = folder_ancestors(session, str(chain[-1]), str(owner))

    expected: list[dict[str, str]] = []

    for folder_id, name in zip(chain[:-1], names[:-1], strict=True):
        expected.append({"id": str(folder_id), "name": name})

    assert crumbs == expected


@settings(max_examples=25, deadline=None)
@given(_CHAIN_NAMES, st.uuids())
def test_folder_ancestors_property_never_walks_a_strangers_folders(
    names: list[str], stranger: uuid.UUID
) -> None:
    owner = uuid.uuid4()

    with _SESSIONS() as session:
        chain = seeded_folder_chain(session, owner, names)
        crumbs = folder_ancestors(session, str(chain[-1]), str(stranger))

    assert crumbs == []
