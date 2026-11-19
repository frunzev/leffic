from abc import ABC, abstractmethod


class TextExtractor(ABC):
    @abstractmethod
    def extract_text(self, filename: str, extension: str) -> str: ...


class TextExtractorFactory:
    def __init__(self) -> None:
        self._registry: dict[str, TextExtractor] = {}

    def register_extractor(
        self, extension: str, extractor: TextExtractor
    ) -> None:
        self._registry[extension.lower()] = extractor

    def get_text_extractor(self, extension: str) -> TextExtractor | None:
        return self._registry.get(extension.lower())
