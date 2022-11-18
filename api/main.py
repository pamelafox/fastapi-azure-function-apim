import random
from typing import Union

import fastapi

app = fastapi.FastAPI(
    servers=[
        {"url": "/api", "description": "API"}
    ],
    root_path="/public",
    root_path_in_servers=False,
)

@app.get("/generate_name")
async def generate_name(starts_with: str = None, subscription_key: Union[str, None] = fastapi.Query(default=None, alias="subscription-key")):
    names = ["Minnie", "Margaret", "Myrtle", "Noa", "Nadia"]
    if starts_with:
        names = [n for n in names if n.lower().startswith(starts_with)]
    random_name = random.choice(names)
    return {"name": random_name}

@app.get("/docs", include_in_schema=False)
async def custom_swagger_ui_html(req: fastapi.applications.Request):
    root_path = req.scope.get("root_path", "").rstrip("/")
    openapi_url = root_path + "public/" + app.openapi_url
    return fastapi.applications.get_swagger_ui_html(
        openapi_url=openapi_url,
        title="API",
    )