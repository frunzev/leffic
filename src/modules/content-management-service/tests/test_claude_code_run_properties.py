import asyncio

import pytest
from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    Message,
    TextBlock,
)
from hypothesis import given, settings
from hypothesis import strategies as st

from shared.claude_code_run import (
    ClaudeCodeUnavailableError,
    final_claude_code_reply,
    run_claude_code,
)
from tests.claude_code_fakes import (
    MissingClaudeCode,
    ScriptedQuery,
    result_message,
)

_TEXT = st.text(min_size=1, max_size=40)
_COSTS = st.one_of(
    st.none(), st.floats(min_value=0, max_value=10, allow_nan=False)
)


@settings(max_examples=25, deadline=None)
@given(st.lists(_TEXT, min_size=1, max_size=4), _COSTS)
def test_final_claude_code_reply_property_keeps_only_the_last_result(
    answers: list[str], cost_in_dollars: float | None
) -> None:
    messages: list[Message] = [
        result_message(answer, is_error=False) for answer in answers[:-1]
    ]
    messages.append(
        result_message(
            answers[-1], is_error=False, cost_in_dollars=cost_in_dollars
        )
    )

    reply = asyncio.run(
        final_claude_code_reply(
            ScriptedQuery(messages), "prompt", ClaudeAgentOptions()
        )
    )

    assert reply.text == answers[-1]
    assert reply.cost_in_dollars == cost_in_dollars


@settings(max_examples=25, deadline=None)
@given(st.one_of(st.none(), _TEXT))
def test_final_claude_code_reply_property_refuses_an_error_run(
    answer: str | None,
) -> None:
    scripted = ScriptedQuery([result_message(answer, is_error=True)])

    with pytest.raises(ClaudeCodeUnavailableError):
        _ = asyncio.run(
            final_claude_code_reply(scripted, "prompt", ClaudeAgentOptions())
        )


@settings(max_examples=25, deadline=None)
@given(st.lists(_TEXT, max_size=3))
def test_final_claude_code_reply_property_refuses_a_run_without_text(
    partial_texts: list[str],
) -> None:
    messages: list[Message] = [
        AssistantMessage(content=[TextBlock(text=text)], model="m")
        for text in partial_texts
    ]
    messages.append(result_message(None, is_error=False))

    with pytest.raises(ClaudeCodeUnavailableError):
        _ = asyncio.run(
            final_claude_code_reply(
                ScriptedQuery(messages), "prompt", ClaudeAgentOptions()
            )
        )


@settings(max_examples=25, deadline=None)
@given(_TEXT)
def test_final_claude_code_reply_property_refuses_a_run_without_result(
    partial_text: str,
) -> None:
    scripted = ScriptedQuery(
        [AssistantMessage(content=[TextBlock(text=partial_text)], model="m")]
    )

    with pytest.raises(ClaudeCodeUnavailableError):
        _ = asyncio.run(
            final_claude_code_reply(scripted, "prompt", ClaudeAgentOptions())
        )


@settings(max_examples=25, deadline=None)
@given(_TEXT, _TEXT)
def test_run_claude_code_property_sends_the_prompt_and_returns_the_text(
    prompt: str, answer: str
) -> None:
    scripted = ScriptedQuery([result_message(answer, is_error=False)])

    reply = run_claude_code(scripted, prompt, ClaudeAgentOptions())

    assert reply.text == answer
    assert scripted.prompts == [prompt]


@settings(max_examples=10, deadline=None)
@given(_TEXT)
def test_run_claude_code_property_reports_a_missing_claude_code(
    prompt: str,
) -> None:
    with pytest.raises(ClaudeCodeUnavailableError):
        _ = run_claude_code(MissingClaudeCode(), prompt, ClaudeAgentOptions())
