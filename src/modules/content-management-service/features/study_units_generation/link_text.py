from features.study_units_generation.webpage_extractor import (
    extract_link_main_content,
)
from features.study_units_generation.youtube_transcript import (
    extract_video_id,
    get_youtube_transcript_auto,
)


class WebLinkText:
    def text_from_link(self, link: str) -> str:
        if extract_video_id(link) is not None:
            transcript = get_youtube_transcript_auto(link)

            if transcript:
                return transcript

        return extract_link_main_content(link) or ""
