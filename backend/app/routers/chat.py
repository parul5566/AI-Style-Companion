"""Chat routes: fashion assistant conversation."""
import json
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models.user import User, UserProfile
from app.models.wardrobe import WardrobeItem
from app.models.chat import ChatConversation, ChatMessage
from app.schemas.chat import ChatMessageRequest, ChatMessageResponse, ChatConversationResponse
from app.services import ai_service, weather_service

router = APIRouter(prefix="/chat", tags=["chat"])


def _wardrobe_context(items: list[WardrobeItem]) -> str:
    if not items:
        return ""
    lines = [f"- {i.name} ({i.category}, {i.color_primary or 'unknown'} color, {i.formality_level or 'unknown'} formality)" for i in items[:30]]
    return "\n".join(lines)


def _profile_context(profile: UserProfile | None) -> str:
    if not profile:
        return ""
    parts = []
    if profile.style_preferences:
        parts.append(f"Style: {', '.join(profile.style_preferences)}")
    if profile.preferred_colors:
        parts.append(f"Preferred colors: {', '.join(profile.preferred_colors)}")
    if profile.favorite_occasions:
        parts.append(f"Favorite occasions: {', '.join(profile.favorite_occasions)}")
    return "; ".join(parts)


@router.post("/message", response_model=ChatMessageResponse)
async def send_message(
    payload: ChatMessageRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Send a message to the AI fashion assistant and get a response."""
    # Get or create conversation
    conv: ChatConversation
    if payload.conversation_id:
        result = await db.execute(
            select(ChatConversation).where(
                ChatConversation.id == payload.conversation_id,
                ChatConversation.user_id == user.id,
            )
        )
        conv = result.scalar_one_or_none()
        if not conv:
            raise HTTPException(404, "Conversation not found")
    else:
        conv = ChatConversation(
            user_id=user.id,
            title=payload.message[:80],
            context_type=payload.context_type,
        )
        db.add(conv)
        await db.flush()

    # Save user message
    user_msg = ChatMessage(
        conversation_id=conv.id,
        role="user",
        content=payload.message,
    )
    db.add(user_msg)
    await db.flush()

    # Load context
    wardrobe_result = await db.execute(
        select(WardrobeItem).where(WardrobeItem.user_id == user.id).limit(30)
    )
    wardrobe_items = list(wardrobe_result.scalars().all())

    profile_result = await db.execute(select(UserProfile).where(UserProfile.user_id == user.id))
    profile = profile_result.scalar_one_or_none()

    # Load history
    history_result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.conversation_id == conv.id)
        .order_by(ChatMessage.created_at.desc())
        .limit(20)
    )
    history = list(reversed(history_result.scalars().all()))
    history_dicts = [{"role": h.role, "content": h.content} for h in history[:-1]]  # exclude current

    # Get AI response
    try:
        ai_text = await ai_service.chat_response(
            message=payload.message,
            wardrobe_context=_wardrobe_context(wardrobe_items),
            profile_context=_profile_context(profile),
            weather_context="",
            history=history_dicts,
        )
    except Exception:
        ai_text = "I'm having trouble right now. Please try again."

    # Save AI message
    ai_msg = ChatMessage(
        conversation_id=conv.id,
        role="assistant",
        content=ai_text,
    )
    db.add(ai_msg)
    await db.flush()

    return ChatMessageResponse(
        id=ai_msg.id,
        conversation_id=conv.id,
        role="assistant",
        content=ai_text,
        created_at=ai_msg.created_at,
    )


@router.get("/conversations", response_model=list[ChatConversationResponse])
async def list_conversations(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(ChatConversation)
        .where(ChatConversation.user_id == user.id)
        .order_by(ChatConversation.updated_at.desc())
        .limit(20)
    )
    convs = list(result.scalars().all())
    responses = []
    for c in convs:
        msgs_result = await db.execute(
            select(ChatMessage)
            .where(ChatMessage.conversation_id == c.id)
            .order_by(ChatMessage.created_at)
        )
        messages = [
            ChatMessageResponse.model_validate(m)
            for m in msgs_result.scalars().all()
        ]
        responses.append(ChatConversationResponse(
            id=c.id,
            title=c.title,
            context_type=c.context_type,
            messages=messages,
            created_at=c.created_at,
        ))
    return responses


@router.get("/conversations/{conv_id}", response_model=ChatMessageResponse)
async def get_conversation(conv_id: int, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(ChatConversation).where(ChatConversation.id == conv_id, ChatConversation.user_id == user.id)
    )
    conv = result.scalar_one_or_none()
    if not conv:
        raise HTTPException(404, "Conversation not found")
    msgs_result = await db.execute(
        select(ChatMessage).where(ChatMessage.conversation_id == conv.id).order_by(ChatMessage.created_at)
    )
    messages = list(msgs_result.scalars().all())
    return ChatConversationResponse(
        id=conv.id, title=conv.title, context_type=conv.context_type, messages=messages, created_at=conv.created_at
    )
