import subprocess
from typing import cast
from unittest import mock

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

from features.study_units_generation.image_text_extractor import (
    ImageTextExtractor,
    TextRecognitionError,
)
from tests.extracted_text_support import WHITESPACE_PADDING

_IMAGE_EXTENSIONS = st.sampled_from(
    ["gif", "jpg", "jpeg", "png", "tiff", "tif"]
)
_STEMS = st.text(alphabet="abcdef", min_size=1, max_size=8)
_SUBPROCESS_RUN = (
    "features.study_units_generation.image_text_extractor.subprocess.run"
)
_TEXT_RECOGNIZER_BINARIES = (
    "tesseract",
    "/opt/homebrew/bin/tesseract",
    "/usr/bin/tesseract",
    "/Applications/Leffic.app/tools/leffic-text-recognizer",
)
_SCAN_PATH = "/work/scan.png"
_DEFAULT_RECOGNIZER = "tesseract"
_STANDARD_OUTPUT = "stdout"
_RECOGNIZER_MISSING = "Text recognition is not available"


def _recognition(
    return_code: int, recognized: bytes, complaint: bytes
) -> subprocess.CompletedProcess[bytes]:
    return subprocess.CompletedProcess(
        args=[], returncode=return_code, stdout=recognized, stderr=complaint
    )


@settings(max_examples=50)
@given(st.text(max_size=40), WHITESPACE_PADDING, WHITESPACE_PADDING)
def test_extract_text_property_image_returns_the_recognized_text_stripped(
    body: str, before: str, after: str
) -> None:
    recognized = f"{before}{body}{after}".encode()
    succeeded = _recognition(0, recognized, b"")

    with mock.patch(_SUBPROCESS_RUN, return_value=succeeded):
        extracted = ImageTextExtractor(_DEFAULT_RECOGNIZER).extract_text(
            _SCAN_PATH, "png"
        )

    assert extracted == body.strip()


@settings(max_examples=50)
@given(_STEMS, _IMAGE_EXTENSIONS, st.sampled_from(_TEXT_RECOGNIZER_BINARIES))
def test_extract_text_property_image_runs_the_configured_tesseract(
    stem: str, extension: str, binary: str
) -> None:
    filename = f"/work/{stem}.{extension}"
    succeeded = _recognition(0, b"", b"")

    with mock.patch(_SUBPROCESS_RUN, return_value=succeeded) as run:
        _ = ImageTextExtractor(binary).extract_text(filename, extension)

    command = cast("list[str]", run.call_args.args[0])

    assert command == [binary, filename, _STANDARD_OUTPUT]


@settings(max_examples=10, deadline=None)
@given(st.sampled_from(_TEXT_RECOGNIZER_BINARIES))
def test_extract_text_property_image_names_a_missing_recognizer(
    binary: str,
) -> None:
    missing = FileNotFoundError(binary)

    with (
        mock.patch(_SUBPROCESS_RUN, side_effect=missing),
        pytest.raises(TextRecognitionError) as refusal,
    ):
        _ = ImageTextExtractor(binary).extract_text(_SCAN_PATH, "png")

    assert str(refusal.value) == f"{_RECOGNIZER_MISSING} at {binary}"


@settings(max_examples=10, deadline=None)
@given(st.integers(min_value=1, max_value=9))
def test_extract_text_property_image_reports_whatever_tesseract_complained(
    return_code: int,
) -> None:
    failed = _recognition(return_code, b"", b"it went wrong")

    with (
        mock.patch(_SUBPROCESS_RUN, return_value=failed),
        pytest.raises(TextRecognitionError, match="it went wrong"),
    ):
        _ = ImageTextExtractor(_DEFAULT_RECOGNIZER).extract_text(
            _SCAN_PATH, "png"
        )
