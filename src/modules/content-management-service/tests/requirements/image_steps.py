import shlex
from pathlib import Path

import pytest
from pytest_bdd import given, parsers

from features.study_units_generation import image_text_extractor

_FAKE_RECOGNIZER = "fake-text-recognizer"
_MISSING_RECOGNIZER = "missing-text-recognizer"
_EXECUTABLE = 0o755
_RECOGNIZER_SCRIPT = "#!/bin/sh\nprintf '%s\\n' {recognized_text}\n"


def _use_recognizer(
    monkeypatch: pytest.MonkeyPatch, recognizer_binary: Path
) -> None:
    monkeypatch.setattr(
        image_text_extractor, "TEXT_RECOGNIZER_BINARY", str(recognizer_binary)
    )


@given(
    parsers.parse(
        'text recognition reads "{recognized_text}" from every image'
    )
)
def install_recognizer(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, recognized_text: str
) -> None:
    recognizer = tmp_path / _FAKE_RECOGNIZER
    script = _RECOGNIZER_SCRIPT.format(
        recognized_text=shlex.quote(recognized_text)
    )
    _ = recognizer.write_text(script, encoding="utf-8")
    recognizer.chmod(_EXECUTABLE)

    _use_recognizer(monkeypatch, recognizer)


@given("text recognition is not available")
def remove_recognizer(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    _use_recognizer(monkeypatch, tmp_path / _MISSING_RECOGNIZER)
