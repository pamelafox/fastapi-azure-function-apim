import logging
import os

import fastapi

from . import fastapi_routes

logger = logging.getLogger("fastapi_app")


def create_app():
    logging.basicConfig(level=logging.INFO)
    # Check for an environment variable that's only set in production
    if os.getenv("RUNNING_IN_PRODUCTION"):
        logger.info("Running in production, using /public as root path")
        app = fastapi.FastAPI(
            servers=[{"url": "/api", "description": "API"}],
            root_path="/public",
            root_path_in_servers=False,
        )
    else:
        logger.info("Running in development, using / as root path")
        app = fastapi.FastAPI()

    app.include_router(fastapi_routes.router)
    return app
