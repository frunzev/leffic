import re

_WORDS_PER_MINUTE = 200
_HALF_MINUTE_OF_WORDS = _WORDS_PER_MINUTE // 2
_SHORTEST_READING_MINUTES = 1
_HTML_TAG = re.compile(r"<[^>]*>")
_TAG_GAP = " "


def reading_minutes(note_html: str) -> int:
    plain_text = _HTML_TAG.sub(_TAG_GAP, note_html)
    word_count = len(plain_text.split())
    rounded_minutes = (word_count + _HALF_MINUTE_OF_WORDS) // _WORDS_PER_MINUTE

    return max(_SHORTEST_READING_MINUTES, rounded_minutes)
