import io
from typing import Annotated

from fastapi import Depends, HTTPException, status
from pypdf import PdfReader
from pypdf.errors import PdfReadError

from shared.dependencies import StoredFileContents
from shared.file_storage import FileContents, storage_name
from shared.libreoffice_exporter import provide_pdf_conversion
from shared.models import File
from shared.pdf_conversion import ConversionError, PdfConversion

_PDF_EXTENSION = "pdf"
_FILE_NOT_FOUND = "File not found"
_UNREADABLE_PDF = "The PDF cannot be read"
_CONVERSION_FAILED = "Conversion failed: {reason}"

InjectedPdfConversion = Annotated[
    PdfConversion, Depends(provide_pdf_conversion)
]


class StoredPdfPages:
    def __init__(
        self, file_contents: FileContents, pdf_conversion: PdfConversion
    ) -> None:
        self._file_contents: FileContents = file_contents
        self._pdf_conversion: PdfConversion = pdf_conversion

    def page_count_of(self, file: File) -> int:
        pdf_document = self._pdf_document(file)

        try:
            reader = PdfReader(io.BytesIO(pdf_document))
            page_count = len(reader.pages)
        except PdfReadError as unreadable:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=_UNREADABLE_PDF,
            ) from unreadable

        return page_count

    def _pdf_document(self, file: File) -> bytes:
        stored_name = storage_name(str(file.id), file.extension)

        try:
            stored_document = self._file_contents.contents_of(stored_name)
        except FileNotFoundError as missing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=_FILE_NOT_FOUND,
            ) from missing

        if file.extension == _PDF_EXTENSION:
            return stored_document

        try:
            return self._pdf_conversion.converted(
                stored_document, file.extension
            )
        except ConversionError as failure:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=_CONVERSION_FAILED.format(reason=failure),
            ) from failure


def provide_stored_pdf_pages(
    file_contents: StoredFileContents, pdf_conversion: InjectedPdfConversion
) -> StoredPdfPages:
    return StoredPdfPages(file_contents, pdf_conversion)
