from abc import ABC, abstractmethod

Conversation = list[dict[str, str]]


class ChatEngineUnavailableError(Exception):
    pass


class ChatEngine(ABC):
    @abstractmethod
    def answer(self, conversation: Conversation, user_id: str) -> str: ...
