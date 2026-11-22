import pytest

_ACCOUNTS_MARKER = "accounts"
_REQUIREMENTS_MODULE = "test_requirements.py"


def _belongs_to_another_service(item: pytest.Item) -> bool:
    is_requirement = item.path.name == _REQUIREMENTS_MODULE
    is_account_requirement = (
        item.get_closest_marker(_ACCOUNTS_MARKER) is not None
    )

    return is_requirement and not is_account_requirement


def pytest_collection_modifyitems(
    config: pytest.Config, items: list[pytest.Item]
) -> None:
    kept_items: list[pytest.Item] = []
    foreign_items: list[pytest.Item] = []

    for item in items:
        if _belongs_to_another_service(item):
            foreign_items.append(item)
        else:
            kept_items.append(item)

    config.hook.pytest_deselected(items=foreign_items)
    items[:] = kept_items
