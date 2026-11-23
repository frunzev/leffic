from collections.abc import Iterator

import pytest
import requests
from pytest_bdd import given, parsers
from youtube_transcript_api import TranscriptsDisabled

from features.study_units_generation import youtube_transcript

_ARTICLE_REPEATS = 30
_ARTICLE_PAGE = "<html><body><article>{article}</article></body></html>"
_UNREACHABLE = "The web page cannot be reached"
_ARTICLE_STEP = 'the web page "{link}" has a long article saying "{sentence}"'
_BLOCK_PAGE = "<html><body><div>{block}</div></body></html>"
_SHORT_ARTICLE_PAGE = (
    "<html><body><article>Short.</article><div>{block}</div></body></html>"
)
_LINE_PAGE = "<html><body><p>{line}</p></body></html>"


class FakeWebPage:
    def __init__(self, page_text: str) -> None:
        self.text: str = page_text

    def raise_for_status(self) -> None:
        return None


class FakeWeb:
    def __init__(self, pages: dict[str, str]) -> None:
        self._pages: dict[str, str] = pages

    def __call__(self, link: str, **_request_options: object) -> FakeWebPage:
        if link not in self._pages:
            raise requests.ConnectionError(_UNREACHABLE)

        return FakeWebPage(self._pages[link])


class FakeTranscriptLine:
    def __init__(self, text: str) -> None:
        self.text: str = text


class FakeTranscript:
    def __init__(self, transcript_text: str) -> None:
        self.is_generated: bool = False
        self._transcript_text: str = transcript_text

    def fetch(self) -> list[FakeTranscriptLine]:
        return [FakeTranscriptLine(self._transcript_text)]


class FakeTranscriptList:
    def __init__(self, transcript: FakeTranscript) -> None:
        self._transcript: FakeTranscript = transcript

    def find_manually_created_transcript(
        self, _language_codes: list[str]
    ) -> FakeTranscript:
        return self._transcript

    def find_generated_transcript(
        self, _language_codes: list[str]
    ) -> FakeTranscript:
        return self._transcript

    def __iter__(self) -> Iterator[FakeTranscript]:
        return iter([self._transcript])


class FakeTranscriptApi:
    def __init__(self, transcripts: dict[str, str]) -> None:
        self._transcripts: dict[str, str] = transcripts

    def __call__(self) -> "FakeTranscriptApi":
        return self

    def list(self, video_id: str) -> FakeTranscriptList:
        if video_id not in self._transcripts:
            raise TranscriptsDisabled(video_id)

        return FakeTranscriptList(FakeTranscript(self._transcripts[video_id]))


def _serve_web(monkeypatch: pytest.MonkeyPatch, pages: dict[str, str]) -> None:
    monkeypatch.setattr(requests, "get", FakeWeb(pages))


@given(parsers.parse(_ARTICLE_STEP))
def serve_article(
    monkeypatch: pytest.MonkeyPatch, link: str, sentence: str
) -> None:
    article = _long_text(sentence)
    _serve_web(monkeypatch, {link: _ARTICLE_PAGE.format(article=article)})


@given(parsers.parse('the web page "{link}" cannot be reached'))
def serve_nothing(monkeypatch: pytest.MonkeyPatch) -> None:
    _serve_web(monkeypatch, {})


@given(
    parsers.parse(
        'the YouTube video "{video_id}" has the transcript "{transcript}"'
    )
)
def serve_transcript(
    monkeypatch: pytest.MonkeyPatch, video_id: str, transcript: str
) -> None:
    _serve_web(monkeypatch, {})
    monkeypatch.setattr(
        youtube_transcript,
        "YouTubeTranscriptApi",
        FakeTranscriptApi({video_id: transcript}),
    )


def _long_text(sentence: str) -> str:
    return " ".join([sentence] * _ARTICLE_REPEATS)


@given(
    parsers.parse(
        (
            'the web page "{link}" has no article but a long block saying '
            '"{sentence}"'
        )
    )
)
def serve_block_page(
    monkeypatch: pytest.MonkeyPatch, link: str, sentence: str
) -> None:
    page = _BLOCK_PAGE.format(block=_long_text(sentence))
    _serve_web(monkeypatch, {link: page})


@given(
    parsers.parse(
        (
            'the web page "{link}" has a short article and a long block saying '
            '"{sentence}"'
        )
    )
)
def serve_short_article_page(
    monkeypatch: pytest.MonkeyPatch, link: str, sentence: str
) -> None:
    page = _SHORT_ARTICLE_PAGE.format(block=_long_text(sentence))
    _serve_web(monkeypatch, {link: page})


@given(parsers.parse('the web page "{link}" has only the line "{line}"'))
def serve_line_page(
    monkeypatch: pytest.MonkeyPatch, link: str, line: str
) -> None:
    _serve_web(monkeypatch, {link: _LINE_PAGE.format(line=line)})


@given(
    parsers.parse('the web page "{link}" has only the short block "{block}"')
)
def serve_short_block_page(
    monkeypatch: pytest.MonkeyPatch, link: str, block: str
) -> None:
    _serve_web(monkeypatch, {link: _BLOCK_PAGE.format(block=block)})
