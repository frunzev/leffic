import importlib.util
import os
from types import ModuleType
from typing import cast
from unittest import mock

from hypothesis import given, settings
from hypothesis import strategies as st

from features.study_units_generation.celery_app import celery_app
from tests.migration_support import service_root

_CELERY_APP_FILE = (
    "features",
    "study_units_generation",
    "celery_app.py",
)
_PROBE_MODULE = "celery_configuration_probe"
_MISSING_MODULE = "celery_app.py could not be loaded"

_HOSTS = st.from_regex(r"[a-z]{1,8}:[0-9]{2,5}", fullmatch=True)
_BROKER_URLS = st.sampled_from(
    ["memory://", "redis://cache:6379", "amqp://guest@queue//"]
)
_RESULT_BACKEND_URLS = st.sampled_from(
    ["db+sqlite:///results.sqlite", "redis://cache:6379"]
)


def _freshly_configured(environment: dict[str, str]) -> ModuleType:
    path = service_root().joinpath(*_CELERY_APP_FILE)
    specification = importlib.util.spec_from_file_location(
        _PROBE_MODULE, path
    )

    if specification is None or specification.loader is None:
        raise RuntimeError(_MISSING_MODULE)

    module = importlib.util.module_from_spec(specification)

    with mock.patch.dict(os.environ, environment):
        specification.loader.exec_module(module)

    celery_app.set_current()

    return module


@settings(max_examples=25, deadline=None)
@given(_BROKER_URLS, _RESULT_BACKEND_URLS)
def test_celery_app_property_uses_the_configured_broker_and_backend(
    broker_url: str, result_backend_url: str
) -> None:
    configured = _freshly_configured(
        {
            "CELERY_BROKER_URL": broker_url,
            "CELERY_RESULT_BACKEND": result_backend_url,
        }
    )

    assert cast("str", configured.BROKER_URL) == broker_url
    assert (
        cast("str", configured.RESULT_BACKEND_URL)
        == result_backend_url
    )


@settings(max_examples=25, deadline=None)
@given(_HOSTS)
def test_celery_app_property_falls_back_to_redis_on_the_redis_host(
    redis_host: str,
) -> None:
    with mock.patch.dict(os.environ):
        _ = os.environ.pop("CELERY_BROKER_URL", None)
        _ = os.environ.pop("CELERY_RESULT_BACKEND", None)
        configured = _freshly_configured({"REDIS_HOST": redis_host})

    redis_url = f"redis://{redis_host}"

    assert cast("str", configured.BROKER_URL) == redis_url
    assert cast("str", configured.RESULT_BACKEND_URL) == redis_url
