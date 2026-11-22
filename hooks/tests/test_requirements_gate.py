import sys
from pathlib import Path

from hypothesis import given
from hypothesis import strategies as st

from check_support import (
    HOOKS,
    HYPOTHESIS_SETTINGS,
    repository,
    run_check,
    stage_file,
    stub_binary,
)

REQUIREMENTS_CHECK = HOOKS / "checks" / "requirements"

if str(REQUIREMENTS_CHECK) not in sys.path:
    sys.path.insert(0, str(REQUIREMENTS_CHECK))

from incomplete_requirements import (
    MINIMUM_SCENARIOS,
    incomplete_requirements,
)

FEATURE_FILE = "requirements/folders.feature"
FOLDER_NOTE = "requirements/README.md"
FEATURE_WITHOUT_RULES = "Feature: Leffic\n"
VIRTUAL_ENVIRONMENT_PYTHON = f'exec "{sys.executable}" "$@"\n'
WELL_EXEMPLIFIED_RULE = """Feature: Leffic

  Rule: Home is my own root folder

    Scenario: Opening home shows an empty folder
      When I open home
      Then it is empty

    Scenario: Another user's home is separate
      When another user opens home
      Then it is empty
"""
SINGLE_SCENARIO_RULE = """Feature: Leffic

  Rule: Home cannot be deleted

    Scenario: Deleting home is refused
      When I delete home
      Then I am told "Home folder cannot be deleted!"
"""
BARE_RULE = """Feature: Leffic

  Rule: Folders nest inside each other
"""
LOOSE_SCENARIO = """Feature: Leffic

  Scenario: Opening home shows an empty folder
    When I open home
    Then it is empty
"""
UNREADABLE_FEATURE = "Rule: there is no feature above me\n"
RULE_NAMES = st.lists(
    st.from_regex(r"[A-Za-z][A-Za-z ]{0,20}[A-Za-z]", fullmatch=True),
    min_size=1,
    max_size=5,
    unique=True,
)
TOO_FEW_SCENARIOS = st.integers(min_value=0, max_value=MINIMUM_SCENARIOS - 1)
ENOUGH_SCENARIOS = st.integers(
    min_value=MINIMUM_SCENARIOS, max_value=MINIMUM_SCENARIOS + 3
)


def _feature_with_rules(rule_names: list[str], scenario_count: int) -> str:
    lines = ["Feature: Leffic", ""]

    for rule_name in rule_names:
        lines.append(f"  Rule: {rule_name}")
        lines.append("")

        for scenario_number in range(scenario_count):
            lines.append(f"    Scenario: Example {scenario_number} of {rule_name}")
            lines.append("      When something happens")
            lines.append("")

    return "\n".join(lines) + "\n"


def _checked_repository(tmp_path: Path, feature_text: str | None) -> None:
    repository(tmp_path)
    stub_binary(tmp_path, "python", VIRTUAL_ENVIRONMENT_PYTHON)

    if feature_text is not None:
        stage_file(tmp_path, FEATURE_FILE, feature_text)


def test_accepts_a_rule_with_two_scenarios(tmp_path: Path) -> None:
    _checked_repository(tmp_path, WELL_EXEMPLIFIED_RULE)

    assert run_check(tmp_path, "requirements").returncode == 0


def test_flags_a_rule_with_a_single_scenario(tmp_path: Path) -> None:
    _checked_repository(tmp_path, SINGLE_SCENARIO_RULE)
    finished = run_check(tmp_path, "requirements")

    assert finished.returncode == 1
    assert "Home cannot be deleted" in finished.stderr


def test_flags_a_rule_without_a_scenario(tmp_path: Path) -> None:
    _checked_repository(tmp_path, BARE_RULE)
    finished = run_check(tmp_path, "requirements")

    assert finished.returncode == 1
    assert "Folders nest inside each other" in finished.stderr


def test_flags_a_scenario_outside_any_rule(tmp_path: Path) -> None:
    _checked_repository(tmp_path, LOOSE_SCENARIO)
    finished = run_check(tmp_path, "requirements")

    assert finished.returncode == 1
    assert "Opening home shows an empty folder" in finished.stderr


def test_flags_a_missing_requirements_folder(tmp_path: Path) -> None:
    _checked_repository(tmp_path, None)
    finished = run_check(tmp_path, "requirements")

    assert finished.returncode == 1
    assert "requirements/ is missing" in finished.stderr


def test_flags_a_folder_without_feature_files(tmp_path: Path) -> None:
    _checked_repository(tmp_path, None)
    stage_file(tmp_path, FOLDER_NOTE, "One file per feature.\n")
    finished = run_check(tmp_path, "requirements")

    assert finished.returncode == 1
    assert "holds no .feature file" in finished.stderr


def test_flags_a_feature_file_without_rules(tmp_path: Path) -> None:
    _checked_repository(tmp_path, FEATURE_WITHOUT_RULES)
    finished = run_check(tmp_path, "requirements")

    assert finished.returncode == 1
    assert f"{FEATURE_FILE}: holds no rule" in finished.stderr


def test_flags_an_empty_feature_file(tmp_path: Path) -> None:
    _checked_repository(tmp_path, "")
    finished = run_check(tmp_path, "requirements")

    assert finished.returncode == 1
    assert "holds no rule" in finished.stderr


def test_flags_an_unreadable_requirements_file(tmp_path: Path) -> None:
    _checked_repository(tmp_path, UNREADABLE_FEATURE)

    assert run_check(tmp_path, "requirements").returncode == 1


@HYPOTHESIS_SETTINGS
@given(rule_names=RULE_NAMES, scenario_count=TOO_FEW_SCENARIOS)
def test_incomplete_requirements_property_names_every_thin_rule(
    rule_names: list[str], scenario_count: int
) -> None:
    thin_feature = _feature_with_rules(rule_names, scenario_count)
    flagged_rules = incomplete_requirements(thin_feature)

    assert sorted(flagged_rules) == sorted(rule_names)


@HYPOTHESIS_SETTINGS
@given(rule_names=RULE_NAMES, scenario_count=ENOUGH_SCENARIOS)
def test_incomplete_requirements_property_accepts_every_full_rule(
    rule_names: list[str], scenario_count: int
) -> None:
    full_feature = _feature_with_rules(rule_names, scenario_count)

    assert incomplete_requirements(full_feature) == []
