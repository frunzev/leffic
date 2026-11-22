from collections.abc import AsyncIterator
from typing import TYPE_CHECKING, cast

import pytest
from claude_agent_sdk import ClaudeAgentOptions, Message
from mcp import Client
from mcp.types import TextContent
from pytest_bdd import given, parsers

from features.chatbot.study_toolset import STUDY_SERVER_NAME
from shared.models import FlashcardDeck, Note
from tests.claude_code_fakes import result_message
from tests.requirements.ask_steps import use_claude_code
from tests.requirements.requirement_lookup import Sessions, unit_id_named

if TYPE_CHECKING:
    from claude_agent_sdk.types import McpSdkServerConfig

_LIST_FOLDERS = "list_folders"
_READ_NOTE = "read_note"
_ADD_FLASHCARD = "add_flashcard"
_ADDED_CARD_BACK = "A card Ask added."
_ADD_CARD_STEP = (
    'Claude Code adds the card "{card_front}" to the deck "{deck_name}"'
)

ToolArguments = dict[str, object]


class ToolCallingClaudeCode:
    def __init__(self, tool_name: str, tool_arguments: ToolArguments) -> None:
        self._tool_name: str = tool_name
        self._tool_arguments: ToolArguments = tool_arguments

    async def __call__(
        self, *, prompt: str, options: ClaudeAgentOptions
    ) -> AsyncIterator[Message]:
        _ = prompt
        tool_text = await self._called_tool(options)

        yield result_message(tool_text, is_error=False)

    async def _called_tool(self, options: ClaudeAgentOptions) -> str:
        servers = cast("dict[str, McpSdkServerConfig]", options.mcp_servers)
        study_server = servers[STUDY_SERVER_NAME]["instance"]

        async with Client(study_server) as tool_client:
            tool_result = await tool_client.call_tool(
                self._tool_name, self._tool_arguments
            )

        tool_texts: list[str] = []

        for content in tool_result.content:
            if isinstance(content, TextContent):
                tool_texts.append(content.text)

        return "\n".join(tool_texts)


@given("Claude Code looks at my folders")
def call_folder_tool(
    monkeypatch: pytest.MonkeyPatch, sessions: Sessions
) -> None:
    claude_code = ToolCallingClaudeCode(_LIST_FOLDERS, {})
    use_claude_code(monkeypatch, sessions, claude_code)


@given(parsers.parse('Claude Code reads the note "{note_name}"'))
def call_note_tool(
    monkeypatch: pytest.MonkeyPatch, sessions: Sessions, note_name: str
) -> None:
    note_id = unit_id_named(sessions, Note, note_name)
    claude_code = ToolCallingClaudeCode(_READ_NOTE, {"note_id": note_id})
    use_claude_code(monkeypatch, sessions, claude_code)


@given(parsers.parse(_ADD_CARD_STEP))
def call_card_tool(
    monkeypatch: pytest.MonkeyPatch,
    sessions: Sessions,
    card_front: str,
    deck_name: str,
) -> None:
    card_arguments: ToolArguments = {
        "deck_id": unit_id_named(sessions, FlashcardDeck, deck_name),
        "front": card_front,
        "back": _ADDED_CARD_BACK,
    }
    claude_code = ToolCallingClaudeCode(_ADD_FLASHCARD, card_arguments)
    use_claude_code(monkeypatch, sessions, claude_code)
