from abc import ABC, abstractmethod


class JsonAnswerer(ABC):
    @abstractmethod
    def get_ai_res(
        self, system_prompt: str, user_prompt: str
    ) -> tuple[dict[str, object], float | None]: ...
