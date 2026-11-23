from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor
from typing import Protocol

import pytest

from features.study_units_generation import generation_router, generation_tasks
from tests.requirements.requirement_lookup import Sessions

TaskRunner = Callable[..., dict[str, object]]
GeneratedAnswer = dict[str, object]

_FINISHED_TASK_ID = "finished-generation"
_WORKER_THREADS = 1


class GenerationAnswerer(Protocol):
    def get_ai_res(
        self, system_prompt: str, user_prompt: str
    ) -> tuple[GeneratedAnswer, float | None]: ...


class GenerationAi(Protocol):
    def get_ai(self, model: str | None = None) -> GenerationAnswerer: ...


class FinishedTask:
    def __init__(self, task_id: str) -> None:
        self.id: str = task_id


class EagerTask:
    def __init__(self, run_task: TaskRunner) -> None:
        self._run_task: TaskRunner = run_task

    def delay(self, **task_arguments: object) -> FinishedTask:
        with ThreadPoolExecutor(max_workers=_WORKER_THREADS) as worker:
            running_task = worker.submit(self._run_task, **task_arguments)
            _ = running_task.result()

        return FinishedTask(_FINISHED_TASK_ID)


def generate_eagerly(
    monkeypatch: pytest.MonkeyPatch,
    sessions: Sessions,
    generation_ai: GenerationAi,
) -> None:
    eager_tasks = {
        "generate_note_task": EagerTask(generation_tasks._generate_note_task),
        "generate_flashcards_of_type_task": EagerTask(
            generation_tasks._generate_flashcards_of_type_task
        ),
        "generate_test_items_of_type_task": EagerTask(
            generation_tasks._generate_test_items_of_type_task
        ),
    }

    for task_name, eager_task in eager_tasks.items():
        monkeypatch.setattr(generation_router, task_name, eager_task)

    monkeypatch.setattr(generation_tasks, "chosen_ai_factory", generation_ai)
    monkeypatch.setattr(generation_tasks, "SessionLocal", sessions)
