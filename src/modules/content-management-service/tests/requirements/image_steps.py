import shlex
from pathlib import Path

import pytest
from pytest_bdd import given, parsers

from features.study_units_generation.text_extractor_registry import (
    text_extractor_factory,
)

_FAKE_RECOGNIZER = "fake-text-recognizer"
_MISSING_RECOGNIZER = "missing-text-recognizer"
_EXECUTABLE = 0o755
_IMAGE_EXTENSION = "png"
_RECOGNIZER_SCRIPT = "#!/bin/sh\nprintf '%s\\n' {recognized_text}\n"
_FAILING_RECOGNIZER_SCRIPT = (
    "#!/bin/sh\nprintf '%s\\n' {complaint} >&2\nexit 1\n"
)


def _use_recognizer(
    monkeypatch: pytest.MonkeyPatch, recognizer_binary: Path
) -> None:
    image_extractor = text_extractor_factory.get_text_extractor(
        _IMAGE_EXTENSION
    )
    monkeypatch.setattr(
        image_extractor, "_recognizer_binary", str(recognizer_binary)
    )


def _install_recognizer_script(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, script: str
) -> None:
    recognizer = tmp_path / _FAKE_RECOGNIZER
    _ = recognizer.write_text(script, encoding="utf-8")
    recognizer.chmod(_EXECUTABLE)
    _use_recognizer(monkeypatch, recognizer)


@given(
    parsers.parse(
        'text recognition reads "{recognized_text}" from every image'
    )
)
def install_recognizer(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, recognized_text: str
) -> None:
    script = _RECOGNIZER_SCRIPT.format(
        recognized_text=shlex.quote(recognized_text)
    )
    _install_recognizer_script(tmp_path, monkeypatch, script)


@given(parsers.parse('text recognition fails saying "{complaint}"'))
def install_failing_recognizer(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, complaint: str
) -> None:
    script = _FAILING_RECOGNIZER_SCRIPT.format(
        complaint=shlex.quote(complaint)
    )
    _install_recognizer_script(tmp_path, monkeypatch, script)


@given("text recognition is not available")
def remove_recognizer(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    _use_recognizer(monkeypatch, tmp_path / _MISSING_RECOGNIZER)
