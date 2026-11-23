from shared.model_rates import (
    GPT_4_1_NANO,
    GPT_5_MINI,
    MODEL_RATES,
    ModelRates,
)

_PER_MILLION = 1_000_000


def test_gpt_5_mini_is_priced_at_its_published_rates() -> None:
    assert MODEL_RATES[GPT_5_MINI] == ModelRates(
        input_token_cost=0.25 / _PER_MILLION,
        output_token_cost=2.00 / _PER_MILLION,
        cached_token_cost=0.025 / _PER_MILLION,
    )


def test_gpt_4_1_nano_is_priced_at_its_published_rates() -> None:
    assert MODEL_RATES[GPT_4_1_NANO] == ModelRates(
        input_token_cost=0.10 / _PER_MILLION,
        output_token_cost=0.40 / _PER_MILLION,
        cached_token_cost=0.025 / _PER_MILLION,
    )
