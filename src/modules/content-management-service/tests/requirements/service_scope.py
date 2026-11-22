import pytest

_FOREIGN_MARKERS = ("accounts", "ui")


def _belongs_to_another_service(item: pytest.Item) -> bool:
    for foreign_marker in _FOREIGN_MARKERS:
        if item.get_closest_marker(foreign_marker) is not None:
            return True

    return False


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
