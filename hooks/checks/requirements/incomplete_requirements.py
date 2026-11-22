import sys
from pathlib import Path

from gherkin.parser import Parser
from gherkin.parser_types import Rule

MINIMUM_SCENARIOS = 2


def _scenario_count(rule: Rule) -> int:
    scenario_count = 0

    for rule_child in rule["children"]:
        if "scenario" in rule_child:
            scenario_count += 1

    return scenario_count


def incomplete_requirements(feature_text: str) -> list[str]:
    document = Parser().parse(feature_text)
    incomplete_names: list[str] = []

    for feature_child in document["feature"]["children"]:
        if "rule" in feature_child:
            rule = feature_child["rule"]

            if _scenario_count(rule) < MINIMUM_SCENARIOS:
                incomplete_names.append(rule["name"])

        if "scenario" in feature_child:
            incomplete_names.append(feature_child["scenario"]["name"])

    return incomplete_names


def main(requirements_path: Path) -> None:
    feature_text = requirements_path.read_text(encoding="utf-8")

    for incomplete_name in incomplete_requirements(feature_text):
        print(incomplete_name)


if __name__ == "__main__":
    main(Path(sys.argv[1]))
