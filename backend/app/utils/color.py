"""Color harmony utilities for outfit recommendations."""
from typing import Optional

# Common color name → rough hue family
COLOR_FAMILIES = {
    "black": "neutral", "white": "neutral", "gray": "neutral", "grey": "neutral",
    "navy": "blue", "blue": "blue", "light blue": "blue", "royal blue": "blue",
    "red": "warm", "maroon": "warm", "burgundy": "warm", "orange": "warm",
    "yellow": "warm", "gold": "warm", "brown": "neutral", "beige": "neutral",
    "tan": "neutral", "cream": "neutral", "ivory": "neutral",
    "green": "cool", "olive": "neutral", "teal": "cool",
    "purple": "cool", "violet": "cool", "pink": "warm", "magenta": "warm",
    "charcoal": "neutral", "khaki": "neutral",
}

# Classic pairs that always look good together
HARMONIOUS_PAIRS = {
    ("neutral", "neutral"), ("neutral", "blue"), ("neutral", "warm"),
    ("neutral", "cool"), ("blue", "warm"), ("cool", "neutral"),
}


def color_family(color_name: str) -> str:
    """Map a color name to its hue family."""
    if not color_name:
        return "neutral"
    key = color_name.lower().strip()
    return COLOR_FAMILIES.get(key, "neutral")


def colors_harmonize(color_a: Optional[str], color_b: Optional[str]) -> bool:
    """Check if two colors harmonize based on their families."""
    fa = color_family(color_a or "")
    fb = color_family(color_b or "")
    if fa == fb:
        return True
    pair = tuple(sorted([fa, fb]))
    return pair in HARMONIOUS_PAIRS


def outfit_color_score(colors: list[str]) -> float:
    """Return 0–1 score for how harmonious a set of colors is."""
    if len(colors) <= 1:
        return 1.0
    score = 0.0
    total = 0
    for i in range(len(colors)):
        for j in range(i + 1, len(colors)):
            total += 1
            if colors_harmonize(colors[i], colors[j]):
                score += 1.0
    return score / total if total > 0 else 1.0
