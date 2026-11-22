import os
import signal
from unittest import mock

from hypothesis import given, settings
from hypothesis import strategies as st

from desktop.parent_watch import (
    _wait_for_orphaning,
    stop_this_process,
    watch_parent,
)

_PARENT_IDS = st.integers(min_value=2, max_value=99_999)
_LIVING_POLLS = st.integers(min_value=0, max_value=5)
_NO_PAUSE = 0.0
_OS_KILL = "desktop.parent_watch.os.kill"
_ADOPTED_BY_LAUNCHD = 1


class ParentHistory:
    def __init__(self, parent_id: int, living_polls: int) -> None:
        self.parent_id: int = parent_id
        self.living_polls: int = living_polls
        self.reads: int = 0
        self.events: list[str] = []

    def read_parent_id(self) -> int:
        self.reads += 1
        self.events.append("read")

        if self.reads <= self.living_polls:
            return self.parent_id

        return _ADOPTED_BY_LAUNCHD

    def record_orphaning(self) -> None:
        self.events.append("orphaned")


@settings(max_examples=50, deadline=None)
@given(_PARENT_IDS, _LIVING_POLLS)
def test__wait_for_orphaning_property_reacts_once_parent_dies(
    parent_id: int, living_polls: int
) -> None:
    history = ParentHistory(parent_id, living_polls)

    _wait_for_orphaning(
        parent_id,
        history.read_parent_id,
        history.record_orphaning,
        _NO_PAUSE,
    )

    assert history.events == ["read"] * (living_polls + 1) + ["orphaned"]


@settings(max_examples=20, deadline=None)
@given(_PARENT_IDS, _LIVING_POLLS)
def test_watch_parent_property_watches_in_a_daemon_thread(
    parent_id: int, living_polls: int
) -> None:
    history = ParentHistory(parent_id, living_polls)

    watcher = watch_parent(
        parent_id,
        history.read_parent_id,
        history.record_orphaning,
        _NO_PAUSE,
    )
    watcher.join(timeout=5)

    assert watcher.daemon
    assert not watcher.is_alive()
    assert history.events[-1] == "orphaned"


@settings(max_examples=10, deadline=None)
@given(st.just(signal.SIGTERM))
def test_stop_this_process_property_terminates_this_process(
    termination: signal.Signals,
) -> None:
    with mock.patch(_OS_KILL) as kill:
        stop_this_process()

    kill.assert_called_once_with(os.getpid(), termination)
