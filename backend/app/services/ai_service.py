"""AI service — LLM orchestration for tagging, recommendations, chat, missing pieces."""
import json
import logging
from typing import Optional

import httpx
from openai import AsyncOpenAI

from app.config import settings
from app.models.user import User, UserProfile
from app.models.wardrobe import WardrobeItem

logger = logging.getLogger(__name__)

# Initialize OpenAI-compatible client
_client: Optional[AsyncOpenAI] = None


def get_client() -> AsyncOpenAI:
    global _client
    if _client is None:
        _client = AsyncOpenAI(
            api_key=settings.OPENAI_API_KEY,
            base_url=settings.OPENAI_BASE_URL,
        )
    return _client


async def _chat_completion(system_prompt: str, user_prompt: str, temperature: float = 0.7) -> str:
    """Call the LLM and return the raw text response."""
    client = get_client()
    try:
        resp = await client.chat.completions.create(
            model=settings.LLM_MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=temperature,
            max_tokens=1200,
        )
        return resp.choices[0].message.content or ""
    except Exception as e:
        logger.error("LLM call failed: %s", e)
        raise


async def _chat_completion_json(system_prompt: str, user_prompt: str, temperature: float = 0.3) -> dict:
    """Call the LLM and parse JSON from the response."""
    raw = await _chat_completion(system_prompt, user_prompt, temperature)
    # Strip markdown code fences if present
    text = raw.strip()
    if text.startswith("```"):
        lines = text.split("\n")
        lines = [l for l in lines if not l.startswith("```")]
        text = "\n".join(lines)
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # Try to extract JSON from text
        start = text.find("{")
        end = text.rfind("}")
        if start != -1 and end != -1:
            return json.loads(text[start : end + 1])
        raise ValueError(f"Could not parse JSON from LLM response: {text[:200]}")


# ─── Garment tagging ───────────────────────────────────────────

TAG_SYSTEM = """You are an AI fashion vision system. Analyze the described garment and return ONLY a JSON object with these fields:
{
  "name": "short descriptive name (e.g. 'Navy Blue Cotton Blazer')",
  "category": "one of: shirt, tshirt, jeans, trousers, jacket, blazer, coat, dress, skirt, shoes, sneakers, boots, watch, belt, hat, bag, accessory, other",
  "subcategory": "optional more specific type",
  "color_primary": "main color",
  "color_secondary": "secondary/accent color or null",
  "pattern": "solid, striped, plaid, floral, graphic, geometric, or null",
  "fabric": "cotton, polyester, wool, denim, silk, leather, linen, blend, or null",
  "brand": "brand name if identifiable, or null",
  "formality_level": "casual, smart_casual, business, formal, black_tie",
  "season": "spring, summer, autumn, winter, all_season",
  "description": "one sentence description"
}
Return ONLY the JSON, no other text."""


async def tag_garment_from_description(description: str) -> dict:
    """Tag a garment from a text description (fallback when no image vision available)."""
    return await _chat_completion_json(
        TAG_SYSTEM,
        f"Analyze this garment: {description}",
        temperature=0.2,
    )


async def tag_garment_from_image(image_base64: str) -> dict:
    """Tag a garment from a base64-encoded image using vision model."""
    client = get_client()
    try:
        resp = await client.chat.completions.create(
            model=settings.LLM_MODEL,
            messages=[
                {"role": "system", "content": TAG_SYSTEM},
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"},
                        },
                        {
                            "type": "text",
                            "text": "Analyze the garment in this image and return the JSON.",
                        },
                    ],
                },
            ],
            temperature=0.2,
            max_tokens=800,
        )
        raw = resp.choices[0].message.content or ""
        text = raw.strip()
        if text.startswith("```"):
            lines = text.split("\n")
            lines = [l for l in lines if not l.startswith("```")]
            text = "\n".join(lines)
        return json.loads(text)
    except Exception as e:
        logger.error("Vision tagging failed: %s", e)
        raise


# ─── Outfit recommendation ─────────────────────────────────────

