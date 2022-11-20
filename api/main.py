import os
import random
from typing import Union

import fastapi

if os.getenv("FUNCTIONS_WORKER_RUNTIME"):
    app = fastapi.FastAPI(
        servers=[{"url": "/api", "description": "API"}],
        root_path="/public",
        root_path_in_servers=False,
    )
else:
    app = fastapi.FastAPI()


@app.get("/generate_name")
async def generate_name(
    starts_with: str = None,
    subscription_key: Union[str, None] = fastapi.Query(default=None, alias="subscription-key"),
):
    names = ["Minnie", "Margaret", "Myrtle", "Noa", "Nadia"]
    if starts_with:
        names = [n for n in names if n.lower().startswith(starts_with)]
    random_name = random.choice(names)
    return {"name": random_name}
