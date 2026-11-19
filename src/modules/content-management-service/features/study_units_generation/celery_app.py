import os

from celery import Celery

REDIS_URL = f"redis://{os.getenv('REDIS_HOST')}"
BROKER_URL = os.getenv("CELERY_BROKER_URL", REDIS_URL)
RESULT_BACKEND_URL = os.getenv("CELERY_RESULT_BACKEND", REDIS_URL)

celery_app = Celery(
    "content",
    broker=BROKER_URL,
    backend=RESULT_BACKEND_URL,
    include=["features.study_units_generation.generation_tasks"],
)
