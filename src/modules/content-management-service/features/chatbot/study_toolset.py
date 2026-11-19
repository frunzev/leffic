from typing import Protocol

from claude_agent_sdk import McpSdkServerConfig, create_sdk_mcp_server, tool
from fastapi import HTTPException

STUDY_SERVER_NAME = "leffic"
STUDY_TOOL_NAMES = (
    "mcp__leffic__list_folders",
    "mcp__leffic__read_note",
    "mcp__leffic__add_flashcard",
)

_LIST_FOLDERS = "list_folders"
_READ_NOTE = "read_note"
_ADD_FLASHCARD = "add_flashcard"
_LIST_FOLDERS_PURPOSE = (
    "List the user's folders with the ids and names of their flashcard "
    "decks and notes."
)
_READ_NOTE_PURPOSE = "Read the full text of one of the user's notes by id."
_ADD_FLASHCARD_PURPOSE = (
    "Add one basic flashcard with a front and a back to one of the user's "
    "flashcard decks by id."
)
_CARD_ADDED = "The flashcard was added."

ToolResult = dict[str, object]


class StudyMaterial(Protocol):
    def folder_outline(self) -> str: ...

    def note_content(self, note_id: str) -> str: ...

    def append_flashcard(
        self, deck_id: str, front: str, back: str
    ) -> None: ...


def _text_result(text: str) -> ToolResult:
    return {"content": [{"type": "text", "text": text}]}


def _refused_result(refusal: HTTPException) -> ToolResult:
    return {
        "content": [{"type": "text", "text": str(refusal.detail)}],
        "is_error": True,
    }


class StudyToolset:
    def __init__(self, library: StudyMaterial) -> None:
        self._library: StudyMaterial = library

    async def list_folders(self, arguments: ToolResult) -> ToolResult:
        _ = arguments

        return _text_result(self._library.folder_outline())

    async def read_note(self, arguments: ToolResult) -> ToolResult:
        note_id = str(arguments["note_id"])

        try:
            note = self._library.note_content(note_id)
        except HTTPException as refusal:
            return _refused_result(refusal)

        return _text_result(note)

    async def add_flashcard(self, arguments: ToolResult) -> ToolResult:
        deck_id = str(arguments["deck_id"])
        front = str(arguments["front"])
        back = str(arguments["back"])

        try:
            self._library.append_flashcard(deck_id, front, back)
        except HTTPException as refusal:
            return _refused_result(refusal)

        return _text_result(_CARD_ADDED)

    def server(self) -> McpSdkServerConfig:
        list_folders = tool(_LIST_FOLDERS, _LIST_FOLDERS_PURPOSE, {})
        read_note = tool(_READ_NOTE, _READ_NOTE_PURPOSE, {"note_id": str})
        add_flashcard = tool(
            _ADD_FLASHCARD,
            _ADD_FLASHCARD_PURPOSE,
            {"deck_id": str, "front": str, "back": str},
        )

        return create_sdk_mcp_server(
            name=STUDY_SERVER_NAME,
            tools=[
                list_folders(self.list_folders),
                read_note(self.read_note),
                add_flashcard(self.add_flashcard),
            ],
        )
