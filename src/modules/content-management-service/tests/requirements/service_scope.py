import pytest

_ACCOUNTS_MARKER = "accounts"


def pytest_collection_modifyitems(
    config: pytest.Config, items: list[pytest.Item]
) -> None:
    kept_items: list[pytest.Item] = []
    account_items: list[pytest.Item] = []

    for item in items:
        if item.get_closest_marker(_ACCOUNTS_MARKER) is None:
            kept_items.append(item)
        else:
            account_items.append(item)

    config.hook.pytest_deselected(items=account_items)
    items[:] = kept_items
