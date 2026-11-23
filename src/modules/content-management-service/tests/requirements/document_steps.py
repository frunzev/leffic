from email.message import EmailMessage
from pathlib import Path

from pytest_bdd import given, parsers

from tests.requirements.file_steps import (
    HomeUploader,
    file_extension,
    stored_file_id,
)
from tests.requirements.requirement_lookup import Sessions

_WEB_PAGE = "<html><body><p>{page_text}</p></body></html>"
_EMAIL_SENDER = "teacher@example.com"
_EMAIL_SUBJECT = "Biology"
_HTML_BODY = "<p>{body_text}</p>"
_HTML_SUBTYPE = "html"
_ATTACHMENT = b"not a text body"
_ATTACHMENT_TYPE = "application"
_ATTACHMENT_SUBTYPE = "octet-stream"
_ATTACHMENT_NAME = "data.bin"


def _email() -> EmailMessage:
    message = EmailMessage()
    message["From"] = _EMAIL_SENDER
    message["Subject"] = _EMAIL_SUBJECT

    return message


@given(
    parsers.parse(
        'I upload the text file "{file_name}" saying "{page_text}" into home'
    )
)
def upload_text_file(
    home_uploader: HomeUploader, file_name: str, page_text: str
) -> None:
    home_uploader.upload([(file_name, page_text.encode())])


@given(
    parsers.parse(
        (
            'I upload the web page file "{file_name}" saying "{page_text}" '
            "into home"
        )
    )
)
def upload_web_page_file(
    home_uploader: HomeUploader, file_name: str, page_text: str
) -> None:
    web_page = _WEB_PAGE.format(page_text=page_text)
    home_uploader.upload([(file_name, web_page.encode())])


@given(
    parsers.parse(
        (
            'I upload the email "{file_name}" with the plain body "{body_text}" '
            "into home"
        )
    )
)
def upload_plain_email(
    home_uploader: HomeUploader, file_name: str, body_text: str
) -> None:
    message = _email()
    message.set_content(body_text)
    home_uploader.upload([(file_name, message.as_bytes())])


@given(
    parsers.parse(
        (
            'I upload the email "{file_name}" with only the HTML body '
            '"{body_text}" into home'
        )
    )
)
def upload_html_email(
    home_uploader: HomeUploader, file_name: str, body_text: str
) -> None:
    message = _email()
    html_body = _HTML_BODY.format(body_text=body_text)
    message.set_content(html_body, subtype=_HTML_SUBTYPE)
    home_uploader.upload([(file_name, message.as_bytes())])


@given(
    parsers.parse(
        'I upload the email "{file_name}" with only an attachment into home'
    )
)
def upload_attachment_email(
    home_uploader: HomeUploader, file_name: str
) -> None:
    message = _email()
    message.add_attachment(
        _ATTACHMENT,
        maintype=_ATTACHMENT_TYPE,
        subtype=_ATTACHMENT_SUBTYPE,
        filename=_ATTACHMENT_NAME,
    )
    home_uploader.upload([(file_name, message.as_bytes())])


@given(parsers.parse('"{file_name}" is gone from storage'))
def remove_from_storage(
    sessions: Sessions, stored_files_directory: Path, file_name: str
) -> None:
    file_id = stored_file_id(sessions, file_name)
    stored_name = f"{file_id}.{file_extension(file_name)}"
    (stored_files_directory / stored_name).unlink()
