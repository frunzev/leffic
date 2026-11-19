import asyncio
import uuid
from typing import cast, override

from fastapi import HTTPException
from hypothesis import given, settings
from hypothesis import strategies as st

from features.chatbot.study_toolset import (
    STUDY_TOOL_NAMES,
    StudyToolset,
    _refused_result,
    _text_result,
)

_TEXT = st.text(min_size=1, max_size=40)
_MISSING = 404


class RecordingLibrary:
    def __init__(self, outline: str, note: str) -> None:
        self.outline: str = outline
        self.note: str = note
        self.appended: list[tuple[str, str, str]] = []

    def folder_outline(self) -> str:
        return self.outline

    def note_content(self, note_id: str) -> str:
        _ = note_id

        return self.note

    def append_flashcard(self, deck_id: str, front: str, back: str) -> None:
        self.appended.append((deck_id, front, back))


class RefusingLibrary(RecordingLibrary):
    @override
    def note_content(self, note_id: str) -> str:
        raise HTTPException(status_code=_MISSING, detail=note_id)

    @override
    def append_flashcard(self, deck_id: str, front: str, back: str) -> None:
        raise HTTPException(status_code=_MISSING, detail=deck_id)


def _texts(tool_result: dict[str, object]) -> list[str]:
    blocks = cast("list[dict[str, str]]", tool_result["content"])
    texts: list[str] = []

    for block in blocks:
        texts.append(block["text"])

    return texts


@settings(max_examples=25)
@given(_TEXT)
def test_list_folders_property_returns_the_library_outline(
    outline: str,
) -> None:
    toolset = StudyToolset(RecordingLibrary(outline, ""))

    tool_result = asyncio.run(toolset.list_folders({}))

    assert _texts(tool_result) == [outline]


@settings(max_examples=25)
@given(_TEXT)
def test_read_note_property_returns_the_note_text(note: str) -> None:
    toolset = StudyToolset(RecordingLibrary("", note))

    tool_result = asyncio.run(
        toolset.read_note({"note_id": str(uuid.uuid4())})
    )

    assert _texts(tool_result) == [note]
    assert tool_result.get("is_error") is not True


@settings(max_examples=25)
@given(st.uuids())
def test_read_note_property_reports_a_refused_note_as_a_tool_error(
    note_id: uuid.UUID,
) -> None:
    toolset = StudyToolset(RefusingLibrary("", ""))

    tool_result = asyncio.run(toolset.read_note({"note_id": str(note_id)}))

    assert tool_result["is_error"] is True


@settings(max_examples=25)
@given(st.uuids(), _TEXT, _TEXT)
def test_add_flashcard_property_hands_the_card_to_the_library(
    deck_id: uuid.UUID, front: str, back: str
) -> None:
    library = RecordingLibrary("", "")
    toolset = StudyToolset(library)

    tool_result = asyncio.run(
        toolset.add_flashcard(
            {"deck_id": str(deck_id), "front": front, "back": back}
        )
    )

    assert library.appended == [(str(deck_id), front, back)]
    assert tool_result.get("is_error") is not True


@settings(max_examples=25)
@given(st.uuids(), _TEXT, _TEXT)
def test_add_flashcard_property_reports_a_refused_deck_as_a_tool_error(
    deck_id: uuid.UUID, front: str, back: str
) -> None:
    toolset = StudyToolset(RefusingLibrary("", ""))

    tool_result = asyncio.run(
        toolset.add_flashcard(
            {"deck_id": str(deck_id), "front": front, "back": back}
        )
    )

    assert tool_result["is_error"] is True


@settings(max_examples=5)
@given(_TEXT)
def test_server_property_offers_exactly_the_study_tools(outline: str) -> None:
    server = StudyToolset(RecordingLibrary(outline, "")).server()

    assert server["type"] == "sdk"
    assert len(STUDY_TOOL_NAMES) == len(set(STUDY_TOOL_NAMES))
    assert all(name.startswith("mcp__leffic__") for name in STUDY_TOOL_NAMES)


@settings(max_examples=50)
@given(_TEXT)
def test__text_result_property_carries_exactly_the_text(text: str) -> None:
    tool_result = _text_result(text)

    assert _texts(tool_result) == [text]
    assert "is_error" not in tool_result


@settings(max_examples=50)
@given(_TEXT)
def test__refused_result_property_marks_the_refusal_as_an_error(
    detail: str,
) -> None:
    tool_result = _refused_result(
        HTTPException(status_code=_MISSING, detail=detail)
    )

    assert _texts(tool_result) == [detail]
    assert tool_result["is_error"] is True
