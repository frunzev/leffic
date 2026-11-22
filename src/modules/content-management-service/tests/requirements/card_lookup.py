from typing import cast

from fastapi.testclient import TestClient
from httpx import Response
from sqlalchemy import select

from shared.models import Flashcard, FlashcardDeck
from tests.requirements.requirement_listing import HOME
from tests.requirements.requirement_lookup import (
    Sessions,
    reply_body,
    unit_id_named,
)
from tests.support import authorization

_FLASHCARDS = "/flashcards"

DueCard = dict[str, object]


def due_cards(client: TestClient, scope: dict[str, str]) -> Response:
    return client.get(_FLASHCARDS, params=scope, headers=authorization())


def due_cards_in_deck(
    client: TestClient, sessions: Sessions, deck_name: str
) -> Response:
    deck_id = unit_id_named(sessions, FlashcardDeck, deck_name)

    return due_cards(client, {"flashcard_deck_id": deck_id})


def _content_of(card: DueCard) -> dict[str, object]:
    return cast("dict[str, object]", card["content"])


def card_fronts(reply: Response) -> list[str]:
    cards = cast("list[DueCard]", reply_body(reply)["flashcards"])
    fronts: list[str] = []

    for card in cards:
        fronts.append(str(_content_of(card)["front"]))

    return fronts


def due_card_with_front(client: TestClient, card_front: str) -> DueCard:
    reply = due_cards(client, {"folder_id": HOME})
    cards = cast("list[DueCard]", reply_body(reply)["flashcards"])

    for card in cards:
        if _content_of(card)["front"] == card_front:
            return card

    message = f"No due card asks {card_front!r}"
    raise LookupError(message)


def due_card_id(client: TestClient, card_front: str) -> int:
    return cast("int", due_card_with_front(client, card_front)["id"])


def stored_card(sessions: Sessions, card_front: str) -> Flashcard:
    with sessions() as session:
        for card in session.execute(select(Flashcard)).scalars():
            if card.content.get("front") == card_front:
                session.expunge(card)

                return card

    message = f"No stored card asks {card_front!r}"
    raise LookupError(message)
