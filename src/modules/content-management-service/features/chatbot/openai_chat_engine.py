from typing import Protocol, cast, override

from openai import OpenAIError

from features.chatbot.chat_engine import (
    ChatEngine,
    ChatEngineUnavailableError,
    Conversation,
)
from shared.ai_budget import AiBudget
from shared.ai_manager import AiMessage, PricedAnswer
from shared.chosen_ai_engine import OPENAI_ENGINE

_SYSTEM_PROMPT = (
    "You are a very helpful assistant! You always answer shortly and clearly"
)
_MODEL_UNAVAILABLE = "The assistant is unavailable right now. Try again."
_KEY_MISSING = (
    "OpenAI is not set up. Add an OpenAI API key in Settings, "
    "or choose Claude Code there."
)


class ConversationModel(Protocol):
    def get_ai_res_hist(
        self, system_prompt: str, history: list[AiMessage]
    ) -> PricedAnswer: ...


class ConversationModelFactory(Protocol):
    def get_ai(self, model: str | None = None) -> ConversationModel: ...


class OpenAIChatEngine(ChatEngine):
    def __init__(
        self, model_factory: ConversationModelFactory, ai_budget: AiBudget
    ) -> None:
        self._model_factory: ConversationModelFactory = model_factory
        self._ai_budget: AiBudget = ai_budget

    @override
    def answer(self, conversation: Conversation, user_id: str) -> str:
        history = cast("list[AiMessage]", conversation)

        try:
            model = self._model_factory.get_ai()
        except OpenAIError as missing_key:
            raise ChatEngineUnavailableError(_KEY_MISSING) from missing_key

        try:
            answer, cost = model.get_ai_res_hist(
                system_prompt=_SYSTEM_PROMPT, history=history
            )
        except OpenAIError as unreachable:
            raise ChatEngineUnavailableError(
                _MODEL_UNAVAILABLE
            ) from unreachable

        self._ai_budget.record_spending(user_id, OPENAI_ENGINE, cost)

        return answer
