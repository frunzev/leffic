import json
from unittest import mock

import pika
import pytest
from pytest_bdd import parsers, then, when

from features.user_events import consumer
from tests.consumer_fakes import FakeChannel, FakeConnection
from tests.requirements.requirement_lookup import Sessions
from tests.support import USER_ID

_DELIVERY_TAG = 7
_UNREADABLE_MESSAGE = b"not a deletion message"
_REMOVAL_FAILURE = "the content database is down"


def _my_deletion_message() -> bytes:
    return json.dumps({"user_id": USER_ID}).encode()


@when("my account is deleted")
def delete_my_account(
    monkeypatch: pytest.MonkeyPatch, sessions: Sessions
) -> None:
    monkeypatch.setattr(consumer, "SessionLocal", sessions)
    consumer.handle(_my_deletion_message())


class ConsumedDelivery:
    def __init__(self, delivery_tag: int) -> None:
        self.delivery_tag: int = delivery_tag


def _receive(
    monkeypatch: pytest.MonkeyPatch,
    sessions: Sessions,
    broker_channel: FakeChannel,
    message_body: bytes,
) -> None:
    monkeypatch.setattr(consumer, "SessionLocal", sessions)
    delivery = ConsumedDelivery(_DELIVERY_TAG)
    consumer._on_message(broker_channel, delivery, None, message_body)


def _break_content_removal(*_arguments: object, **_settings: object) -> int:
    raise RuntimeError(_REMOVAL_FAILURE)


@pytest.fixture
def broker_channel() -> FakeChannel:
    return FakeChannel()


@when("the content service starts listening for account deletions")
def start_listening(
    monkeypatch: pytest.MonkeyPatch, broker_channel: FakeChannel
) -> None:
    connection = FakeConnection(broker_channel)
    monkeypatch.setattr(
        pika, "BlockingConnection", mock.Mock(return_value=connection)
    )
    consumer.consume()


@then(
    parsers.parse(
        'it listens on the durable queue "{queue}" for "{routing_key}" messages'
    )
)
def check_listening_queue(
    broker_channel: FakeChannel, queue: str, routing_key: str
) -> None:
    assert broker_channel.queues == [queue]
    assert broker_channel.durable_queues == [True]
    assert broker_channel.bindings == [(queue, consumer.EXCHANGE, routing_key)]
    assert broker_channel.consumed == [queue]
    assert broker_channel.started


@when("the account deletion message for me arrives")
def receive_my_deletion(
    monkeypatch: pytest.MonkeyPatch,
    sessions: Sessions,
    broker_channel: FakeChannel,
) -> None:
    _receive(monkeypatch, sessions, broker_channel, _my_deletion_message())


@when("an unreadable account deletion message arrives")
def receive_unreadable_deletion(
    monkeypatch: pytest.MonkeyPatch,
    sessions: Sessions,
    broker_channel: FakeChannel,
) -> None:
    _receive(monkeypatch, sessions, broker_channel, _UNREADABLE_MESSAGE)


@when(
    "the account deletion message for me arrives but removing content breaks"
)
def receive_deletion_while_broken(
    monkeypatch: pytest.MonkeyPatch,
    sessions: Sessions,
    broker_channel: FakeChannel,
) -> None:
    monkeypatch.setattr(
        consumer, "remove_everything_owned_by", _break_content_removal
    )

    with pytest.raises(RuntimeError, match=_REMOVAL_FAILURE):
        _receive(monkeypatch, sessions, broker_channel, _my_deletion_message())


@then("the message is acknowledged")
def check_acknowledged(broker_channel: FakeChannel) -> None:
    assert broker_channel.acknowledged == [_DELIVERY_TAG]


@then("the message is not acknowledged")
def check_not_acknowledged(broker_channel: FakeChannel) -> None:
    assert broker_channel.acknowledged == []
