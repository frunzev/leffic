from datetime import UTC, datetime

_MONTH_FORMAT = "%Y-%m"


def current_month() -> str:
    return datetime.now(UTC).strftime(_MONTH_FORMAT)


def spent_this_month(spent_cents: int, spent_month: str, month: str) -> int:
    if spent_month != month:
        return 0

    return spent_cents


def can_spend(limit_cents: int | None, spent_cents: int) -> bool:
    if limit_cents is None:
        return True

    return spent_cents < limit_cents


def budget_reply(
    limit_cents: int | None, spent_cents: int
) -> dict[str, object]:
    return {
        "monthly_limit_cents": limit_cents,
        "spent_cents": spent_cents,
        "can_spend": can_spend(limit_cents, spent_cents),
    }
