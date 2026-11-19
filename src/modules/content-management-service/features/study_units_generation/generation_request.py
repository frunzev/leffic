from typing import Literal, Self

from pydantic import BaseModel, Field, PositiveInt, model_validator

_UNREQUESTED_AMOUNT = "An amount was given for types not requested:"


class UnrequestedAmountError(ValueError):
    def __init__(self, unrequested_types: list[str]) -> None:
        super().__init__(
            f"{_UNREQUESTED_AMOUNT} {', '.join(unrequested_types)}"
        )


class TypedUnitsMetadata[TypeName: str](BaseModel, extra="forbid"):
    types: list[TypeName] | None = None
    amounts: dict[str, PositiveInt] = Field(default_factory=dict)

    @model_validator(mode="after")
    def validated_amounts(self) -> Self:
        unrequested_types = sorted(set(self.amounts) - set(self.types or ()))

        if unrequested_types:
            raise UnrequestedAmountError(unrequested_types)

        return self


class FlashcardsMetadata(
    TypedUnitsMetadata[Literal["basic", "list", "cloze", "feynman"]]
):
    comprehensiveness: Literal["high", "medium", "low"] | None = "medium"
    verbosity: Literal["high", "medium", "low"] | None = "low"


class NoteMetadata(BaseModel):
    pass


class TestMetadata(
    TypedUnitsMetadata[
        Literal["multiple_choice", "true_or_false", "short_answer"]
    ]
):
    pass


class GenerationRequest(BaseModel):
    text: str
    folder_id: str | None = None
    source_kind: Literal["file", "link", "topic", "text"] | None = None
    source_reference: str | None = None
    flashcards: FlashcardsMetadata | None = None
    note: NoteMetadata | None = None
    test: TestMetadata | None = None
    ai_model: str | None = None
