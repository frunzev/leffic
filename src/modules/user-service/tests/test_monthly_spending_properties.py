import re
from datetime import UTC, datetime
from unittest import mock

from hypothesis import given
from hypothesis import strategies as st

from features.account import monthly_spending
from features.account.monthly_spending import (
    budget_reply,
    can_spend,
    current_month,
    spent_this_month,
)

_MONTH_SHAPE = re.compile(r"\d{4}-\d{2}")
_CENTS = st.integers(min_value=0, max_value=10_000_000)
_LIMITS = st.one_of(st.none(), _CENTS)
_MONTHS = st.from_regex(r"20[0-9]{2}-(0[1-9]|1[0-2])", fullmatch=True)
_PRESENT_MOMENTS = st.datetimes(
    min_value=datetime(2000, 1, 1),
    max_value=datetime(9999, 12, 31),
    timezones=st.just(UTC),
)


class FrozenClock:
    def __init__(self, moment: datetime) -> None:
        self._moment: datetime = moment

    def now(self, timezone: object) -> datetime:
        _ = timezone

        return self._moment


@given(moment=_PRESENT_MOMENTS)
def test_current_month_property_names_the_year_and_month_of_now(
    moment: datetime,
) -> None:
    with mock.patch.object(monthly_spending, "datetime", FrozenClock(moment)):
        month = current_month()

    assert _MONTH_SHAPE.fullmatch(month)
    assert month == f"{moment.year:04d}-{moment.month:02d}"


@given(spent_cents=_CENTS, spent_month=_MONTHS, month=_MONTHS)
def test_spent_this_month_property_forgets_every_other_month(
    spent_cents: int, spent_month: str, month: str
) -> None:
    spent = spent_this_month(spent_cents, spent_month, month)

    if spent_month == month:
        assert spent == spent_cents
    else:
        assert spent == 0


@given(limit_cents=_LIMITS, spent_cents=_CENTS)
def test_can_spend_property_closes_once_the_limit_is_reached(
    limit_cents: int | None, spent_cents: int
) -> None:
    is_open = can_spend(limit_cents, spent_cents)

    if limit_cents is None:
        assert is_open
    else:
        assert is_open == (spent_cents < limit_cents)


@given(limit_cents=_LIMITS, spent_cents=_CENTS)
def test_budget_reply_property_reports_what_it_decided(
    limit_cents: int | None, spent_cents: int
) -> None:
    reply = budget_reply(limit_cents, spent_cents)

    assert reply == {
        "monthly_limit_cents": limit_cents,
        "spent_cents": spent_cents,
        "can_spend": can_spend(limit_cents, spent_cents),
    }
