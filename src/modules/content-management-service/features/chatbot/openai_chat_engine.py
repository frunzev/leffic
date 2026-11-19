from typing import Protocol, cast, override

from openai import OpenAIError

from features.chatbot.chat_engine import (
    ChatEngine,
    ChatEngineUnavailableError,
    Conversation,
)
from shared.ai_manager import AiMessage

_SYSTEM_PROMPT = (
    "You are a very helpful assistant! "
    "You always answer shortly and clearly"
)
_MODEL_UNAVAILABLE = "The assistant is unavailable right now. Try again."
_KEY_MISSING = (
    "OpenAI is not set up. Add an OpenAI API key in Settings, "
    "or choose Claude Code there."
)


class ConversationModel(Protocol):
    def get_ai_res_hist(
        self, system_prompt: str, history: list[AiMessage]
    ) -> str: ...


class ConversationModelFactory(Protocol):
    def get_ai(self, model: str | None = None) -> ConversationModel: ...


class OpenAIChatEngine(ChatEngine):
    def __init__(self, model_factory: ConversationModelFactory) -> None:
        self._model_factory: ConversationModelFactory = model_factory

    @override
    def answer(self, conversation: Conversation, user_id: str) -> str:
        history = cast("list[AiMessage]", conversation)

        try:
            model = self._model_factory.get_ai()
        except OpenAIError as missing_key:
            raise ChatEngineUnavailableError(_KEY_MISSING) from missing_key

        try:
            return model.get_ai_res_hist(
                system_prompt=_SYSTEM_PROMPT, history=history
            )
        except OpenAIError as unreachable:
            raise ChatEngineUnavailableError(
                _MODEL_UNAVAILABLE
            ) from unreachable
