import os
import signal
from threading import Thread

import hypothesis
import pytest
from hypothesis import strategies as st
from pytest_bdd import parsers, then, when

from desktop import parent_watch
from desktop.desktop_port import read_desktop_port
from tests.celery_probe import DOUBLING, finished_result, started_worker

_PORT_VARIABLE = "DESKTOP_PORT"
_PROPERTY_EXAMPLES = 60
_UNREADABLE_PORTS = st.text(max_size=8).filter(
    lambda port_text: not (port_text.isascii() and port_text.isdigit())
)


class SentSignals:
    def __init__(self) -> None:
        self.received: list[tuple[int, int]] = []

    def kill(self, process_id: int, sent_signal: int) -> None:
        self.received.append((process_id, sent_signal))


@hypothesis.settings(max_examples=_PROPERTY_EXAMPLES, deadline=None)
@hypothesis.given(port_text=_UNREADABLE_PORTS)
def _refuses_every_unreadable_port(port_text: str) -> None:
    with pytest.raises(ValueError, match=_PORT_VARIABLE):
        _ = read_desktop_port({_PORT_VARIABLE: port_text})


@then(
    "every port that is not a whole number is refused for the desktop backend"
)
def check_unreadable_ports_refused() -> None:
    _refuses_every_unreadable_port()


@when(
    "the desktop backend stops its own process", target_fixture="sent_signals"
)
def stop_own_process(monkeypatch: pytest.MonkeyPatch) -> SentSignals:
    sent_signals = SentSignals()
    monkeypatch.setattr(os, "kill", sent_signals.kill)
    parent_watch.stop_this_process()

    return sent_signals


@then("it sends its own process the termination signal")
def check_termination_signal(sent_signals: SentSignals) -> None:
    own_process_id = os.getpid()

    assert sent_signals.received == [(own_process_id, signal.SIGTERM)]


@when(
    "the desktop backend starts its generation worker",
    target_fixture="worker_thread",
)
def start_worker() -> Thread:
    return started_worker()


@when(
    parsers.parse("a generation job doubling {number:d} is queued"),
    target_fixture="queued_job_id",
)
def queue_generation_job(number: int) -> str:
    queued_job = DOUBLING.delay(number=number)

    return str(queued_job.id)


@then(parsers.parse("the job finishes inside the backend with {doubled:d}"))
def check_job_finished(queued_job_id: str, doubled: int) -> None:
    assert finished_result(queued_job_id) == {"doubled": doubled}


@then("the worker thread ends with the backend")
def check_worker_daemon(worker_thread: Thread) -> None:
    assert worker_thread.daemon
    assert worker_thread.is_alive()
