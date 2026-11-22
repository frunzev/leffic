from pathlib import Path

from pytest_bdd import scenarios

_REPOSITORY_ROOT = Path(__file__).parents[4]
_REQUIREMENTS_DIRECTORY = _REPOSITORY_ROOT / "requirements"

scenarios(str(_REQUIREMENTS_DIRECTORY))
