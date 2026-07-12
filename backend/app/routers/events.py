"""Event routes."""
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models.user import User
from app.models.event import Event
from pydantic import BaseModel, Field

router = APIRouter(prefix="/events", tags=["events"])


class EventCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    event_type: str = Field(min_length=1, max_length=50)
    event_date: str  # ISO datetime string
    location: Optional[str] = None
    dress_code: Optional[str] = None


class EventResponse(EventCreate):
    id: int
    user_id: int

    model_config = {"from_attributes": True}


@router.get("", response_model=list[EventResponse])
async def list_events(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Event).where(Event.user_id == user.id).order_by(Event.event_date.desc())
    )
    return list(result.scalars().all())


@router.post("", response_model=EventResponse, status_code=201)
async def create_event(
    payload: EventCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    event = Event(
        user_id=user.id,
        title=payload.title,
        event_type=payload.event_type,
        event_date=datetime.fromisoformat(payload.event_date),
        location=payload.location,
        dress_code=payload.dress_code,
    )
    db.add(event)
    await db.flush()
    return event


@router.delete("/{event_id}", status_code=204)
async def delete_event(
    event_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Event).where(Event.id == event_id, Event.user_id == user.id))
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(404, "Event not found")
    await db.delete(event)
    await db.flush()
    return None
