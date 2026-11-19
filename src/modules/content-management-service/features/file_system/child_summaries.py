import uuid
from datetime import datetime
from typing import NamedTuple, cast

from sqlalchemy import (
    ColumnElement,
    CompoundSelect,
    Select,
    func,
    select,
    union_all,
)
from sqlalchemy.orm import Session

from shared.models import File, FlashcardDeck, Folder, Note, Test
from shared.models.mixins import FolderContent

FolderIds = Select[tuple[uuid.UUID]]

_CONTENT_MODELS: tuple[type[FolderContent], ...] = (
    FlashcardDeck,
    Test,
    Note,
    File,
)
_FOLDER_COLUMN = "folder_id"
_CREATED_AT_COLUMN = "created_at"


class ChildSummary(NamedTuple):
    item_count: int
    newest_created_at: datetime


def child_summaries(
    db: Session, folder_id: str
) -> dict[uuid.UUID, ChildSummary]:
    subfolder_ids = select(Folder.id).where(Folder.parent_id == folder_id)
    children = _children_of(subfolder_ids).subquery()
    parent_id = cast("ColumnElement[uuid.UUID]", children.c[_FOLDER_COLUMN])
    created_at = cast(
        "ColumnElement[datetime]", children.c[_CREATED_AT_COLUMN]
    )
    statement = select(parent_id, func.count(), func.max(created_at)).group_by(
        parent_id
    )

    summaries: dict[uuid.UUID, ChildSummary] = {}

    for subfolder_id, item_count, newest in db.execute(statement).tuples():
        summaries[subfolder_id] = ChildSummary(
            item_count=item_count, newest_created_at=newest
        )

    return summaries


def _children_of(folder_ids: FolderIds) -> CompoundSelect:
    child_folders = select(
        Folder.parent_id.label(_FOLDER_COLUMN),
        Folder.created_at.label(_CREATED_AT_COLUMN),
    ).where(Folder.parent_id.in_(folder_ids))
    child_contents: list[Select[tuple[uuid.UUID, datetime]]] = []

    for model in _CONTENT_MODELS:
        child_contents.append(
            select(model.folder_id, model.created_at).where(
                model.folder_id.in_(folder_ids)
            )
        )

    return union_all(child_folders, *child_contents)
