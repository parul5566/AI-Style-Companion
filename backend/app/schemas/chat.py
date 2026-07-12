"""Chat schemas."""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class ChatMessageRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    conversation_id: Optional[int] = None
    context_type: str = "general"  # general, outfit, event, shopping


class ChatMessageResponse(BaseModel):
    id: Optional[int] = None
    conversation_id: int
    role: str
    content: str
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class ChatConversationResponse(BaseModel):
    id: int
    title: Optional[str] = None
    context_type: str
    messages: list[ChatMessageResponse] = []
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
