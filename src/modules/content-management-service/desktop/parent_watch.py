import os
import signal
import time
from collections.abc import Callable
from threading import Thread

ParentIdReader = Callable[[], int]
OrphaningReaction = Callable[[], None]


def watch_parent(
    parent_id: int,
    read_parent_id: ParentIdReader,
    on_orphaned: OrphaningReaction,
    poll_seconds: float,
) -> Thread:
    watcher = Thread(
        target=_wait_for_orphaning,
        args=(parent_id, read_parent_id, on_orphaned, poll_seconds),
        daemon=True,
    )
    watcher.start()

    return watcher


def _wait_for_orphaning(
    parent_id: int,
    read_parent_id: ParentIdReader,
    on_orphaned: OrphaningReaction,
    poll_seconds: float,
) -> None:
    while read_parent_id() == parent_id:
        time.sleep(poll_seconds)

    on_orphaned()


def stop_this_process() -> None:
    os.kill(os.getpid(), signal.SIGTERM)
