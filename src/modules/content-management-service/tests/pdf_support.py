import io
import subprocess
from pathlib import Path

from pypdf import PageObject, PdfReader, PdfWriter
from pypdf.generic import ContentStream, DictionaryObject, NameObject

_PAGE_SIDE = 200
_EXPORTED_NAME = "exported.pdf"
_FONT_KEY = "/F1"
_TEXT_DRAWING = "BT /F1 12 Tf 10 100 Td ({page_text}) Tj ET"


class PdfDocuments:
    @staticmethod
    def blank(page_count: int) -> bytes:
        writer = PdfWriter()

        for _ in range(page_count):
            _ = writer.add_blank_page(width=_PAGE_SIDE, height=_PAGE_SIDE)

        return PdfDocuments._written(writer)

    @staticmethod
    def with_text(page_texts: list[str]) -> bytes:
        writer = PdfWriter()

        for page_text in page_texts:
            page = writer.add_blank_page(width=_PAGE_SIDE, height=_PAGE_SIDE)
            PdfDocuments._draw_text(writer, page, page_text)

        return PdfDocuments._written(writer)

    @staticmethod
    def page_count(document: bytes) -> int:
        return len(PdfReader(io.BytesIO(document)).pages)

    @staticmethod
    def _draw_text(
        writer: PdfWriter, page: PageObject, page_text: str
    ) -> None:
        helvetica = DictionaryObject(
            {
                NameObject("/Type"): NameObject("/Font"),
                NameObject("/Subtype"): NameObject("/Type1"),
                NameObject("/BaseFont"): NameObject("/Helvetica"),
            }
        )
        fonts = DictionaryObject({NameObject(_FONT_KEY): helvetica})
        page[NameObject("/Resources")] = DictionaryObject(
            {NameObject("/Font"): fonts}
        )

        drawing = ContentStream(None, writer)
        drawing.set_data(_TEXT_DRAWING.format(page_text=page_text).encode())
        page.replace_contents(drawing)

    @staticmethod
    def _written(writer: PdfWriter) -> bytes:
        written = io.BytesIO()
        _ = writer.write(written)

        return written.getvalue()


class LibreOfficeStub:
    def __init__(self, page_count: int) -> None:
        self.page_count: int = page_count
        self.converted_sources: list[str] = []

    def __call__(
        self, command: list[str], **_unused: object
    ) -> subprocess.CompletedProcess[bytes]:
        output_directory = Path(command[command.index("--outdir") + 1])
        source = Path(command[-1])
        self.converted_sources.append(source.name)
        written = output_directory / f"{source.stem}.pdf"
        _ = written.write_bytes(PdfDocuments.blank(self.page_count))

        return subprocess.CompletedProcess(
            args=command, returncode=0, stderr=b""
        )


class CopyingExporter:
    def export_pdf(self, source_path: Path, output_directory: str) -> Path:
        exported = Path(output_directory) / _EXPORTED_NAME
        _ = exported.write_bytes(source_path.read_bytes())

        return exported


class SilentExporter:
    def export_pdf(self, source_path: Path, output_directory: str) -> Path:
        return Path(output_directory) / f"{source_path.stem}.pdf"
