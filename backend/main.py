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
    return message.content[0].text.strip()

# --- USDA Protein Fonksiyonu ---

async def get_protein_from_usda(ingredient: str) -> float:
    async with httpx.AsyncClient(timeout=10.0) as client_http:
        search_url = f"{USDA_BASE_URL}/foods/search"
        params = {
            "query": ingredient,
            "api_key": USDA_API_KEY,
            "pageSize": 1,
            "dataType": "Foundation,SR Legacy"
        }
        response = await client_http.get(search_url, params=params)
        data = response.json()

        if not data.get("foods"):
            return 0.0

        food = data["foods"][0]
        nutrients = food.get("foodNutrients", [])

        for nutrient in nutrients:
            if nutrient.get("nutrientName") == "Protein":
                return round(nutrient.get("value", 0.0), 1)

    return 0.0


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

    proteins = []
    total = 0.0
    for ing in request.ingredients:
        english_ing = await translate_to_english(ing)
        protein = await get_protein_from_usda(english_ing)
        proteins.append(ProteinItem(ingredient=ing, protein_g=protein))
        total += protein

    return RecipeResponse(
        recipes=ai_data["recipes"],
        proteins=proteins,
        total_protein=round(total, 1),
        tip=ai_data.get("tip", ""),
    )