RECOMMEND_SYSTEM = """You are an expert AI fashion stylist. Given a user's wardrobe inventory, the occasion, weather conditions, and style preferences, recommend a complete outfit.

Return ONLY a JSON object:
{
  "name": "outfit name",
  "items": [
    {"role": "top|bottom|outer|footwear|accessory", "item_id": <id from wardrobe>, "reason": "why this piece works"}
  ],
  "ai_reasoning": "2-3 sentence explanation of why this outfit works",
  "confidence_score": 0.0 to 1.0
}

Guidelines:
- Pick items that match the occasion and weather.
- Ensure colors harmonize (neutrals go with everything, avoid clashing).
- Use real item IDs from the provided wardrobe.
- If the wardrobe lacks an essential piece, set confidence lower and note it.
Return ONLY JSON."""


async def recommend_outfit(
    wardrobe_items: list[dict],
    occasion: str,
    weather: Optional[dict],
    profile: Optional[dict],
) -> dict:
    """Get AI outfit recommendation based on wardrobe + context."""
    wardrobe_str = json.dumps(wardrobe_items, indent=2) if wardrobe_items else "[]"
    weather_str = json.dumps(weather) if weather else "No weather data"
    profile_str = json.dumps(profile) if profile else "No profile data"

    return await _chat_completion_json(
        RECOMMEND_SYSTEM,
        f"Occasion: {occasion}\n\nWeather:\n{weather_str}\n\nStyle Preferences:\n{profile_str}\n\nWardrobe Items:\n{wardrobe_str}",
        temperature=0.6,
    )


# ─── Missing piece engine ──────────────────────────────────────

MISSING_PIECE_SYSTEM = """You are an AI wardrobe completeness analyzer. Given the user's wardrobe and an upcoming event type, determine what clothing items are missing for that occasion.

Return ONLY a JSON object:
{
  "event_type": "the event type",
  "have": ["list of categories the user already has that are relevant"],
  "missing": [
    {
      "category": "item category needed",
      "name": "specific item name",
      "reason": "why it's needed for this event",
      "priority": "high|medium|low",
      "suggested_price_range": "e.g. '$50-$150'"
    }
  ],
  "summary": "one sentence overview"
}
Return ONLY JSON."""


async def find_missing_pieces(
    wardrobe_items: list[dict],
    event_type: str,
    dress_code: Optional[str] = None,
    budget_max: Optional[int] = None,
) -> dict:
    wardrobe_str = json.dumps(wardrobe_items, indent=2) if wardrobe_items else "[]"
    context = f"Event type: {event_type}"
    if dress_code:
        context += f"\nDress code: {dress_code}"
    if budget_max:
        context += f"\nBudget: up to ${budget_max}"

    return await _chat_completion_json(
        MISSING_PIECE_SYSTEM,
        f"{context}\n\nWardrobe Items:\n{wardrobe_str}",
        temperature=0.4,
    )


# ─── Fashion assistant chat ────────────────────────────────────

CHAT_SYSTEM = """You are an AI personal fashion stylist assistant called "Style Companion". You help users with outfit advice, fashion tips, and style recommendations.

You have access to the user's wardrobe, style preferences, and weather data (if provided in the context).

Guidelines:
- Be friendly, concise, and stylish in tone.
- Give specific, actionable advice referencing their actual wardrobe items when possible.
- If asked about weather-appropriate outfits, consider the conditions.
- Keep responses under 200 words unless the user asks for detail.
- If you don't have enough information, ask clarifying questions."""


async def chat_response(
    message: str,
    wardrobe_context: str,
    profile_context: str,
    weather_context: str,
    history: list[dict],
) -> str:
    """Get a conversational response from the AI fashion assistant."""
    client = get_client()
    messages = [{"role": "system", "content": CHAT_SYSTEM}]

    if wardrobe_context:
        messages.append({"role": "system", "content": f"User's Wardrobe:\n{wardrobe_context}"})
    if profile_context:
        messages.append({"role": "system", "content": f"User's Style Profile:\n{profile_context}"})
    if weather_context:
        messages.append({"role": "system", "content": f"Current Weather:\n{weather_context}"})

    # Add conversation history (last 10 messages)
    for h in history[-10:]:
        messages.append({"role": h["role"], "content": h["content"]})

    messages.append({"role": "user", "content": message})

    try:
        resp = await client.chat.completions.create(
            model=settings.LLM_MODEL,
            messages=messages,
            temperature=0.7,
            max_tokens=500,
        )
        return resp.choices[0].message.content or "I'm sorry, I couldn't generate a response."
    except Exception as e:
        logger.error("Chat LLM call failed: %s", e)
        return "I'm having trouble connecting to my styling engine right now. Please try again in a moment."
