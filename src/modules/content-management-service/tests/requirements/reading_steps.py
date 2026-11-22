from fastapi.testclient import TestClient
from httpx import Response
from pytest_bdd import given, parsers, then, when

from tests.requirements.file_steps import stored_file_id
from tests.requirements.requirement_lookup import (
    Sessions,
    reply_body,
    told_message,
)
from tests.support import authorization

_FILE_BOOKMARK = "/file-bookmark"
_EXTRACT_TEXT = "/extract-text"
_RECOGNITION_UNAVAILABLE = "Text recognition is not available"


def _extracted(
    client: TestClient, extraction_request: dict[str, object]
) -> Response:
    return client.post(
        _EXTRACT_TEXT, json=extraction_request, headers=authorization()
    )


def _bookmark(
    client: TestClient, sessions: Sessions, file_name: str
) -> Response:
    return client.get(
        _FILE_BOOKMARK,
        params={"file_id": stored_file_id(sessions, file_name)},
        headers=authorization(),
    )


@when(parsers.parse('I stop reading "{file_name}" on page {page:d}'))
@given(parsers.parse('I stopped reading "{file_name}" on page {page:d}'))
def bookmark_page(
    client: TestClient, sessions: Sessions, file_name: str, page: int
) -> None:
    bookmark_request = {
        "file_id": stored_file_id(sessions, file_name),
        "page": page,
    }
    reply = client.put(
        _FILE_BOOKMARK, json=bookmark_request, headers=authorization()
    )
    _ = reply.raise_for_status()


@when(parsers.parse('I remove the bookmark of "{file_name}"'))
def remove_bookmark(
    client: TestClient, sessions: Sessions, file_name: str
) -> None:
    reply = client.delete(
        _FILE_BOOKMARK,
        params={"file_id": stored_file_id(sessions, file_name)},
        headers=authorization(),
    )
    _ = reply.raise_for_status()


@then(parsers.parse('"{file_name}" opens on page {page:d}'))
def check_bookmarked_page(
    client: TestClient, sessions: Sessions, file_name: str, page: int
) -> None:
    bookmark = reply_body(_bookmark(client, sessions, file_name))

    assert bookmark["page"] == page


@then(parsers.parse('"{file_name}" has no bookmark'))
def check_no_bookmark(
    client: TestClient, sessions: Sessions, file_name: str
) -> None:
    bookmark = reply_body(_bookmark(client, sessions, file_name))

    assert bookmark["page"] is None


@when(
    parsers.parse('I read the text out of "{file_name}"'),
    target_fixture="reply",
)
def read_file_text(
    client: TestClient, sessions: Sessions, file_name: str
) -> Response:
    file_metadata = {"file_id": stored_file_id(sessions, file_name)}

    return _extracted(client, {"file_metadata": [file_metadata]})


@when(
    parsers.parse('I read the text out of page {page:d} of "{file_name}"'),
    target_fixture="reply",
)
def read_page_text(
    client: TestClient, sessions: Sessions, page: int, file_name: str
) -> Response:
    file_metadata = {
        "file_id": stored_file_id(sessions, file_name),
        "pages": {"first": page, "last": page},
    }

    return _extracted(client, {"file_metadata": [file_metadata]})


@when(
    parsers.parse('I read the text out of the link "{link}"'),
    target_fixture="reply",
)
def read_link_text(client: TestClient, link: str) -> Response:
    return _extracted(client, {"link_metadata": link})


@then(parsers.parse('I get the text "{expected_text}"'))
def check_text_received(reply: Response, expected_text: str) -> None:
    assert expected_text in str(reply_body(reply)["text"])


@then(parsers.parse('the text leaves out "{left_out_text}"'))
def check_text_left_out(reply: Response, left_out_text: str) -> None:
    assert left_out_text not in str(reply_body(reply)["text"])


@then("I am told text recognition is not available")
def check_recognition_reported(reply: Response) -> None:
    assert _RECOGNITION_UNAVAILABLE in str(told_message(reply))
