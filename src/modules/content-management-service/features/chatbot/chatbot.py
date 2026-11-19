import os
from typing import Annotated

from claude_agent_sdk import query
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from features.chatbot.chat_engine import ChatEngine, ChatEngineUnavailableError
from features.chatbot.claude_code_chat_engine import ClaudeCodeChatEngine
from features.chatbot.openai_chat_engine import OpenAIChatEngine
from shared.ai_manager import ai_factory
from shared.database import SessionLocal
from shared.dependencies import AuthenticatedUserId

CHAT_ENGINE = os.getenv("CHAT_ENGINE", "openai")

_CLAUDE_CODE = "claude-code"

chatbot = APIRouter()


class ChatbotRequest(BaseModel):
    conversation: list[dict[str, str]]


def provide_chat_engine() -> ChatEngine:
    if CHAT_ENGINE == _CLAUDE_CODE:
        return ClaudeCodeChatEngine(SessionLocal, query)

    return OpenAIChatEngine(ai_factory)


SelectedChatEngine = Annotated[ChatEngine, Depends(provide_chat_engine)]


@chatbot.post("/chat")
def chat(
    request_data: ChatbotRequest,
    user_id: AuthenticatedUserId,
    chat_engine: SelectedChatEngine,
) -> dict[str, str]:
    try:
        answer = chat_engine.answer(request_data.conversation, user_id)
    except ChatEngineUnavailableError as unavailable:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(unavailable),
        ) from unavailable

    return {"answer": answer}
