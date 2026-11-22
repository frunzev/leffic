from typing import override

from claude_agent_sdk import ClaudeAgentOptions
from sqlalchemy.orm import Session, sessionmaker

from features.chatbot.chat_engine import (
    ChatEngine,
    ChatEngineUnavailableError,
    Conversation,
)
from features.chatbot.study_library import StudyLibrary
from features.chatbot.study_toolset import (
    STUDY_SERVER_NAME,
    STUDY_TOOL_NAMES,
    StudyToolset,
)
from shared.claude_code_run import (
    ClaudeCodeUnavailableError,
    QueryRunner,
    run_claude_code,
)

_SYSTEM_PROMPT = (
    "You are the study assistant inside Leffic. Answer shortly and "
    "clearly. Use the leffic tools to look at the user's folders, notes "
    "and flashcard decks, and to add flashcards when the user asks."
)
_MAXIMUM_TURNS = 8
_TURN_SEPARATOR = "\n\n"


def rendered_prompt(conversation: Conversation) -> str:
    rendered_turns: list[str] = []

    for turn in conversation:
        rendered_turns.append(f"{turn['role']}: {turn['content']}")

    return _TURN_SEPARATOR.join(rendered_turns)


class ClaudeCodeChatEngine(ChatEngine):
    def __init__(
        self, sessions: sessionmaker[Session], run_query: QueryRunner
    ) -> None:
        self._sessions: sessionmaker[Session] = sessions
        self._run_query: QueryRunner = run_query

    @override
    def answer(self, conversation: Conversation, user_id: str) -> str:
        options = self._options(user_id)
        prompt = rendered_prompt(conversation)

        try:
            reply = run_claude_code(self._run_query, prompt, options)
        except ClaudeCodeUnavailableError as unavailable:
            raise ChatEngineUnavailableError(str(unavailable)) from unavailable

        return reply.text

    def _options(self, user_id: str) -> ClaudeAgentOptions:
        toolset = StudyToolset(StudyLibrary(self._sessions, user_id))

        return ClaudeAgentOptions(
            system_prompt=_SYSTEM_PROMPT,
            tools=[],
            allowed_tools=list(STUDY_TOOL_NAMES),
            mcp_servers={STUDY_SERVER_NAME: toolset.server()},
            setting_sources=[],
            max_turns=_MAXIMUM_TURNS,
        )
