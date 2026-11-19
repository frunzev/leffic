from sqlalchemy.orm import Session, sessionmaker

from shared.content_access import owned_content
from shared.models import Flashcard, FlashcardDeck, Folder, Note

_MISSING_NOTE = "Note does not exist!"
_MISSING_DECK = "Flashcard deck does not exist!"
_BASIC_CARD = "basic"


class StudyLibrary:
    def __init__(
        self, sessions: sessionmaker[Session], user_id: str
    ) -> None:
        self._sessions: sessionmaker[Session] = sessions
        self._user_id: str = user_id

    def folder_outline(self) -> str:
        outline_lines: list[str] = []

        with self._sessions() as session:
            folders = (
                session.query(Folder).filter_by(user_id=self._user_id).all()
            )

            for folder in folders:
                outline_lines.append(f"folder {folder.id}: {folder.name}")

                for deck in folder.flashcard_decks:
                    outline_lines.append(f"  deck {deck.id}: {deck.name}")

                for note in folder.notes:
                    outline_lines.append(f"  note {note.id}: {note.name}")

        return "\n".join(outline_lines)

    def note_content(self, note_id: str) -> str:
        with self._sessions() as session:
            note = owned_content(
                session, self._user_id, Note, note_id, _MISSING_NOTE
            )

            return note.content

    def append_flashcard(self, deck_id: str, front: str, back: str) -> None:
        with self._sessions() as session:
            deck = owned_content(
                session, self._user_id, FlashcardDeck, deck_id, _MISSING_DECK
            )
            deck.flashcards.append(
                Flashcard(
                    type=_BASIC_CARD, content={"front": front, "back": back}
                )
            )
            session.commit()
