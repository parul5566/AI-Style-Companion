"""Seed shopping_products with mock vendor data for prototype."""
import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select, delete
from app.database import engine
from app.database import async_session_factory as AsyncSessionLocal
from app.models.shopping import ShoppingProduct

MOCK_PRODUCTS = [
    # Tops
    {"name": "Classic White Oxford Shirt", "category": "Tops", "brand": "Brooks Brothers",
     "price": "89.00", "product_url": "#", "vendor": "Brooks Brothers",
     "image_url": "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=400",
     "tags": {"style": "classic", "formality": "business", "colors": ["white"]}},
    {"name": "Navy Silk Blend Blouse", "category": "Tops", "brand": "Theory",
     "price": "145.00", "product_url": "#", "vendor": "Theory",
     "image_url": "https://images.unsplash.com/photo-1551803091-e20673f15770?w=400",
     "tags": {"style": "smart_casual", "formality": "business", "colors": ["navy"]}},
    {"name": "Relaxed Linen Shirt", "category": "Tops", "brand": "J.Crew",
     "price": "69.50", "product_url": "#", "vendor": "J.Crew",
     "image_url": "https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=400",
     "tags": {"style": "casual", "formality": "casual", "colors": ["beige", "white"]}},

    # Bottoms
    {"name": "Tailored Charwool Trousers", "category": "Bottoms", "brand": "Hugo Boss",
     "price": "195.00", "product_url": "#", "vendor": "Hugo Boss",
     "image_url": "https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400",
     "tags": {"style": "classic", "formality": "business", "colors": ["gray", "charcoal"]}},
    {"name": "Premium Dark Wash Jeans", "category": "Bottoms", "brand": "Levi's",
     "price": "98.00", "product_url": "#", "vendor": "Levi's",
     "image_url": "https://images.unsplash.com/photo-1542272604-787c3835535d?w=400",
     "tags": {"style": "casual", "formality": "casual", "colors": ["blue", "navy"]}},
    {"name": "Pleated Midi Skirt", "category": "Bottoms", "brand": "Zara",
     "price": "49.90", "product_url": "#", "vendor": "Zara",
     "image_url": "https://images.unsplash.com/photo-1583496661160-fb5886a13d44?w=400",
     "tags": {"style": "feminine", "formality": "smart_casual", "colors": ["black", "burgundy"]}},

    # Outerwear
    {"name": "Double-Breasted Wool Coat", "category": "Outerwear", "brand": "Max Mara",
     "price": "1290.00", "product_url": "#", "vendor": "Max Mara",
     "image_url": "https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400",
     "tags": {"style": "luxury", "formality": "formal", "colors": ["camel", "black"]}},
    {"name": "Bomber Jacket", "category": "Outerwear", "brand": "Alpha Industries",
     "price": "150.00", "product_url": "#", "vendor": "Alpha Industries",
     "image_url": "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400",
     "tags": {"style": "streetwear", "formality": "casual", "colors": ["black", "olive"]}},
    {"name": "Navy Blazer", "category": "Outerwear", "brand": "Ralph Lauren",
     "price": "298.00", "product_url": "#", "vendor": "Ralph Lauren",
     "image_url": "https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=400",
     "tags": {"style": "classic", "formality": "business", "colors": ["navy"]}},

    # Dresses
    {"name": "Wrap Cocktail Dress", "category": "Dresses", "brand": "Diane von Furstenberg",
     "price": "368.00", "product_url": "#", "vendor": "DVF",
     "image_url": "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400",
     "tags": {"style": "elegant", "formality": "formal", "colors": ["black", "burgundy"]}},
    {"name": "Floral Summer Maxi Dress", "category": "Dresses", "brand": "Reformation",
     "price": "218.00", "product_url": "#", "vendor": "Reformation",
     "image_url": "https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400",
     "tags": {"style": "bohemian", "formality": "casual", "colors": ["floral", "multi"]}},

    # Footwear
    {"name": "Leather Oxford Shoes", "category": "Footwear", "brand": "Allen Edmonds",
     "price": "395.00", "product_url": "#", "vendor": "Allen Edmonds",
     "image_url": "https://images.unsplash.com/photo-1614252369475-531eba835eb1?w=400",
     "tags": {"style": "classic", "formality": "business", "colors": ["brown", "black"]}},
    {"name": "White Leather Sneakers", "category": "Footwear", "brand": "Common Projects",
     "price": "425.00", "product_url": "#", "vendor": "Common Projects",
     "image_url": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400",
     "tags": {"style": "minimalist", "formality": "casual", "colors": ["white"]}},
    {"name": "Pointed-Toe Heels", "category": "Footwear", "brand": "Stuart Weitzman",
     "price": "395.00", "product_url": "#", "vendor": "Stuart Weitzman",
     "image_url": "https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400",
     "tags": {"style": "elegant", "formality": "formal", "colors": ["black", "nude"]}},

    # Accessories
    {"name": "Leather Belt", "category": "Accessories", "brand": "Hermès",
     "price": "725.00", "product_url": "#", "vendor": "Hermès",
     "image_url": "https://images.unsplash.com/photo-1624222247344-550fb60583dc?w=400",
     "tags": {"style": "luxury", "formality": "all", "colors": ["brown", "black"]}},
    {"name": "Silk Scarf", "category": "Accessories", "brand": "Gucci",
     "price": "450.00", "product_url": "#", "vendor": "Gucci",
     "image_url": "https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=400",
     "tags": {"style": "luxury", "formality": "smart_casual", "colors": ["multi"]}},
    {"name": "Minimalist Wristwatch", "category": "Accessories", "brand": "Daniel Wellington",
     "price": "249.00", "product_url": "#", "vendor": "Daniel Wellington",
     "image_url": "https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=400",
     "tags": {"style": "minimalist", "formality": "all", "colors": ["black", "silver"]}},

    # Bags
    {"name": "Quilted Shoulder Bag", "category": "Bags", "brand": "Chanel",
     "price": "8500.00", "product_url": "#", "vendor": "Chanel",
     "image_url": "https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400",
     "tags": {"style": "luxury", "formality": "all", "colors": ["black"]}},
    {"name": "Canvas Tote Bag", "category": "Bags", "brand": "Baggu",
     "price": "44.00", "product_url": "#", "vendor": "Baggu",
     "image_url": "https://images.unsplash.com/photo-1591561954557-26941169b49e?w=400",
     "tags": {"style": "casual", "formality": "casual", "colors": ["black", "navy"]}},
]


async def seed():
    async with AsyncSessionLocal() as db:
        # Check if products already exist
        result = await db.execute(select(ShoppingProduct).limit(1))
        if result.scalar_one_or_none():
            print("Products already seeded, skipping.")
            return

        for p in MOCK_PRODUCTS:
            db.add(ShoppingProduct(**p))
        await db.commit()
        print(f"Seeded {len(MOCK_PRODUCTS)} mock products.")


if __name__ == "__main__":
    asyncio.run(seed())
