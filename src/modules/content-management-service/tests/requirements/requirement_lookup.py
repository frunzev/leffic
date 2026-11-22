import uuid
from typing import cast

from httpx import Response
from sqlalchemy import select
from sqlalchemy.orm import Session, sessionmaker

from shared.content_access import ContentUnit
from shared.folder_access import ensured_home_folder
from shared.models import Folder, TestItem
from tests.support import OTHER_USER_ID, USER_ID

ReplyBody = dict[str, object]
Sessions = sessionmaker[Session]

_QUESTION_FIELDS = ("question", "statement")


def home_folder_id(sessions: Sessions) -> str:
    with sessions() as session:
        home = ensured_home_folder(session, USER_ID)

        return str(home.id)


def stranger_home_folder_id(sessions: Sessions) -> str:
    with sessions() as session:
        home = ensured_home_folder(session, OTHER_USER_ID)

        return str(home.id)


def _owned_folder_id(
    sessions: Sessions, folder_name: str, owner_id: str
) -> uuid.UUID | None:
    query = select(Folder.id).where(
        Folder.name == folder_name, Folder.user_id == uuid.UUID(owner_id)
    )

    with sessions() as session:
        return session.execute(query).scalar_one_or_none()


def folder_id_named(sessions: Sessions, folder_name: str) -> str:
    folder_id = _owned_folder_id(sessions, folder_name, USER_ID)

    if folder_id is None:
        message = f"I have no folder named {folder_name!r}"
        raise LookupError(message)

    return str(folder_id)


def is_folder_named(
    sessions: Sessions, folder_name: str, owner_id: str
) -> bool:
    return _owned_folder_id(sessions, folder_name, owner_id) is not None


def unit_id_named[UnitT: ContentUnit](
    sessions: Sessions, model: type[UnitT], unit_name: str
) -> str:
    query = select(model.id).where(model.name == unit_name)

    with sessions() as session:
        unit_id = session.execute(query).scalar_one()

    return str(unit_id)


def is_unit_named[UnitT: ContentUnit](
    sessions: Sessions, model: type[UnitT], unit_name: str
) -> bool:
    query = select(model.id).where(model.name == unit_name)

    with sessions() as session:
        unit_id = session.execute(query).scalar_one_or_none()

    return unit_id is not None


def _asks(test_item: TestItem, question: str) -> bool:
    for question_field in _QUESTION_FIELDS:
        if test_item.content.get(question_field) == question:
            return True

    return False


def stored_question(sessions: Sessions, question: str) -> TestItem:
    with sessions() as session:
        for test_item in session.execute(select(TestItem)).scalars():
            if _asks(test_item, question):
                session.expunge(test_item)

                return test_item

    message = f"No stored question asks {question!r}"
    raise LookupError(message)


def reply_body(reply: Response) -> ReplyBody:
    return cast("ReplyBody", reply.json())


def told_message(reply: Response) -> object:
    body = reply_body(reply)

    if "detail" in body:
        return body["detail"]

    return body.get("msg")
