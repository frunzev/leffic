from pathlib import Path

import pytest
from fastapi import FastAPI
from pytest_bdd import given, parsers, then
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from features.account.models import ProviderKey
from shared import database
from shared.database import Base, get_db
from shared.models import User

_DATABASE_FILE = "accounts.db"

AccountDatabase = sessionmaker[Session]


@given(
    "the account service uses its own database",
    target_fixture="account_database",
)
def use_own_database(
    account_app: FastAPI,
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: Path,
) -> AccountDatabase:
    database_path = tmp_path / _DATABASE_FILE
    engine = create_engine(f"sqlite:///{database_path}")
    Base.metadata.create_all(bind=engine)
    account_database = sessionmaker(bind=engine)
    monkeypatch.setattr(database, "SessionLocal", account_database)
    _ = account_app.dependency_overrides.pop(get_db)

    return account_database


@then(parsers.parse('the account database holds the account "{username}"'))
def check_account_stored(
    account_database: AccountDatabase, username: str
) -> None:
    with account_database() as session:
        stored = session.query(User).filter(User.username == username).all()

    assert len(stored) == 1


@then("the account database holds no saved keys")
def check_no_saved_keys(account_database: AccountDatabase) -> None:
    with account_database() as session:
        saved_key_count = session.query(ProviderKey).count()

    assert saved_key_count == 0
