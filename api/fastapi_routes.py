import random
from typing import Optional

import fastapi

router = fastapi.APIRouter()


@router.get("/generate_name")
async def generate_name(
    starts_with: Optional[str] = None,
    subscription_key: Optional[str] = fastapi.Query(default=None, alias="subscription-key"),
):
    names = ["Minnie", "Margaret", "Myrtle", "Noa", "Nadia"]
    if starts_with:
        names = [n for n in names if n.lower().startswith(starts_with)]
    random_name = random.choice(names)
    return {"name": random_name}
