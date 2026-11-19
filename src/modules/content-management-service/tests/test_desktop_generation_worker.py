import tempfile
import time
from functools import cache
from pathlib import Path
from threading import Thread

from celery import Celery
from celery.result import AsyncResult
from hypothesis import given, settings
from hypothesis import strategies as st

from desktop.generation_worker import start_generation_worker

_RESULTS_FILE = Path(tempfile.mkdtemp()) / "results.sqlite"
_PROBE_APP = Celery(
    "desktop-worker-probe",
    broker="memory://",
    backend=f"db+sqlite:///{_RESULTS_FILE}",
)
_FINISHED = "SUCCESS"
_POLL_SECONDS = 0.05
_PATIENCE_SECONDS = 10.0


def _doubled(number: int) -> dict[str, int]:
    return {"doubled": number * 2}


_DOUBLING = _PROBE_APP.task(_doubled, name="desktop_probe_double")


@cache
def _started_worker() -> Thread:
    return start_generation_worker(_PROBE_APP)


def _finished_result(task_id: str) -> object:
    deadline = time.monotonic() + _PATIENCE_SECONDS

    while time.monotonic() < deadline:
        task_result = AsyncResult(task_id, app=_PROBE_APP)

        if task_result.ready() and task_result.status == _FINISHED:
            return task_result.result

        time.sleep(_POLL_SECONDS)

    return None


@settings(max_examples=10, deadline=None)
@given(st.integers(min_value=-1000, max_value=1000))
def test_start_generation_worker_property_finishes_every_queued_task(
    number: int,
) -> None:
    _ = _started_worker()

    queued = _DOUBLING.delay(number=number)

    assert _finished_result(queued.id) == {"doubled": number * 2}


@settings(max_examples=5, deadline=None)
@given(st.integers(min_value=1, max_value=5))
def test_start_generation_worker_property_never_keeps_the_process_alive(
    repeats: int,
) -> None:
    for _ in range(repeats):
        worker_thread = _started_worker()

        assert worker_thread.daemon
        assert worker_thread.is_alive()
