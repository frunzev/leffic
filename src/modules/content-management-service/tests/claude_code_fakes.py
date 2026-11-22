from collections.abc import AsyncIterator

from claude_agent_sdk import (
    ClaudeAgentOptions,
    CLINotFoundError,
    Message,
    ResultMessage,
)


def result_message(
    answer: str | None,
    *,
    is_error: bool,
    cost_in_dollars: float | None = None,
) -> ResultMessage:
    return ResultMessage(
        subtype="success",
        duration_ms=1,
        duration_api_ms=1,
        is_error=is_error,
        num_turns=1,
        session_id="session",
        total_cost_usd=cost_in_dollars,
        result=answer,
    )


class ScriptedQuery:
    def __init__(self, messages: list[Message]) -> None:
        self.messages: list[Message] = messages
        self.prompts: list[str] = []
        self.options: list[ClaudeAgentOptions] = []

    async def __call__(
        self, *, prompt: str, options: ClaudeAgentOptions
    ) -> AsyncIterator[Message]:
        self.prompts.append(prompt)
        self.options.append(options)

        for message in self.messages:
            yield message


class MissingClaudeCode:
    def __call__(
        self, *, prompt: str, options: ClaudeAgentOptions
    ) -> AsyncIterator[Message]:
        _ = (prompt, options)

        raise CLINotFoundError
