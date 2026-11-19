from typing import TYPE_CHECKING, cast

from sqlalchemy import literal, select
from sqlalchemy.orm import Session, aliased

from shared.models import Folder

if TYPE_CHECKING:
    import uuid

    from sqlalchemy import ColumnElement

FolderCrumb = dict[str, str]

_CURRENT_FOLDER_DEPTH = 0
_ONE_LEVEL_UP = 1
_LINEAGE = "lineage"
_DEPTH_COLUMN = "depth"


def folder_ancestors(
    db: Session, folder_id: str, user_id: str
) -> list[FolderCrumb]:
    lineage = (
        select(
            Folder.id,
            Folder.name,
            Folder.parent_id,
            literal(_CURRENT_FOLDER_DEPTH).label(_DEPTH_COLUMN),
        )
        .where(Folder.id == folder_id, Folder.user_id == user_id)
        .cte(name=_LINEAGE, recursive=True)
    )
    parent = aliased(Folder)
    lineage = lineage.union_all(
        select(
            parent.id,
            parent.name,
            parent.parent_id,
            lineage.c[_DEPTH_COLUMN] + _ONE_LEVEL_UP,
        ).where(parent.id == lineage.c.parent_id, parent.user_id == user_id)
    )
    ancestor_id = cast("ColumnElement[uuid.UUID]", lineage.c.id)
    ancestor_name = cast("ColumnElement[str]", lineage.c.name)
    depth = cast("ColumnElement[int]", lineage.c[_DEPTH_COLUMN])
    statement = (
        select(ancestor_id, ancestor_name)
        .where(depth > _CURRENT_FOLDER_DEPTH)
        .order_by(depth.desc())
    )

    crumbs: list[FolderCrumb] = []

    for crumb_id, crumb_name in db.execute(statement).tuples():
        crumbs.append({"id": str(crumb_id), "name": crumb_name})

    return crumbs
