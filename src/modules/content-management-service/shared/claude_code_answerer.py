from typing import override

from claude_agent_sdk import ClaudeAgentOptions

from shared.claude_code_run import QueryRunner, run_claude_code
from shared.json_answerer import JsonAnswerer
from shared.json_extraction import get_dict_from_text

_SINGLE_TURN = 1


class ClaudeCodeAnswerer(JsonAnswerer):
    def __init__(self, run_query: QueryRunner, model_name: str | None) -> None:
        self._run_query: QueryRunner = run_query
        self._model_name: str | None = model_name

    @override
    def get_ai_res(
        self, system_prompt: str, user_prompt: str
    ) -> tuple[dict[str, object], float | None]:
        options = ClaudeAgentOptions(
            system_prompt=system_prompt,
            model=self._model_name,
            tools=[],
            setting_sources=[],
            max_turns=_SINGLE_TURN,
        )

        reply = run_claude_code(self._run_query, user_prompt, options)

        return get_dict_from_text(reply.text), reply.cost_in_dollars
