from hypothesis import given, settings
from hypothesis import strategies as st

from tests.celery_probe import DOUBLING, finished_result, started_worker


@settings(max_examples=10, deadline=None)
@given(st.integers(min_value=-1000, max_value=1000))
def test_start_generation_worker_property_finishes_every_queued_task(
    number: int,
) -> None:
    _ = started_worker()

    queued = DOUBLING.delay(number=number)

    assert finished_result(queued.id) == {"doubled": number * 2}


@settings(max_examples=5, deadline=None)
@given(st.integers(min_value=1, max_value=5))
def test_start_generation_worker_property_never_keeps_the_process_alive(
    repeats: int,
) -> None:
    for _ in range(repeats):
        worker_thread = started_worker()

        assert worker_thread.daemon
        assert worker_thread.is_alive()
