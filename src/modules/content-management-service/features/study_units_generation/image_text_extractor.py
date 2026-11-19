import os
import subprocess
from typing import override

from features.study_units_generation.text_extractor import TextExtractor

TEXT_RECOGNIZER_BINARY = os.getenv("TEXT_RECOGNIZER_BINARY", "tesseract")

_STANDARD_OUTPUT = "stdout"
_RECOGNITION_TIMEOUT_SECONDS = 120
_RECOGNIZER_MISSING = "Text recognition is not available at {binary}"


class TextRecognitionError(Exception):
    pass


class ImageTextExtractor(TextExtractor):
    @override
    def extract_text(self, filename: str, extension: str) -> str:
        command = [TEXT_RECOGNIZER_BINARY, filename, _STANDARD_OUTPUT]

        try:
            completed_recognition = subprocess.run(
                command,
                capture_output=True,
                check=False,
                timeout=_RECOGNITION_TIMEOUT_SECONDS,
            )
        except FileNotFoundError as missing:
            message = _RECOGNIZER_MISSING.format(binary=TEXT_RECOGNIZER_BINARY)
            raise TextRecognitionError(message) from missing

        if completed_recognition.returncode != 0:
            complaint = completed_recognition.stderr.decode()
            raise TextRecognitionError(complaint)

        recognized_text = completed_recognition.stdout.decode()

        return recognized_text.strip()
