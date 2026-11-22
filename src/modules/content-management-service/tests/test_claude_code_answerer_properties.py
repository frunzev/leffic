import json

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

from shared.claude_code_answerer import ClaudeCodeAnswerer
from shared.claude_code_run import ClaudeCodeUnavailableError
from tests.claude_code_fakes import (
    MissingClaudeCode,
    ScriptedQuery,
    result_message,
)

_TEXT = st.text(min_size=1, max_size=30)
_PAYLOADS = st.dictionaries(
    st.text(alphabet="abcdefgh_", min_size=1, max_size=8),
    st.text(alphabet="abcdefgh ", max_size=12),
    max_size=4,
)
_MODELS = st.one_of(st.none(), st.sampled_from(["sonnet", "opus"]))
_COSTS = st.one_of(
    st.none(), st.floats(min_value=0, max_value=10, allow_nan=False)
)


@settings(max_examples=25, deadline=None)
@given(_PAYLOADS, _COSTS)
def test_get_ai_res_property_returns_the_answered_object_and_cost(
    payload: dict[str, str], cost_in_dollars: float | None
) -> None:
    answer = f"Here it is: {json.dumps(payload)}"
    scripted = ScriptedQuery(
        [
            result_message(
                answer, is_error=False, cost_in_dollars=cost_in_dollars
            )
        ]
    )

    answered, cost = ClaudeCodeAnswerer(scripted, None).get_ai_res(
        system_prompt="system", user_prompt="user"
    )

    assert answered == payload
    assert cost == cost_in_dollars


@settings(max_examples=25, deadline=None)
@given(_TEXT, _TEXT, _MODELS)
def test_get_ai_res_property_asks_one_tool_free_turn_with_the_prompts(
    system_prompt: str, user_prompt: str, model_name: str | None
) -> None:
    scripted = ScriptedQuery([result_message("{}", is_error=False)])

    _ = ClaudeCodeAnswerer(scripted, model_name).get_ai_res(
        system_prompt=system_prompt, user_prompt=user_prompt
    )
    options = scripted.options[0]

    assert scripted.prompts == [user_prompt]
    assert options.system_prompt == system_prompt
    assert options.model == model_name
    assert options.tools == []
    assert options.allowed_tools == []
    assert options.setting_sources == []
    assert options.max_turns == 1


@settings(max_examples=10, deadline=None)
@given(_TEXT)
def test_get_ai_res_property_reports_a_missing_claude_code(
    user_prompt: str,
) -> None:
    answerer = ClaudeCodeAnswerer(MissingClaudeCode(), None)

    with pytest.raises(ClaudeCodeUnavailableError):
        _ = answerer.get_ai_res(system_prompt="s", user_prompt=user_prompt)
