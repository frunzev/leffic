import json
from typing import cast
from unittest import mock

import pika
import pytest
from pika.exceptions import AMQPError

from features.account import events
from tests.broker_fakes import FakeChannel, FakeConnection


def test_an_event_is_published_to_the_topic_exchange() -> None:
    channel = FakeChannel()
    connection = FakeConnection(channel)

    with mock.patch.object(
        pika, "BlockingConnection", return_value=connection
    ):
        events.publish(events.USER_DELETED, {"user_id": "u1"})

    assert channel.exchanges == [events.EXCHANGE]
    assert channel.published[0]["routing_key"] == events.USER_DELETED
    assert json.loads(str(channel.published[0]["body"])) == {"user_id": "u1"}


def test_publishing_waits_for_the_broker_to_confirm() -> None:
    channel = FakeChannel()
    connection = FakeConnection(channel)

    with mock.patch.object(
        pika, "BlockingConnection", return_value=connection
    ):
        events.publish(events.USER_DELETED, {"user_id": "u1"})

    assert channel.confirmed


def test_the_connection_is_always_closed() -> None:
    channel = FakeChannel()
    connection = FakeConnection(channel)

    with mock.patch.object(
        pika, "BlockingConnection", return_value=connection
    ):
        events.publish(events.USER_DELETED, {"user_id": "u1"})

    assert connection.closed


def test_an_unreachable_broker_is_reported() -> None:
    with (
        mock.patch.object(
            pika, "BlockingConnection", side_effect=AMQPError("down")
        ),
        pytest.raises(events.BrokerUnavailableError) as refusal,
    ):
        events.publish(events.USER_DELETED, {"user_id": "u1"})

    assert str(refusal.value) == "The event broker is unreachable."


def test_the_broker_is_reached_at_the_configured_url() -> None:
    channel = FakeChannel()

    with (
        mock.patch.object(
            pika, "BlockingConnection", return_value=FakeConnection(channel)
        ),
        mock.patch.object(pika, "URLParameters") as parameters,
    ):
        events.publish(events.USER_DELETED, {"user_id": "u1"})

    url = cast("str", parameters.call_args.args[0])

    assert url.startswith("amqp://")


def test_a_refused_publish_is_reported() -> None:
    channel = FakeChannel()
    connection = FakeConnection(channel)

    with (
        mock.patch.object(
            pika, "BlockingConnection", return_value=connection
        ),
        mock.patch.object(
            FakeChannel, "basic_publish", side_effect=AMQPError("refused")
        ),
        pytest.raises(events.BrokerUnavailableError),
    ):
        events.publish(events.USER_DELETED, {"user_id": "u1"})

    assert connection.closed


def test_the_exchange_and_message_survive_a_broker_restart() -> None:
    channel = FakeChannel()
    connection = FakeConnection(channel)

    with mock.patch.object(
        pika, "BlockingConnection", return_value=connection
    ):
        events.publish(events.USER_DELETED, {"user_id": "u1"})

    assert channel.exchange_types == ["topic"]
    assert channel.durable_exchanges == [True]
    assert channel.delivery_modes == [2]


def test_the_event_goes_to_the_shared_exchange() -> None:
    channel = FakeChannel()
    connection = FakeConnection(channel)

    with mock.patch.object(
        pika, "BlockingConnection", return_value=connection
    ):
        events.publish(events.USER_DELETED, {"user_id": "u1"})

    assert channel.published[0]["exchange"] == "domain.events"
    assert channel.published[0]["routing_key"] == "user.deleted"
