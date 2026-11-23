import subprocess
from typing import override

from features.study_units_generation.text_extractor import TextExtractor

_STANDARD_OUTPUT = "stdout"
_RECOGNITION_TIMEOUT_SECONDS = 120
_RECOGNIZER_MISSING = "Text recognition is not available at {binary}"


class TextRecognitionError(Exception):
    pass


class ImageTextExtractor(TextExtractor):
    def __init__(self, recognizer_binary: str) -> None:
        self._recognizer_binary: str = recognizer_binary

    @override
    def extract_text(self, filename: str, extension: str) -> str:
        command = [self._recognizer_binary, filename, _STANDARD_OUTPUT]

        try:
            completed_recognition = subprocess.run(
                command,
                capture_output=True,
                check=False,
                timeout=_RECOGNITION_TIMEOUT_SECONDS,
            )
        except FileNotFoundError as missing:
            message = _RECOGNIZER_MISSING.format(
                binary=self._recognizer_binary
            )
            raise TextRecognitionError(message) from missing

        if completed_recognition.returncode != 0:
            complaint = completed_recognition.stderr.decode().strip()
            raise TextRecognitionError(complaint)

        recognized_text = completed_recognition.stdout.decode()

        return recognized_text.strip()
