from collections.abc import Mapping

_PORT_VARIABLE = "DESKTOP_PORT"
_LOWEST_UNPRIVILEGED_PORT = 1024
_HIGHEST_PORT = 65535
_REFUSED_PORT = (
    f"{_PORT_VARIABLE} must be a whole number from "
    f"{_LOWEST_UNPRIVILEGED_PORT} to {_HIGHEST_PORT}"
)


def read_desktop_port(environment: Mapping[str, str]) -> int:
    port_text = environment.get(_PORT_VARIABLE, "")

    if not (port_text.isascii() and port_text.isdigit()):
        raise ValueError(_REFUSED_PORT)

    port = int(port_text)

    if not _LOWEST_UNPRIVILEGED_PORT <= port <= _HIGHEST_PORT:
        raise ValueError(_REFUSED_PORT)

    return port
