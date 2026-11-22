import os
from unittest import mock

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

from shared.ai_manager import OpenAIManager
from shared.chosen_ai_engine import (
    ANSWERER_BUILDERS,
    CLAUDE_CODE_ENGINE,
    OPENAI_ENGINE,
    ChosenAiFactory,
    build_claude_code_answerer,
)
from shared.claude_code_answerer import ClaudeCodeAnswerer

_MODELS = st.one_of(st.none(), st.sampled_from(["sonnet", "gpt-5-mini"]))
_UNKNOWN_ENGINES = st.text(max_size=12).filter(
    lambda engine: engine not in ANSWERER_BUILDERS
)
_TEST_KEY = {"OPENAI_API_KEY": "test-key"}


@settings(max_examples=10)
@given(_MODELS)
def test_get_ai_property_uses_claude_code_when_it_is_chosen(
    model_name: str | None,
) -> None:
    answerer = ChosenAiFactory(CLAUDE_CODE_ENGINE).get_ai(model_name)

    assert isinstance(answerer, ClaudeCodeAnswerer)


@settings(max_examples=10)
@given(_MODELS)
def test_get_ai_property_uses_openai_when_it_is_chosen(
    model_name: str | None,
) -> None:
    with mock.patch.dict(os.environ, _TEST_KEY):
        answerer = ChosenAiFactory(OPENAI_ENGINE).get_ai(model_name)

    assert isinstance(answerer, OpenAIManager)


@settings(max_examples=25)
@given(_UNKNOWN_ENGINES)
def test___init___property_refuses_an_unknown_engine(engine: str) -> None:
    with pytest.raises(ValueError, match="Unknown AI engine"):
        _ = ChosenAiFactory(engine)


@settings(max_examples=10)
@given(_MODELS)
def test_build_claude_code_answerer_property_builds_a_claude_code_answerer(
    model_name: str | None,
) -> None:
    answerer = build_claude_code_answerer(model_name)

    assert isinstance(answerer, ClaudeCodeAnswerer)
