import os

import fastapi

from . import fastapi_routes


def create_app():
    if os.getenv("FUNCTIONS_WORKER_RUNTIME"):
        app = fastapi.FastAPI(
            servers=[{"url": "/api", "description": "API"}],
            root_path="/public",
            root_path_in_servers=False,
        )
    else:
        app = fastapi.FastAPI()

    app.include_router(fastapi_routes.router)
    return app
