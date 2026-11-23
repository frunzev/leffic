from features.study_units_generation.webpage_extractor import (
    extract_link_main_content,
)
from features.study_units_generation.youtube_transcript import (
    PREFERRED_TRANSCRIPT_LANGUAGES,
    extract_video_id,
    transcript_of_video,
)


class WebLinkText:
    def text_from_link(self, link: str) -> str:
        video_id = extract_video_id(link)

        if video_id is not None:
            transcript = transcript_of_video(
                video_id, PREFERRED_TRANSCRIPT_LANGUAGES
            )

            if transcript:
                return transcript

        return extract_link_main_content(link) or ""
