from collections.abc import Callable

class TaskResult:
    @property
    def id(self) -> str: ...

class RegisteredTask:
    def delay(self, **kwargs: object) -> TaskResult: ...

class WorkController:
    def start(self) -> None: ...

class Celery:
    def __init__(
        self,
        main: str | None = ...,
        *,
        broker: str | None = ...,
        backend: str | None = ...,
        include: list[str] | None = ...,
    ) -> None: ...
    def task(
        self, fun: Callable[..., object], /, *, name: str = ...
    ) -> RegisteredTask: ...
    def send_task(
        self, name: str, /, *, kwargs: dict[str, object] = ...
    ) -> TaskResult: ...
    def set_current(self) -> None: ...
    def set_default(self) -> None: ...
    def WorkController(
        self,
        *,
        pool: str,
        concurrency: int,
        without_heartbeat: bool,
        without_mingle: bool,
        without_gossip: bool,
    ) -> WorkController: ...
