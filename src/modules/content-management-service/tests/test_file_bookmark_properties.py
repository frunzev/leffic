import uuid
from typing import cast

from fastapi import FastAPI
from hypothesis import given, settings
from hypothesis import strategies as st

from features.file_system.pdf_page_count import provide_stored_pdf_pages
from shared.models import File
from tests.file_storage_fakes import FixedPdfPages
from tests.property_support import property_world, seeded_file
from tests.support import authorization

_OK = 200
_NOT_FOUND = 404
_PAGES = st.integers(min_value=1, max_value=500)
_PAGE_COUNTS = st.integers(min_value=1, max_value=900)
_CLIENT, _SESSIONS = property_world()


def _counting_pages(page_count: int) -> None:
    application = cast("FastAPI", _CLIENT.app)
    overrides = application.dependency_overrides
    overrides[provide_stored_pdf_pages] = lambda: FixedPdfPages(page_count)


def _bookmarked(owner: uuid.UUID, page: int | None) -> uuid.UUID:
    with _SESSIONS() as session:
        return seeded_file(session, owner, page)


@settings(max_examples=25, deadline=None)
@given(st.uuids(), st.one_of(st.none(), _PAGES), _PAGE_COUNTS)
def test_get_file_bookmark_property_reports_the_page_that_was_stored(
    owner: uuid.UUID, page: int | None, page_count: int
) -> None:
    file_id = _bookmarked(owner, page)
    _counting_pages(page_count)
    response = _CLIENT.get(
        "/file-bookmark",
        params={"file_id": str(file_id)},
        headers=authorization(str(owner)),
    )

    with _SESSIONS() as session:
        stored = session.get(File, file_id)

        assert stored is not None

        folder_id = str(stored.folder_id)

    assert response.status_code == _OK
    assert response.json() == {
        "page": page,
        "page_count": page_count,
        "folder_id": folder_id,
        "folder_name": "Home",
    }


@settings(max_examples=25, deadline=None)
@given(st.uuids(), _PAGES)
def test_set_file_bookmark_property_round_trips_the_chosen_page(
    owner: uuid.UUID, page: int
) -> None:
    file_id = _bookmarked(owner, None)
    written = _CLIENT.put(
        "/file-bookmark",
        json={"file_id": str(file_id), "page": page},
        headers=authorization(str(owner)),
    )
    _counting_pages(page)
    read_back = _CLIENT.get(
        "/file-bookmark",
        params={"file_id": str(file_id)},
        headers=authorization(str(owner)),
    )
    read_body = cast("dict[str, object]", read_back.json())

    assert written.json() == {"page": page}
    assert read_body["page"] == page


@settings(max_examples=25, deadline=None)
@given(st.uuids(), _PAGES)
def test_remove_file_bookmark_property_always_clears_the_page(
    owner: uuid.UUID, page: int
) -> None:
    file_id = _bookmarked(owner, page)
    removed = _CLIENT.delete(
        "/file-bookmark",
        params={"file_id": str(file_id)},
        headers=authorization(str(owner)),
    )

    assert removed.json() == {"page": None}


@settings(max_examples=25, deadline=None)
@given(st.uuids(), st.uuids(), _PAGES)
def test_get_file_bookmark_property_hides_another_owners_file(
    owner: uuid.UUID, stranger: uuid.UUID, page: int
) -> None:
    file_id = _bookmarked(owner, page)
    response = _CLIENT.get(
        "/file-bookmark",
        params={"file_id": str(file_id)},
        headers=authorization(str(stranger)),
    )

    assert response.status_code == _NOT_FOUND
