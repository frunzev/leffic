from typing import Annotated, Protocol

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from features.file_system.pdf_page_count import provide_stored_pdf_pages
from shared.dependencies import AuthenticatedUserId, DatabaseSession
from shared.file_access import owned_file
from shared.folder_access import MISSING_FOLDER, owned_folder
from shared.models import File

bookmark_router = APIRouter()


class BookmarkRequest(BaseModel):
    file_id: str
    page: int = Field(ge=1)


class PageCounter(Protocol):
    def page_count_of(self, file: File) -> int: ...


StoredPageCount = Annotated[PageCounter, Depends(provide_stored_pdf_pages)]


@bookmark_router.get("/file-bookmark")
async def get_file_bookmark(
    file_id: str,
    user_id: AuthenticatedUserId,
    db: DatabaseSession,
    page_counter: StoredPageCount,
) -> dict[str, int | str | None]:
    file = owned_file(db, user_id, file_id)
    folder = owned_folder(db, user_id, str(file.folder_id), MISSING_FOLDER)

    return {
        "page": file.bookmarked_page,
        "page_count": page_counter.page_count_of(file),
        "folder_id": str(folder.id),
        "folder_name": folder.name,
    }


@bookmark_router.put("/file-bookmark")
async def set_file_bookmark(
    request_data: BookmarkRequest,
    user_id: AuthenticatedUserId,
    db: DatabaseSession,
) -> dict[str, int | None]:
    file = owned_file(db, user_id, request_data.file_id)
    file.bookmarked_page = request_data.page
    db.commit()

    return {"page": file.bookmarked_page}


@bookmark_router.delete("/file-bookmark")
async def remove_file_bookmark(
    file_id: str, user_id: AuthenticatedUserId, db: DatabaseSession
) -> dict[str, int | None]:
    file = owned_file(db, user_id, file_id)
    file.bookmarked_page = None
    db.commit()

    return {"page": file.bookmarked_page}
