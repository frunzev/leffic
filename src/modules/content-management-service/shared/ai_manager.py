from abc import ABC, abstractmethod
from collections.abc import Callable
from typing import override

from openai import OpenAI, OpenAIError
from openai.types.responses import (
    EasyInputMessageParam,
    Response,
    ResponseInputItemParam,
)

from shared.json_answerer import JsonAnswerer
from shared.json_extraction import get_dict_from_text
from shared.model_rates import GPT_5_MINI, MODEL_RATES, ModelRates

_ATTEMPTS = 2
_ALL_ATTEMPTS_FAILED = "The AI model did not answer"

AiMessage = ResponseInputItemParam
PricedAnswer = tuple[str, float | None]


class AIManager(JsonAnswerer, ABC):
    @abstractmethod
    def get_ai_res_hist(
        self, system_prompt: str, history: list[AiMessage]
    ) -> PricedAnswer: ...


class RequestCost:
    def __init__(self, rates: ModelRates | None) -> None:
        self.rates: ModelRates | None = rates

    def of(self, response: Response) -> float | None:
        usage = response.usage

        if self.rates is None or usage is None:
            return None

        cached_tokens = usage.input_tokens_details.cached_tokens

        return (
            usage.input_tokens * self.rates.input_token_cost
            + usage.output_tokens * self.rates.output_token_cost
            + cached_tokens * self.rates.cached_token_cost
        )


class OpenAIManager(AIManager):
    def __init__(
        self, client: OpenAI, model_name: str, request_cost: RequestCost
    ) -> None:
        self.client: OpenAI = client
        self.model_name: str = model_name
        self.request_cost: RequestCost = request_cost

    @override
    def get_ai_res(
        self, system_prompt: str, user_prompt: str
    ) -> tuple[dict[str, object], float | None]:
        history: list[AiMessage] = [
            EasyInputMessageParam(role="developer", content=system_prompt),
            EasyInputMessageParam(role="user", content=user_prompt),
        ]
        last_error: OpenAIError | None = None

        for _ in range(_ATTEMPTS):
            try:
                response = self._answer(history)
            except OpenAIError as error:
                last_error = error
                continue

            return (
                get_dict_from_text(response.output_text),
                self.request_cost.of(response),
            )

        raise RuntimeError(_ALL_ATTEMPTS_FAILED) from last_error

    @override
    def get_ai_res_hist(
        self, system_prompt: str, history: list[AiMessage]
    ) -> PricedAnswer:
        conversation: list[AiMessage] = [
            EasyInputMessageParam(role="developer", content=system_prompt),
            *history,
        ]
        response = self._answer(conversation)

        return response.output_text, self.request_cost.of(response)

    def _answer(self, history: list[AiMessage]) -> Response:
        return self.client.responses.create(
            model=self.model_name, input=history
        )


AIBuilder = Callable[[str, ModelRates | None], AIManager]


class AIFactory:
    def __init__(self, builder: AIBuilder) -> None:
        self._builder: AIBuilder = builder

    def get_ai(self, model: str | None = None) -> AIManager:
        model_name = model or GPT_5_MINI

        return self._builder(model_name, MODEL_RATES.get(model_name))


class OpenAIClientSource:
    def __init__(self, client: OpenAI | None) -> None:
        self._client: OpenAI | None = client

    def client(self) -> OpenAI:
        if self._client is None:
            self._client = OpenAI()

        return self._client


def create_openai_factory(client: OpenAI | None = None) -> AIFactory:
    client_source = OpenAIClientSource(client)

    return AIFactory(
        lambda model, rates: OpenAIManager(
            client_source.client(), model, RequestCost(rates)
        )
    )


ai_factory = create_openai_factory()
