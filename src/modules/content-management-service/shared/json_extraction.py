from typing import cast

import demjson3

_OPENING_BRACE = "{"
_CLOSING_BRACE = "}"


def get_dict_from_text(text: str) -> dict[str, object]:
    text = text.replace("\n", "")
    start_index = text.find(_OPENING_BRACE)
    end_index = text.rfind(_CLOSING_BRACE)
    object_text = text[start_index : end_index + 1]

    return cast("dict[str, object]", demjson3.decode(object_text))
