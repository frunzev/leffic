import os

os.environ["DATABASE_URL"] = "sqlite://"
os.environ["SCHEDULER_SERVICE"] = "http://scheduler"
os.environ["REDIS_HOST"] = "localhost:6379"
os.environ["OPENAI_API_KEY"] = "test-key-never-a-real-one"
os.environ["JWT_SECRET_KEY"] = "unit-test-secret-key-value"

from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session, sessionmaker

from tests.access_support import crashless_client
from tests.study_unit_access_support import StudyUnitWorld, seeded_world
from tests.support import in_memory_sessions

pytest_plugins = [
    "tests.requirements.service_scope",
    "tests.requirements.reply_steps",
    "tests.requirements.access_steps",
    "tests.requirements.folder_steps",
    "tests.requirements.unit_steps",
    "tests.requirements.stranger_steps",
    "tests.requirements.flashcard_steps",
    "tests.requirements.card_steps",
    "tests.requirements.assessment_steps",
    "tests.requirements.question_steps",
    "tests.requirements.note_steps",
    "tests.requirements.file_steps",
    "tests.requirements.viewing_steps",
    "tests.requirements.reading_steps",
    "tests.requirements.link_steps",
    "tests.requirements.image_steps",
    "tests.requirements.import_steps",
    "tests.requirements.generation_steps",
    "tests.requirements.generation_status_steps",
    "tests.requirements.ask_steps",
    "tests.requirements.ask_tool_steps",
    "tests.requirements.openai_steps",
    "tests.requirements.account_deletion_steps",
]


@pytest.fixture
def sessions() -> sessionmaker[Session]:
    return in_memory_sessions()


@pytest.fixture
def world(sessions: sessionmaker[Session]) -> StudyUnitWorld:
    return seeded_world(sessions)


@pytest.fixture
def client(sessions: sessionmaker[Session]) -> Iterator[TestClient]:
    yield from crashless_client(sessions)
