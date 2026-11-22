from pathlib import Path

from pytest_bdd import scenarios

_REPOSITORY_ROOT = Path(__file__).parents[4]
_REQUIREMENTS_FILE = _REPOSITORY_ROOT / "requirements.feature"

scenarios(str(_REQUIREMENTS_FILE))
