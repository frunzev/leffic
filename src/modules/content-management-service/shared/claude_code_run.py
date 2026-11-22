import asyncio
from collections.abc import AsyncIterator, Callable
from dataclasses import dataclass

from claude_agent_sdk import (
    ClaudeAgentOptions,
    ClaudeSDKError,
    Message,
    ResultMessage,
)

QueryRunner = Callable[..., AsyncIterator[Message]]

CLAUDE_CODE_UNAVAILABLE = (
    "Claude Code did not answer. Check that it is installed and logged in."
)


class ClaudeCodeUnavailableError(Exception):
    def __init__(self) -> None:
        super().__init__(CLAUDE_CODE_UNAVAILABLE)


@dataclass(frozen=True)
class ClaudeCodeReply:
    text: str
    cost_in_dollars: float | None


async def final_claude_code_reply(
    run_query: QueryRunner, prompt: str, options: ClaudeAgentOptions
) -> ClaudeCodeReply:
    final_message: ResultMessage | None = None

    async for message in run_query(prompt=prompt, options=options):
        if isinstance(message, ResultMessage):
            final_message = message

    if final_message is None or final_message.is_error:
        raise ClaudeCodeUnavailableError

    final_text = final_message.result

    if final_text is None:
        raise ClaudeCodeUnavailableError

    return ClaudeCodeReply(
        text=final_text, cost_in_dollars=final_message.total_cost_usd
    )


def run_claude_code(
    run_query: QueryRunner, prompt: str, options: ClaudeAgentOptions
) -> ClaudeCodeReply:
    reply_coroutine = final_claude_code_reply(run_query, prompt, options)

    try:
        return asyncio.run(reply_coroutine)
    except ClaudeSDKError as unavailable:
        raise ClaudeCodeUnavailableError from unavailable
