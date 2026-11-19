from fractions import Fraction

from hypothesis import given, settings
from hypothesis import strategies as st

from features.file_system.reading_time import reading_minutes

_WORDS_PER_MINUTE = 200
_HALF = Fraction(1, 2)
_WORDS = st.text(alphabet="abcdefghij", min_size=1, max_size=6)
_SEPARATORS = st.sampled_from(
    [" ", "\n", "\t ", "<br/>", "</p><p>", '<a href="x y">', "<b> </b>"]
)
_WORDED_HTML = st.lists(st.tuples(_WORDS, _SEPARATORS), max_size=900)


def _html_from(worded_html: list[tuple[str, str]]) -> str:
    html = "<p>"

    for word, separator in worded_html:
        html += word + separator

    return html + "</p>"


@settings(max_examples=50, deadline=None)
@given(_WORDED_HTML)
def test_reading_minutes_property_rounds_words_per_two_hundred_half_up(
    worded_html: list[tuple[str, str]],
) -> None:
    word_count = len(worded_html)
    rounded_minutes = int(Fraction(word_count, _WORDS_PER_MINUTE) + _HALF)

    assert reading_minutes(_html_from(worded_html)) == max(1, rounded_minutes)


@settings(max_examples=50, deadline=None)
@given(st.lists(st.sampled_from(["<p>", "</p>", "<br/>", " ", "\n"])))
def test_reading_minutes_property_gives_at_least_one_minute(
    wordless_parts: list[str],
) -> None:
    assert reading_minutes("".join(wordless_parts)) == 1
