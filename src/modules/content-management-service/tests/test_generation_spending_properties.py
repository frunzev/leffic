from decimal import Decimal
from unittest import mock

import pytest
from hypothesis import HealthCheck, given, settings
from hypothesis import strategies as st

from features.study_units_generation import generation_tasks
from features.study_units_generation.generation_tasks import (
    GenerationRequester,
    _billed_generation,
)
from shared.ai_budget import cents_of
from shared.chosen_ai_engine import OPENAI_ENGINE
from tests.account_service_fakes import (
    ACCOUNT_SERVICE_URL,
    FakeAccountService,
    install_account_service,
)

_DOLLARS = st.decimals(
    min_value=Decimal(0),
    max_value=Decimal(5),
    places=4,
    allow_nan=False,
    allow_infinity=False,
)
_PATCHED_SETTINGS = settings(
    max_examples=25,
    deadline=None,
    suppress_health_check=[HealthCheck.function_scoped_fixture],
)
_SPENDING_URL = (
    f"{ACCOUNT_SERVICE_URL}/account/provider-keys/{OPENAI_ENGINE}/spending"
)

GeneratedPayload = dict[str, object]


class PricedAi:
    def __init__(self, payload: GeneratedPayload, dollars: float) -> None:
        self._payload: GeneratedPayload = payload
        self._dollars: float = dollars

    def get_ai_res(
        self, system_prompt: str, user_prompt: str
    ) -> tuple[GeneratedPayload, float | None]:
        _ = (system_prompt, user_prompt)

        return self._payload, self._dollars


class PricedAiFactory:
    def __init__(self, priced_ai: PricedAi) -> None:
        self._priced_ai: PricedAi = priced_ai

    def get_ai(self, model: str | None = None) -> PricedAi:
        _ = model

        return self._priced_ai


@_PATCHED_SETTINGS
@given(
    payload=st.dictionaries(st.text(max_size=5), st.text(max_size=5)),
    dollars=_DOLLARS,
    user_id=st.uuids().map(str),
)
def test__billed_generation_property_records_what_each_answer_cost(
    monkeypatch: pytest.MonkeyPatch,
    payload: dict[str, str],
    dollars: Decimal,
    user_id: str,
) -> None:
    account_service = FakeAccountService(is_open=True)
    install_account_service(monkeypatch, account_service)
    generated: GeneratedPayload = dict(payload)
    factory = PricedAiFactory(PricedAi(generated, float(dollars)))

    with (
        mock.patch.object(generation_tasks, "chosen_ai_factory", factory),
        mock.patch.object(generation_tasks, "CHOSEN_AI_ENGINE", OPENAI_ENGINE),
    ):
        answered = _billed_generation(
            requester=GenerationRequester(user_id=user_id, ai_model=None),
            system_prompt="prompt",
            extracted_text="text",
        )

    assert answered == generated
    assert account_service.recorded == [
        (_SPENDING_URL, cents_of(float(dollars)))
    ]
