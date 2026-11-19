import os
import subprocess
from pathlib import Path

from shared.pdf_conversion import ConversionError, PdfConversion

LIBREOFFICE_BINARY = os.getenv("LIBREOFFICE_BINARY", "libreoffice")

_PDF_EXTENSION = "pdf"
_CONVERSION_TIMEOUT_SECONDS = 120
_LIBREOFFICE_MISSING = "LibreOffice is not installed at {binary}"


class LibreOfficeExporter:
    def export_pdf(self, source_path: Path, output_directory: str) -> Path:
        command = self._command(source_path, output_directory)

        try:
            completed_conversion = subprocess.run(
                command,
                capture_output=True,
                check=False,
                timeout=_CONVERSION_TIMEOUT_SECONDS,
            )
        except FileNotFoundError as missing:
            message = _LIBREOFFICE_MISSING.format(binary=command[0])
            raise ConversionError(message) from missing

        if completed_conversion.returncode != 0:
            raise ConversionError(completed_conversion.stderr.decode())

        exported_name = f"{source_path.stem}.{_PDF_EXTENSION}"

        return Path(output_directory) / exported_name

    @staticmethod
    def _command(source_path: Path, output_directory: str) -> list[str]:
        return [
            LIBREOFFICE_BINARY,
            "--headless",
            "--convert-to",
            _PDF_EXTENSION,
            "--outdir",
            output_directory,
            str(source_path),
        ]


def provide_pdf_conversion() -> PdfConversion:
    return PdfConversion(LibreOfficeExporter())
