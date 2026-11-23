from typing import Self

import pika


class FakeChannel:
    def __init__(self) -> None:
        super().__init__()
        self.published: list[dict[str, object]] = []
        self.exchanges: list[str] = []
        self.exchange_types: list[str] = []
        self.durable_exchanges: list[bool] = []
        self.delivery_modes: list[int] = []
        self.confirmed: bool = False

    def confirm_delivery(self) -> None:
        self.confirmed = True

    def exchange_declare(
        self, *, exchange: str, exchange_type: str, durable: bool = False
    ) -> None:
        self.exchanges.append(exchange)
        self.exchange_types.append(exchange_type)
        self.durable_exchanges.append(durable)

    def basic_publish(
        self,
        *,
        exchange: str,
        routing_key: str,
        body: bytes,
        properties: pika.BasicProperties | None = None,
    ) -> None:
        if properties is not None:
            self.delivery_modes.append(properties.delivery_mode)

        self.published.append(
            {
                "exchange": exchange,
                "routing_key": routing_key,
                "body": body.decode(),
            }
        )


class FakeConnection:
    def __init__(self, channel: FakeChannel) -> None:
        super().__init__()
        self.fake_channel: FakeChannel = channel
        self.closed: bool = False

    def channel(self: Self) -> FakeChannel:
        return self.fake_channel

    def close(self) -> None:
        self.closed = True
