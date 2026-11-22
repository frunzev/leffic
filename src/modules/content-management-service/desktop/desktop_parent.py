from collections.abc import Mapping

_PARENT_VARIABLE = "DESKTOP_PARENT_PROCESS_ID"
_FIRST_USER_PROCESS_ID = 2
_REFUSED_PARENT = (
    f"{_PARENT_VARIABLE} must be the process id of the app that started "
    "the backend"
)


def read_parent_process_id(environment: Mapping[str, str]) -> int:
    parent_text = environment.get(_PARENT_VARIABLE, "")

    if not (parent_text.isascii() and parent_text.isdigit()):
        raise ValueError(_REFUSED_PARENT)

    parent_process_id = int(parent_text)

    if parent_process_id < _FIRST_USER_PROCESS_ID:
        raise ValueError(_REFUSED_PARENT)

    return parent_process_id
