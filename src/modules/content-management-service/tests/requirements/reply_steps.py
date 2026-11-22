from httpx import Response
from pytest_bdd import parsers, then

from tests.requirements.requirement_lookup import told_message


@then(parsers.parse('I am told "{message}"'))
@then(parsers.parse('they are told "{message}"'))
def check_told_message(reply: Response, message: str) -> None:
    assert told_message(reply) == message
