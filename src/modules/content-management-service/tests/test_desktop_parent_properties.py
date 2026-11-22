import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

from desktop.desktop_parent import read_parent_process_id

_PARENT_VARIABLE = "DESKTOP_PARENT_PROCESS_ID"
_PROCESS_IDS = st.integers(min_value=2, max_value=2**31 - 1)
_REFUSED_TEXT = st.one_of(
    st.integers(max_value=1).map(str),
    st.text(max_size=8).filter(
        lambda candidate: not (candidate.isascii() and candidate.isdigit())
    ),
)


@settings(max_examples=100)
@given(_PROCESS_IDS)
def test_read_parent_process_id_property_returns_every_real_process_id(
    process_id: int,
) -> None:
    environment = {_PARENT_VARIABLE: str(process_id)}

    assert read_parent_process_id(environment) == process_id


@settings(max_examples=100)
@given(_REFUSED_TEXT)
def test_read_parent_process_id_property_refuses_anything_else(
    refused_text: str,
) -> None:
    with pytest.raises(ValueError, match=_PARENT_VARIABLE):
        _ = read_parent_process_id({_PARENT_VARIABLE: refused_text})


@settings(max_examples=20)
@given(st.dictionaries(st.sampled_from(["PORT", "HOME"]), st.text()))
def test_read_parent_process_id_property_refuses_a_missing_variable(
    environment: dict[str, str],
) -> None:
    with pytest.raises(ValueError, match=_PARENT_VARIABLE):
        _ = read_parent_process_id(environment)
