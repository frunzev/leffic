from typing import Annotated

from claude_agent_sdk import query
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from features.chatbot.chat_engine import ChatEngine, ChatEngineUnavailableError
from features.chatbot.claude_code_chat_engine import ClaudeCodeChatEngine
from features.chatbot.openai_chat_engine import OpenAIChatEngine
from shared.ai_budget import provide_ai_budget
from shared.ai_budget_guard import ensure_ai_budget
from shared.ai_manager import ai_factory
from shared.chosen_ai_engine import CHOSEN_AI_ENGINE, CLAUDE_CODE_ENGINE
from shared.database import SessionLocal
from shared.dependencies import AuthenticatedUserId

chatbot = APIRouter()


class ChatbotRequest(BaseModel):
    conversation: list[dict[str, str]]


def provide_chat_engine() -> ChatEngine:
    if CHOSEN_AI_ENGINE == CLAUDE_CODE_ENGINE:
        return ClaudeCodeChatEngine(SessionLocal, query)

    return OpenAIChatEngine(ai_factory, provide_ai_budget())


SelectedChatEngine = Annotated[ChatEngine, Depends(provide_chat_engine)]


@chatbot.post("/chat")
def chat(
    request_data: ChatbotRequest,
    user_id: AuthenticatedUserId,
    chat_engine: SelectedChatEngine,
) -> dict[str, str]:
    ensure_ai_budget(user_id, CHOSEN_AI_ENGINE)

    try:
        answer = chat_engine.answer(request_data.conversation, user_id)
    except ChatEngineUnavailableError as unavailable:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(unavailable),
        ) from unavailable

    return {"answer": answer}
