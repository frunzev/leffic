from unittest import mock

from hypothesis import given, settings
from hypothesis import strategies as st

from features.study_units_generation import link_text
from features.study_units_generation.link_text import WebLinkText

_LINK_TEXT = WebLinkText()
_VIDEO_IDS = st.from_regex(r"[A-Za-z0-9_-]{1,11}", fullmatch=True)
_YOUTUBE_LINK_FORMS = st.sampled_from(
    [
        "https://www.youtube.com/watch?v={video_id}",
        "https://youtube.com/watch?v={video_id}",
        "https://youtu.be/{video_id}",
    ]
)


@settings(max_examples=40)
@given(video_id=_VIDEO_IDS, link_form=_YOUTUBE_LINK_FORMS)
def test_text_from_link_property_reads_every_youtube_link_from_its_transcript(
    video_id: str, link_form: str
) -> None:
    link = link_form.format(video_id=video_id)

    with (
        mock.patch.object(
            link_text, "transcript_of_video", return_value="spoken"
        ),
        mock.patch.object(
            link_text, "extract_link_main_content", return_value="page"
        ),
    ):
        assert _LINK_TEXT.text_from_link(link) == "spoken"


def test_a_youtube_link_uses_the_transcript() -> None:
    link = "https://youtube.com/watch?v=x"

    with mock.patch.object(
        link_text, "transcript_of_video", return_value="spoken"
    ) as transcript:
        assert _LINK_TEXT.text_from_link(link) == "spoken"

    assert transcript.call_args.args[0] == "x"


def test_a_youtube_link_without_a_transcript_reads_the_page() -> None:
    link = "https://youtube.com/watch?v=x"

    with (
        mock.patch.object(
            link_text, "transcript_of_video", return_value=None
        ),
        mock.patch.object(
            link_text, "extract_link_main_content", return_value="page"
        ),
    ):
        assert _LINK_TEXT.text_from_link(link) == "page"


def test_a_plain_link_reads_the_page() -> None:
    link = "https://example.com/story"

    with mock.patch.object(
        link_text, "extract_link_main_content", return_value="article"
    ) as page:
        assert _LINK_TEXT.text_from_link(link) == "article"

    assert page.call_args.args[0] == link


def test_an_unreadable_link_yields_no_text() -> None:
    with mock.patch.object(
        link_text, "extract_link_main_content", return_value=None
    ):
        assert _LINK_TEXT.text_from_link("https://example.com") == ""
