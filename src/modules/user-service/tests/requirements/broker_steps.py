import json
from typing import cast, override

import pika
import pytest
from pika.exceptions import AMQPError
from pytest_bdd import given, then

from features.account.events import USER_DELETED
from tests.broker_fakes import FakeChannel, FakeConnection

_REFUSED_CONNECTION = "connection refused"
_DROPPED_MESSAGE = "message dropped"


class DroppingChannel(FakeChannel):
    @override
    def basic_publish(
        self,
        *,
        exchange: str,
        routing_key: str,
        body: bytes,
        properties: pika.BasicProperties | None = None,
    ) -> None:
        _ = (exchange, routing_key, body, properties)

        raise AMQPError(_DROPPED_MESSAGE)


class FakeBroker:
    def __init__(self, channel: FakeChannel) -> None:
        self.channel: FakeChannel = channel

    def connect(self, parameters: pika.URLParameters) -> FakeConnection:
        _ = parameters

        return FakeConnection(self.channel)


def _refuse_connection(parameters: pika.URLParameters) -> FakeConnection:
    _ = parameters

    raise AMQPError(_REFUSED_CONNECTION)


@pytest.fixture
def event_broker(monkeypatch: pytest.MonkeyPatch) -> FakeChannel:
    channel = FakeChannel()
    broker = FakeBroker(channel)
    monkeypatch.setattr(pika, "BlockingConnection", broker.connect)

    return channel


@given("the event broker is unreachable")
def make_broker_unreachable(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(pika, "BlockingConnection", _refuse_connection)


@given("the event broker drops every message")
def make_broker_drop_messages(monkeypatch: pytest.MonkeyPatch) -> None:
    broker = FakeBroker(DroppingChannel())
    monkeypatch.setattr(pika, "BlockingConnection", broker.connect)


@then("my deletion is announced")
def check_deletion_announced(event_broker: FakeChannel) -> None:
    announcement = event_broker.published[0]
    announced_body = cast(
        "dict[str, object]", json.loads(str(announcement["body"]))
    )

    assert announcement["routing_key"] == USER_DELETED
    assert announced_body["user_id"]
