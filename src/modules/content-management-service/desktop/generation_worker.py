from threading import Thread

from celery import Celery

_WORKER_POOL = "threads"
_WORKER_THREADS = 3


def start_generation_worker(celery: Celery) -> Thread:
    celery.set_default()

    worker = celery.WorkController(
        pool=_WORKER_POOL,
        concurrency=_WORKER_THREADS,
        without_heartbeat=True,
        without_mingle=True,
        without_gossip=True,
    )
    worker_thread = Thread(target=worker.start, daemon=True)
    worker_thread.start()

    return worker_thread
