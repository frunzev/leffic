from fastapi import HTTPException, status

from shared.ai_budget import AiBudgetExhaustedError, provide_ai_budget


def ensure_ai_budget(user_id: str, provider: str) -> None:
    try:
        provide_ai_budget().ensure_can_spend(user_id, provider)
    except AiBudgetExhaustedError as exhausted:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=str(exhausted),
        ) from exhausted
