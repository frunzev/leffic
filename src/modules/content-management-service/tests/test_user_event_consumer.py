import json
from typing import cast
from unittest import mock

import pika
import pytest
from sqlalchemy.orm import Session

from features.user_events import consumer
from shared.local_disk_file_storage import LocalDiskFileStorage
from tests.consumer_fakes import FakeChannel, FakeConnection, FakeMethod


def test_a_deletion_event_removes_that_users_content() -> None:
    with mock.patch.object(consumer, "remove_everything_owned_by") as remove:
        consumer.handle(json.dumps({"user_id": "u1"}).encode())

    stored_files = cast("object", remove.call_args.kwargs["file_storage"])

    assert isinstance(remove.call_args.args[0], Session)
    assert remove.call_args.args[1] == "u1"
    assert isinstance(stored_files, LocalDiskFileStorage)


def test_an_event_without_a_user_is_ignored() -> None:
    with mock.patch.object(consumer, "remove_everything_owned_by") as remove:
        consumer.handle(json.dumps({"nothing": True}).encode())

    assert remove.call_args is None


def test_an_event_that_is_not_an_object_is_ignored() -> None:
    with mock.patch.object(consumer, "remove_everything_owned_by") as remove:
        consumer.handle(json.dumps(["not", "an", "object"]).encode())

    assert remove.call_args is None


def test_the_consumer_binds_its_queue_to_the_deletion_key() -> None:
    channel = FakeChannel()

    with (
        mock.patch.object(
            pika,
            "BlockingConnection",
            return_value=FakeConnection(channel),
        ),
        mock.patch.object(pika, "URLParameters") as parameters,
    ):
        consumer.consume()

    url = cast("str", parameters.call_args.args[0])

    assert url.startswith("amqp://")
    assert channel.queues == [consumer.QUEUE]
    assert channel.bindings == [
        (consumer.QUEUE, consumer.EXCHANGE, consumer.USER_DELETED)
    ]
    assert channel.consumed == [consumer.QUEUE]
    assert channel.callbacks == [consumer._on_message]
    assert channel.started


def test_a_handled_message_is_acknowledged() -> None:
    channel = FakeChannel()

    with mock.patch.object(consumer, "remove_everything_owned_by"):
        consumer._on_message(
            channel,
            FakeMethod(7),
            None,
            json.dumps({"user_id": "u1"}).encode(),
        )

    assert channel.acknowledged == [7]


def test_a_message_that_fails_is_not_acknowledged() -> None:
    channel = FakeChannel()

    with (
        mock.patch.object(
            consumer,
            "remove_everything_owned_by",
            side_effect=RuntimeError("down"),
        ),
        pytest.raises(RuntimeError),
    ):
        consumer._on_message(
            channel,
            FakeMethod(7),
            None,
            json.dumps({"user_id": "u1"}).encode(),
        )

    assert channel.acknowledged == []


def test_an_unreadable_message_is_dropped_rather_than_retried() -> None:
    channel = FakeChannel()

    consumer._on_message(channel, FakeMethod(7), None, b"not json")

    assert channel.acknowledged == [7]


def test_the_queue_and_exchange_survive_a_broker_restart() -> None:
    channel = FakeChannel()

    with (
        mock.patch.object(
            pika,
            "BlockingConnection",
            return_value=FakeConnection(channel),
        ),
        mock.patch.object(pika, "URLParameters"),
    ):
        consumer.consume()

    assert channel.exchanges == [consumer.EXCHANGE]
    assert channel.exchange_types == ["topic"]
    assert channel.durable_exchanges == [True]
    assert channel.durable_queues == [True]


def test_an_event_with_a_non_string_user_is_ignored() -> None:
    with mock.patch.object(consumer, "remove_everything_owned_by") as remove:
        consumer.handle(json.dumps({"user_id": 42}).encode())

    assert remove.call_args is None
