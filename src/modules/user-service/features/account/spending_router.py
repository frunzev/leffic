from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from pydantic import BaseModel, NonNegativeInt
from sqlalchemy.orm import Session

from features.account.claims_extractor import get_user_id_from_jwt
from features.account.monthly_spending import (
    budget_reply,
    current_month,
    spent_this_month,
)
from features.account.provider_key_lookup import saved_provider_key
from shared.database import get_db

spending_router = APIRouter(prefix="/account/provider-keys")

DatabaseSession = Annotated[Session, Depends(get_db)]
AuthenticatedUserId = Annotated[str, Depends(get_user_id_from_jwt)]

_NOTHING_SPENT = 0


class SpendingRequest(BaseModel):
    cents: NonNegativeInt


@spending_router.get("/{provider}/budget")
async def read_budget(
    provider: str, user_id: AuthenticatedUserId, db: DatabaseSession
) -> JSONResponse:
    saved_key = saved_provider_key(db, user_id, provider)

    if saved_key is None:
        return JSONResponse(content=budget_reply(None, _NOTHING_SPENT))

    spent = spent_this_month(
        saved_key.spent_cents, saved_key.spent_month, current_month()
    )

    return JSONResponse(
        content=budget_reply(saved_key.monthly_limit_cents, spent)
    )


@spending_router.post("/{provider}/spending")
async def record_spending(
    provider: str,
    request_data: SpendingRequest,
    user_id: AuthenticatedUserId,
    db: DatabaseSession,
) -> JSONResponse:
    saved_key = saved_provider_key(db, user_id, provider)

    if saved_key is None:
        return JSONResponse(content=budget_reply(None, _NOTHING_SPENT))

    month = current_month()
    spent = spent_this_month(
        saved_key.spent_cents, saved_key.spent_month, month
    )
    saved_key.spent_cents = spent + request_data.cents
    saved_key.spent_month = month
    db.commit()

    return JSONResponse(
        content=budget_reply(
            saved_key.monthly_limit_cents, saved_key.spent_cents
        )
    )
