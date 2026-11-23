import tempfile
import time
from functools import cache
from pathlib import Path
from threading import Thread

from celery import Celery
from celery.result import AsyncResult

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


DOUBLING = _PROBE_APP.task(_doubled, name="desktop_probe_double")


@cache
def started_worker() -> Thread:
    return start_generation_worker(_PROBE_APP)


def finished_result(task_id: str) -> object:
    deadline = time.monotonic() + _PATIENCE_SECONDS

    while time.monotonic() < deadline:
        task_result = AsyncResult(task_id, app=_PROBE_APP)

        if task_result.ready() and task_result.status == _FINISHED:
            return task_result.result

        time.sleep(_POLL_SECONDS)

    return None
