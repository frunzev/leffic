import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

from desktop.desktop_port import read_desktop_port

_PORT_VARIABLE = "DESKTOP_PORT"
_LOWEST_UNPRIVILEGED_PORT = 1024
_HIGHEST_PORT = 65535

_UNPRIVILEGED_PORTS = st.integers(
    min_value=_LOWEST_UNPRIVILEGED_PORT, max_value=_HIGHEST_PORT
)
_PRIVILEGED_PORTS = st.integers(
    min_value=0, max_value=_LOWEST_UNPRIVILEGED_PORT - 1
)
_PORTS_ABOVE_THE_RANGE = st.integers(min_value=_HIGHEST_PORT + 1)
_TEXT_THAT_IS_NO_WHOLE_NUMBER = st.text(max_size=8).filter(
    lambda candidate: not (candidate.isascii() and candidate.isdigit())
)
_REFUSED_PORT_TEXT = st.one_of(
    _PRIVILEGED_PORTS.map(str),
    _PORTS_ABOVE_THE_RANGE.map(str),
    _TEXT_THAT_IS_NO_WHOLE_NUMBER,
)


@settings(max_examples=100)
@given(_UNPRIVILEGED_PORTS)
def test_read_desktop_port_property_returns_every_unprivileged_port(
    port: int,
) -> None:
    environment = {_PORT_VARIABLE: str(port)}

    assert read_desktop_port(environment) == port


@settings(max_examples=100)
@given(_REFUSED_PORT_TEXT)
def test_read_desktop_port_property_refuses_text_outside_the_range(
    port_text: str,
) -> None:
    environment = {_PORT_VARIABLE: port_text}

    with pytest.raises(ValueError, match=_PORT_VARIABLE):
        _ = read_desktop_port(environment)


@settings(max_examples=25)
@given(st.dictionaries(st.sampled_from(["PORT", "HOME"]), st.text()))
def test_read_desktop_port_property_refuses_an_environment_without_it(
    environment: dict[str, str],
) -> None:
    with pytest.raises(ValueError, match=_PORT_VARIABLE):
        _ = read_desktop_port(environment)
