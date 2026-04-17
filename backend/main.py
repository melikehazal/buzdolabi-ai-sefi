from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from anthropic import Anthropic
import os
import json
import re
import httpx
import random
from dotenv import load_dotenv
import asyncio

load_dotenv()

app = FastAPI(title="Buzdolabı AI Şefi API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
USDA_API_KEY = os.getenv("USDA_API_KEY")
USDA_BASE_URL = "https://api.nal.usda.gov/fdc/v1"


# --- Models ---

class RecipeRequest(BaseModel):
    ingredients: list[str]

class ProteinItem(BaseModel):
    ingredient: str
    protein_g: float

class SingleRecipe(BaseModel):
    recipe_name: str
    emoji: str
    steps: list[str]

class RecipeResponse(BaseModel):
    recipes: list[SingleRecipe]
    proteins: list[ProteinItem]
    total_protein: float
    tip: str


async def translate_to_english(ingredient: str) -> str:
    message = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=50,
        messages=[{
            "role": "user",
            "content": f"Translate this food ingredient to English. Return ONLY the English word, nothing else: {ingredient}"
        }]
    )
    result = message.content[0].text.strip()
    print(f"Çeviri: {ingredient} → {result}")
    return result


async def get_protein_from_claude(ingredient: str) -> float:
    message = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=50,
        messages=[{
            "role": "user",
            "content": f"100 gram {ingredient} içinde kaç gram protein var? Sadece sayıyı yaz, başka hiçbir şey yazma. Örnek: 25.0"
        }]
    )
    try:
        return float(message.content[0].text.strip())
    except:
        return 0.0


async def get_protein_from_usda(ingredient: str) -> Optional[float]:
    async with httpx.AsyncClient(timeout=10.0) as client_http:
        search_url = f"{USDA_BASE_URL}/foods/search"
        params = {
    "query": ingredient,
    "api_key": USDA_API_KEY,
    "pageSize": 3,
    "dataType": "Foundation,SR Legacy",
}
        response = await client_http.get(search_url, params=params)
        data = response.json()

        if not data.get("foods"):
            return None

        max_protein = 0.0
        for food in data["foods"]:
            nutrients = food.get("foodNutrients", [])
            for nutrient in nutrients:
                if nutrient.get("nutrientName") == "Protein":
                    value = round(nutrient.get("value", 0.0), 1)
                    if value > max_protein:
                        max_protein = value

        if max_protein > 0:
            print(f"USDA protein buldu: {ingredient} → {max_protein}")
            return max_protein

        print(f"USDA protein bulamadı: {ingredient}")
        return None


# --- Endpoints ---

@app.get("/")
def root():
    return {"message": "Buzdolabı AI Şefi API çalışıyor 🍳"}


@app.post("/recipe", response_model=RecipeResponse)
async def get_recipe(request: RecipeRequest):
    if not request.ingredients:
        raise HTTPException(status_code=400, detail="En az 1 malzeme girin.")
    if len(request.ingredients) > 10:
        raise HTTPException(status_code=400, detail="En fazla 10 malzeme girilebilir.")

    ingredients_str = ", ".join(request.ingredients)

    creativity_boost = random.choice([
        "Akdeniz mutfağından ilham al.",
        "Asya mutfağından ilham al.",
        "Amerikan mutfağından ilham al.",
        "Mümkün olduğunca sade ve hızlı tarifler öner.",
        "Biraz egzotik ve farklı tarifler öner.",
    ])

    prompt = f"""
Sen bir şef ve beslenme uzmanısın. Kullanıcının elindeki malzemeler: {ingredients_str}

Bu malzemelerle yapılabilecek 3 FARKLI, protein açısından zengin tarif öner.
{creativity_boost}
Her seferinde yaratıcı ve birbirinden farklı tarifler öner, aynı tarifleri tekrarlama.

Yanıtı SADECE şu JSON formatında ver, başka hiçbir şey yazma:
{{
  "recipes": [
    {{
      "recipe_name": "Yemeğin adı",
      "emoji": "1-2 emoji",
      "steps": ["Adım 1", "Adım 2", "Adım 3"]
    }},
    {{
      "recipe_name": "Yemeğin adı",
      "emoji": "1-2 emoji",
      "steps": ["Adım 1", "Adım 2", "Adım 3"]
    }},
    {{
      "recipe_name": "Yemeğin adı",
      "emoji": "1-2 emoji",
      "steps": ["Adım 1", "Adım 2", "Adım 3"]
    }}
  ],
  "tip": "Kısa bir protein veya lezzet ipucu"
}}
"""

    message = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=1200,
        messages=[{"role": "user", "content": prompt}]
    )

    raw = message.content[0].text.strip()
    raw = re.sub(r"```json|```", "", raw).strip()
    ai_data = json.loads(raw)

    async def process_ingredient(ing: str):
        english_ing = await translate_to_english(ing)
        protein = await get_protein_from_usda(english_ing)
        if protein is None:
            protein = await get_protein_from_claude(ing)
        return ProteinItem(ingredient=ing, protein_g=protein)

    protein_items = await asyncio.gather(*[process_ingredient(ing) for ing in request.ingredients])
    proteins = list(protein_items)
    total = round(sum(item.protein_g for item in proteins), 1)

    return RecipeResponse(
        recipes=ai_data["recipes"],
        proteins=proteins,
        total_protein=round(total, 1),
        tip=ai_data.get("tip", ""),
    )