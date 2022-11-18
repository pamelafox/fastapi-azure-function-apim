import logging

import nest_asyncio
import azure.functions as func

from .main import app

nest_asyncio.apply()

logging.getLogger().setLevel(logging.DEBUG)
logging.getLogger('azure.functions.AsgiMiddleware').setLevel(logging.DEBUG)


async def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    logging.info(req.url)
    asgi_mware = func.AsgiMiddleware(app)
    logging.getLogger('azure.functions.AsgiMiddleware').setLevel(logging.DEBUG)
    return asgi_mware.handle(req, context)