from typing import Self, cast

from openai import OpenAI, OpenAIError
from openai.types.responses import Response

from shared.ai_manager import OpenAIManager, RequestCost
from shared.model_rates import ModelRates


class FakeUsageDetails:
    def __init__(self, cached_tokens: int) -> None:
        self.cached_tokens: int = cached_tokens


class FakeUsage:
    def __init__(
        self, input_tokens: int, output_tokens: int, cached_tokens: int
    ) -> None:
        self.input_tokens: int = input_tokens
        self.output_tokens: int = output_tokens
        self.input_tokens_details: FakeUsageDetails = FakeUsageDetails(
            cached_tokens
        )


class FakeResponse:
    def __init__(
        self, output_text: str, usage: FakeUsage | None = None
    ) -> None:
        self.output_text: str = output_text
        self.usage: FakeUsage | None = usage


class FakeResponses:
    def __init__(self, answers: list[object]) -> None:
        self.answers: list[object] = answers
        self.calls: list[object] = []

    def create(self, **kwargs: object) -> object:
        self.calls.append(kwargs)
        answer = self.answers.pop(0)

        if isinstance(answer, OpenAIError):
            raise answer

        return answer


class FakeClient:
    def __init__(self, answers: list[object]) -> None:
        self.responses: FakeResponses = FakeResponses(answers)

    def __enter__(self) -> Self:
        return self

    def __exit__(self, *_: object) -> None:
        return None


def as_response(fake: FakeResponse) -> Response:
    return cast("Response", cast("object", fake))


def as_openai(fake: FakeClient) -> OpenAI:
    return cast("OpenAI", cast("object", fake))


def openai_manager(
    answers: list[object], model: str, rates: ModelRates | None
) -> tuple[OpenAIManager, FakeClient]:
    client = FakeClient(answers)
    manager = OpenAIManager(as_openai(client), model, RequestCost(rates))

    return manager, client
