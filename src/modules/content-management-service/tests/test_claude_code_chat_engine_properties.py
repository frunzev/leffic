import uuid

import pytest
from claude_agent_sdk import AssistantMessage, TextBlock
from hypothesis import given, settings
from hypothesis import strategies as st

from features.chatbot.chat_engine import ChatEngineUnavailableError
from features.chatbot.claude_code_chat_engine import (
    ClaudeCodeChatEngine,
    rendered_prompt,
)
from features.chatbot.study_toolset import (
    STUDY_SERVER_NAME,
    STUDY_TOOL_NAMES,
)
from shared.claude_code_run import QueryRunner
from tests.claude_code_fakes import (
    MissingClaudeCode,
    ScriptedQuery,
    result_message,
)
from tests.support import in_memory_sessions

_TEXT = st.text(min_size=1, max_size=40)
_ROLES = st.sampled_from(["user", "assistant"])
_TURNS = st.lists(
    st.fixed_dictionaries({"role": _ROLES, "content": _TEXT}),
    min_size=1,
    max_size=6,
)
_USER_ID = "8f5d2a9e-3c1b-4f6a-9d7e-2b4c6a8e0f13"
_ONE_TURN = [{"role": "user", "content": "hello"}]


def _engine(run_query: QueryRunner) -> ClaudeCodeChatEngine:
    return ClaudeCodeChatEngine(in_memory_sessions(), run_query)


@settings(max_examples=25, deadline=None)
@given(_TEXT, _TEXT)
def test_answer_property_returns_the_final_result_text(
    partial: str, final: str
) -> None:
    scripted = ScriptedQuery(
        [
            AssistantMessage(content=[TextBlock(text=partial)], model="m"),
            result_message(final, is_error=False),
        ]
    )

    assert _engine(scripted).answer(_ONE_TURN, _USER_ID) == final


@settings(max_examples=25, deadline=None)
@given(st.one_of(st.none(), _TEXT))
def test_answer_property_refuses_a_run_that_ended_in_error(
    answer: str | None,
) -> None:
    scripted = ScriptedQuery([result_message(answer, is_error=True)])

    with pytest.raises(ChatEngineUnavailableError):
        _ = _engine(scripted).answer(_ONE_TURN, _USER_ID)


@settings(max_examples=25, deadline=None)
@given(_TEXT)
def test_answer_property_refuses_a_run_without_aresult_message(
    partial: str,
) -> None:
    scripted = ScriptedQuery(
        [AssistantMessage(content=[TextBlock(text=partial)], model="m")]
    )

    with pytest.raises(ChatEngineUnavailableError):
        _ = _engine(scripted).answer(_ONE_TURN, _USER_ID)


@settings(max_examples=10, deadline=None)
@given(_TURNS)
def test_answer_property_reports_a_missing_claude_code(
    conversation: list[dict[str, str]],
) -> None:
    with pytest.raises(ChatEngineUnavailableError):
        _ = _engine(MissingClaudeCode()).answer(conversation, _USER_ID)


@settings(max_examples=10, deadline=None)
@given(_TURNS)
def test_answer_property_offers_only_the_study_tools(
    conversation: list[dict[str, str]],
) -> None:
    scripted = ScriptedQuery([result_message("done", is_error=False)])

    _ = _engine(scripted).answer(conversation, _USER_ID)
    options = scripted.options[0]

    assert options.tools == []
    assert options.setting_sources == []
    assert options.allowed_tools == list(STUDY_TOOL_NAMES)
    assert scripted.prompts == [rendered_prompt(conversation)]


@settings(max_examples=50)
@given(_TURNS)
def test_rendered_prompt_property_keeps_every_turn_in_order(
    conversation: list[dict[str, str]],
) -> None:
    prompt = rendered_prompt(conversation)
    position = 0

    for turn in conversation:
        found_at = prompt.find(turn["content"], position)

        assert found_at >= position

        position = found_at + len(turn["content"])


@settings(max_examples=25, deadline=None)
@given(st.uuids())
def test__options_property_never_offers_a_built_in_tool(
    user_id: uuid.UUID,
) -> None:
    options = _engine(ScriptedQuery([]))._options(str(user_id))

    assert options.tools == []
    assert options.setting_sources == []
    assert options.allowed_tools == list(STUDY_TOOL_NAMES)
    assert isinstance(options.mcp_servers, dict)
    assert list(options.mcp_servers) == [STUDY_SERVER_NAME]
