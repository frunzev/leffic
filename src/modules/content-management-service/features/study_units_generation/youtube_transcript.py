from urllib.parse import parse_qs, urlparse

from youtube_transcript_api import (
    NoTranscriptFound,
    Transcript,
    TranscriptList,
    TranscriptsDisabled,
    YouTubeTranscriptApi,
)

_YOUTUBE_HOSTS = ("www.youtube.com", "youtube.com")
_SHORT_YOUTUBE_HOST = "youtu.be"
PREFERRED_TRANSCRIPT_LANGUAGES = ("en",)


def extract_video_id(url: str) -> str | None:
    parsed_url = urlparse(url)

    if parsed_url.hostname in _YOUTUBE_HOSTS:
        query = parse_qs(parsed_url.query)

        return query.get("v", [None])[0]

    if parsed_url.hostname == _SHORT_YOUTUBE_HOST:
        short_link_video_id = parsed_url.path.lstrip("/")

        return short_link_video_id or None

    return None


def _joined_transcript(transcript: Transcript) -> str:
    return " ".join(entry.text for entry in transcript.fetch())


def _preferred_transcript(
    transcript_list: TranscriptList, preferred_langs: tuple[str, ...]
) -> Transcript | None:
    for finder in (
        transcript_list.find_manually_created_transcript,
        transcript_list.find_generated_transcript,
    ):
        for language in preferred_langs:
            try:
                return finder([language])
            except NoTranscriptFound:
                continue

    return None


def _any_transcript(transcript_list: TranscriptList) -> Transcript | None:
    for transcript in transcript_list:
        if not transcript.is_generated:
            return transcript

    return next(iter(transcript_list), None)


def transcript_of_video(
    video_id: str, preferred_langs: tuple[str, ...]
) -> str | None:
    try:
        transcript_list = YouTubeTranscriptApi().list(video_id)
    except (TranscriptsDisabled, NoTranscriptFound):
        return None

    transcript = _preferred_transcript(
        transcript_list, preferred_langs
    ) or _any_transcript(transcript_list)

    if transcript is None:
        return None

    return _joined_transcript(transcript)
