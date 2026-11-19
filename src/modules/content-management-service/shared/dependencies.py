from typing import Annotated

from fastapi import Depends
from sqlalchemy.orm import Session

from shared.claims_extractor import get_user_id_from_jwt
from shared.database import get_db
from shared.file_storage import FileContents, FileSizes, FileStorage
from shared.local_disk_file_storage import (
    provide_file_contents,
    provide_file_sizes,
    provide_file_storage,
)

DatabaseSession = Annotated[Session, Depends(get_db)]
AuthenticatedUserId = Annotated[str, Depends(get_user_id_from_jwt)]
StoredFileStorage = Annotated[FileStorage, Depends(provide_file_storage)]
StoredFileSizes = Annotated[FileSizes, Depends(provide_file_sizes)]
StoredFileContents = Annotated[
    FileContents, Depends(provide_file_contents)
]
