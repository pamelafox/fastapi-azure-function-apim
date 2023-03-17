import os

import fastapi

from . import fastapi_routes


def create_app():
    # Check for an environment variable that's only set in production
    if os.getenv("SCM_DO_BUILD_DURING_DEPLOYMENT"):
        app = fastapi.FastAPI(
            servers=[{"url": "/api", "description": "API"}],
            root_path="/public",
            root_path_in_servers=False,
        )
    else:
        app = fastapi.FastAPI()

    app.include_router(fastapi_routes.router)
    return app
