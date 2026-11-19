import asyncio
from collections.abc import AsyncIterator, Callable
from typing import override

from claude_agent_sdk import (
    ClaudeAgentOptions,
    ClaudeSDKError,
    Message,
    ResultMessage,
)
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

QueryRunner = Callable[..., AsyncIterator[Message]]

_SYSTEM_PROMPT = (
    "You are the study assistant inside Leffic. Answer shortly and "
    "clearly. Use the leffic tools to look at the user's folders, notes "
    "and flashcard decks, and to add flashcards when the user asks."
)
_MAXIMUM_TURNS = 8
_CLAUDE_CODE_UNAVAILABLE = (
    "Claude Code did not answer. Check that it is installed and logged in."
)
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
            return asyncio.run(self._final_answer(prompt, options))
        except ClaudeSDKError as unavailable:
            raise ChatEngineUnavailableError(
                _CLAUDE_CODE_UNAVAILABLE
            ) from unavailable

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

    async def _final_answer(
        self, prompt: str, options: ClaudeAgentOptions
    ) -> str:
        final_message: ResultMessage | None = None

        async for message in self._run_query(prompt=prompt, options=options):
            if isinstance(message, ResultMessage):
                final_message = message

        if final_message is None or final_message.is_error:
            raise ChatEngineUnavailableError(_CLAUDE_CODE_UNAVAILABLE)

        final_answer = final_message.result

        if final_answer is None:
            raise ChatEngineUnavailableError(_CLAUDE_CODE_UNAVAILABLE)

        return final_answer
