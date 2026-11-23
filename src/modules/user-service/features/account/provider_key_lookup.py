import uuid

from sqlalchemy.orm import Session

from features.account.models import ProviderKey


def provider_keys_of(db: Session, user_id: str) -> list[ProviderKey]:
    return (
        db.query(ProviderKey)
        .filter(ProviderKey.user_id == uuid.UUID(user_id))
        .all()
    )


def saved_provider_key(
    db: Session, user_id: str, provider: str
) -> ProviderKey | None:
    return (
        db.query(ProviderKey)
        .filter(
            ProviderKey.user_id == uuid.UUID(user_id),
            ProviderKey.provider == provider,
        )
        .first()
    )
