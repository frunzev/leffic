from collections.abc import Iterator

import pytest
from pytest_bdd import given, parsers
from youtube_transcript_api import NoTranscriptFound, TranscriptsDisabled

from features.study_units_generation import youtube_transcript


class ForeignTranscriptLine:
    def __init__(self, text: str) -> None:
        self.text: str = text


class ForeignTranscript:
    def __init__(self, transcript_text: str, *, is_generated: bool) -> None:
        self.is_generated: bool = is_generated
        self._transcript_text: str = transcript_text

    def fetch(self) -> list[ForeignTranscriptLine]:
        return [ForeignTranscriptLine(self._transcript_text)]


class ForeignTranscriptList:
    def __init__(
        self, video_id: str, transcripts: list[ForeignTranscript]
    ) -> None:
        self._video_id: str = video_id
        self._transcripts: list[ForeignTranscript] = transcripts

    def _missing(self, language_codes: list[str]) -> NoTranscriptFound:
        return NoTranscriptFound(self._video_id, language_codes, self)

    def find_manually_created_transcript(
        self, language_codes: list[str]
    ) -> ForeignTranscript:
        raise self._missing(language_codes)

    def find_generated_transcript(
        self, language_codes: list[str]
    ) -> ForeignTranscript:
        raise self._missing(language_codes)

    def __iter__(self) -> Iterator[ForeignTranscript]:
        return iter(self._transcripts)


class ForeignTranscriptApi:
    def __init__(self, transcript_list: ForeignTranscriptList | None) -> None:
        self._transcript_list: ForeignTranscriptList | None = transcript_list

    def __call__(self) -> "ForeignTranscriptApi":
        return self

    def list(self, video_id: str) -> ForeignTranscriptList:
        if self._transcript_list is None:
            raise TranscriptsDisabled(video_id)

        return self._transcript_list


def _serve_transcripts(
    monkeypatch: pytest.MonkeyPatch, api: ForeignTranscriptApi
) -> None:
    monkeypatch.setattr(youtube_transcript, "YouTubeTranscriptApi", api)


def _serve_foreign_transcript(
    monkeypatch: pytest.MonkeyPatch,
    video_id: str,
    transcript: ForeignTranscript,
) -> None:
    transcript_list = ForeignTranscriptList(video_id, [transcript])
    _serve_transcripts(monkeypatch, ForeignTranscriptApi(transcript_list))


@given(
    parsers.parse(
        (
            'the YouTube video "{video_id}" has only the German transcript '
            '"{transcript_text}"'
        )
    )
)
def serve_german_transcript(
    monkeypatch: pytest.MonkeyPatch, video_id: str, transcript_text: str
) -> None:
    transcript = ForeignTranscript(transcript_text, is_generated=False)
    _serve_foreign_transcript(monkeypatch, video_id, transcript)


@given(
    parsers.parse(
        (
            'the YouTube video "{video_id}" has only the automatic German '
            'transcript "{transcript_text}"'
        )
    )
)
def serve_automatic_german_transcript(
    monkeypatch: pytest.MonkeyPatch, video_id: str, transcript_text: str
) -> None:
    transcript = ForeignTranscript(transcript_text, is_generated=True)
    _serve_foreign_transcript(monkeypatch, video_id, transcript)


@given(
    parsers.parse('the YouTube video "{video_id}" has transcripts turned off')
)
def turn_off_transcripts(monkeypatch: pytest.MonkeyPatch) -> None:
    _serve_transcripts(monkeypatch, ForeignTranscriptApi(None))


@given(parsers.parse('the YouTube video "{video_id}" has no transcripts'))
def serve_no_transcripts(
    monkeypatch: pytest.MonkeyPatch, video_id: str
) -> None:
    empty_list = ForeignTranscriptList(video_id, [])
    _serve_transcripts(monkeypatch, ForeignTranscriptApi(empty_list))
