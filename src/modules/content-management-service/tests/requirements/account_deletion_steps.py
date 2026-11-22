import json

import pytest
from pytest_bdd import when

from features.user_events import consumer
from tests.requirements.requirement_lookup import Sessions
from tests.support import USER_ID


@when("my account is deleted")
def delete_my_account(
    monkeypatch: pytest.MonkeyPatch, sessions: Sessions
) -> None:
    monkeypatch.setattr(consumer, "SessionLocal", sessions)
    user_deleted_event = json.dumps({"user_id": USER_ID}).encode()

    consumer.handle(user_deleted_event)
