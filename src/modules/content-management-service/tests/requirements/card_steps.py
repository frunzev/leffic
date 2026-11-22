from fastapi.testclient import TestClient
from pytest_bdd import parsers, then, when

from tests.requirements.card_lookup import (
    due_card_id,
    due_card_with_front,
    stored_card,
)
from tests.requirements.requirement_lookup import Sessions
from tests.support import authorization

_UPDATE_FLASHCARD = "/update-flashcard"
_DELETE_FLASHCARD = "/delete-flashcard/"
_EDITED_BACK = "An edited answer."


def _updated_card(
    client: TestClient, card_id: int, card_content: dict[str, object]
) -> None:
    update_request = {"flashcard_id": card_id, "content": card_content}
    reply = client.patch(
        _UPDATE_FLASHCARD, json=update_request, headers=authorization()
    )
    _ = reply.raise_for_status()


@when(parsers.parse('I change the card "{card_front}" to "{new_front}"'))
def change_card_front(
    client: TestClient, card_front: str, new_front: str
) -> None:
    card_content: dict[str, object] = {
        "front": new_front,
        "back": _EDITED_BACK,
    }
    _updated_card(client, due_card_id(client, card_front), card_content)


@when(parsers.parse('I change the answer of "{card_front}" to "{new_back}"'))
def change_card_back(
    client: TestClient, card_front: str, new_back: str
) -> None:
    card_content: dict[str, object] = {
        "front": card_front,
        "back": new_back,
    }
    _updated_card(client, due_card_id(client, card_front), card_content)


@then(parsers.parse('the card "{card_front}" answers "{expected_back}"'))
def check_card_answer(
    client: TestClient, card_front: str, expected_back: str
) -> None:
    card = due_card_with_front(client, card_front)

    assert card["content"] == {"front": card_front, "back": expected_back}


@when(parsers.parse('I delete the card "{card_front}"'))
def delete_card(
    client: TestClient, sessions: Sessions, card_front: str
) -> None:
    card_id = stored_card(sessions, card_front).id
    reply = client.delete(
        _DELETE_FLASHCARD,
        params={"flashcard_id": card_id},
        headers=authorization(),
    )
    _ = reply.raise_for_status()
