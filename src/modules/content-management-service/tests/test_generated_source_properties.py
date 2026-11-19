from hypothesis import given, settings
from hypothesis import strategies as st

from shared.generated_source import source_fields
from shared.models import FlashcardDeck, Note, Test

_SOURCE_KINDS = st.one_of(
    st.none(), st.sampled_from(["file", "link", "topic", "text"])
)
_REFERENCES = st.one_of(st.none(), st.text(max_size=8))
_GENERATED_MODELS = st.sampled_from([FlashcardDeck, Note, Test])


@settings(max_examples=25, deadline=None)
@given(_GENERATED_MODELS, _SOURCE_KINDS, _REFERENCES)
def test_source_fields_property_reports_a_reference_only_with_a_kind(
    model: type[FlashcardDeck | Note | Test],
    source_kind: str | None,
    reference: str | None,
) -> None:
    row = model(source_kind=source_kind, source_reference=reference)
    described = source_fields(row)

    if source_kind is None:
        assert described == {}
    else:
        assert described == {
            "source_kind": source_kind,
            "source_reference": reference or "",
        }
