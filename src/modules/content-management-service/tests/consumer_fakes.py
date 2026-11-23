from typing import Self


class FakeChannel:
    def __init__(self) -> None:
        super().__init__()
        self.bindings: list[tuple[str, str, str]] = []
        self.exchanges: list[str] = []
        self.queues: list[str] = []
        self.durable_queues: list[bool] = []
        self.durable_exchanges: list[bool] = []
        self.exchange_types: list[str] = []
        self.consumed: list[str] = []
        self.callbacks: list[object] = []
        self.acknowledged: list[int] = []
        self.started: bool = False

    def exchange_declare(
        self, *, exchange: str, exchange_type: str, durable: bool = False
    ) -> None:
        self.exchanges.append(exchange)
        self.exchange_types.append(exchange_type)
        self.durable_exchanges.append(durable)

    def queue_declare(self, *, queue: str, durable: bool = False) -> None:
        self.queues.append(queue)
        self.durable_queues.append(durable)

    def queue_bind(
        self, *, queue: str, exchange: str, routing_key: str
    ) -> None:
        self.bindings.append((queue, exchange, routing_key))

    def basic_consume(
        self, *, queue: str, on_message_callback: object
    ) -> None:
        self.consumed.append(queue)
        self.callbacks.append(on_message_callback)

    def basic_ack(self, *, delivery_tag: int) -> None:
        self.acknowledged.append(delivery_tag)

    def start_consuming(self) -> None:
        self.started = True


class FakeConnection:
    def __init__(self, channel: FakeChannel) -> None:
        super().__init__()
        self.fake_channel: FakeChannel = channel

    def channel(self: Self) -> FakeChannel:
        return self.fake_channel


class FakeMethod:
    def __init__(self, delivery_tag: int) -> None:
        super().__init__()
        self.delivery_tag: int = delivery_tag
