from httpx import Response
from pytest_bdd import parsers, then

from tests.requirements.requirement_lookup import told_message

_INVALID_REQUEST = 422


@then(parsers.parse('I am told "{message}"'))
@then(parsers.parse('they are told "{message}"'))
def check_told_message(reply: Response, message: str) -> None:
    assert told_message(reply) == message


@then("the request is refused as invalid")
def check_refused_as_invalid(reply: Response) -> None:
    assert reply.status_code == _INVALID_REQUEST
