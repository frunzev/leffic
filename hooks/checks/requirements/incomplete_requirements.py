import sys
from pathlib import Path

from gherkin.parser import Parser
from gherkin.parser_types import Envelope, Rule

MINIMUM_SCENARIOS = 2
NO_RULE = "holds no rule - write each requirement as a Gherkin Rule"


def _scenario_count(rule: Rule) -> int:
    scenario_count = 0

    for rule_child in rule["children"]:
        if "scenario" in rule_child:
            scenario_count += 1

    return scenario_count


def _feature_children(feature_text: str) -> list[Envelope]:
    document = Parser().parse(feature_text)
    feature = document.get("feature")

    if feature is None:
        return []

    return feature["children"]


def has_rules(feature_text: str) -> bool:
    for feature_child in _feature_children(feature_text):
        if "rule" in feature_child:
            return True

    return False


def incomplete_requirements(feature_text: str) -> list[str]:
    incomplete_names: list[str] = []

    for feature_child in _feature_children(feature_text):
        if "rule" in feature_child:
            rule = feature_child["rule"]

            if _scenario_count(rule) < MINIMUM_SCENARIOS:
                incomplete_names.append(rule["name"])

        if "scenario" in feature_child:
            incomplete_names.append(feature_child["scenario"]["name"])

    return incomplete_names


def main(feature_paths: list[Path]) -> None:
    for feature_path in feature_paths:
        feature_text = feature_path.read_text(encoding="utf-8")

        if not has_rules(feature_text):
            print(f"{feature_path}: {NO_RULE}")

        for incomplete_name in incomplete_requirements(feature_text):
            print(f"{feature_path}: {incomplete_name}")


if __name__ == "__main__":
    paths: list[Path] = []

    for argument in sys.argv[1:]:
        paths.append(Path(argument))

    main(paths)
