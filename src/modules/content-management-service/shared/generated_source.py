from shared.models.mixins import GeneratedContent

SourceFields = dict[str, str]


def source_fields(row: GeneratedContent) -> SourceFields:
    if row.source_kind is None:
        return {}

    return {
        "source_kind": row.source_kind,
        "source_reference": row.source_reference or "",
    }
