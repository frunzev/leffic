import os
from collections.abc import Callable

from claude_agent_sdk import query

from shared.ai_manager import ai_factory
from shared.claude_code_answerer import ClaudeCodeAnswerer
from shared.json_answerer import JsonAnswerer

OPENAI_ENGINE = "openai"
CLAUDE_CODE_ENGINE = "claude-code"
CHOSEN_AI_ENGINE = os.getenv("CHAT_ENGINE", OPENAI_ENGINE)

_UNKNOWN_ENGINE = "Unknown AI engine {engine!r}"

AnswererBuilder = Callable[[str | None], JsonAnswerer]


def build_claude_code_answerer(model_name: str | None) -> JsonAnswerer:
    return ClaudeCodeAnswerer(query, model_name)


ANSWERER_BUILDERS: dict[str, AnswererBuilder] = {
    OPENAI_ENGINE: ai_factory.get_ai,
    CLAUDE_CODE_ENGINE: build_claude_code_answerer,
}


class ChosenAiFactory:
    def __init__(self, engine: str) -> None:
        builder = ANSWERER_BUILDERS.get(engine)

        if builder is None:
            raise ValueError(_UNKNOWN_ENGINE.format(engine=engine))

        self._build_answerer: AnswererBuilder = builder

    def get_ai(self, model: str | None = None) -> JsonAnswerer:
        return self._build_answerer(model)


chosen_ai_factory = ChosenAiFactory(CHOSEN_AI_ENGINE)
