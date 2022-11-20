import azure.functions as func
import nest_asyncio

from .main import app

nest_asyncio.apply()


async def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    asgi_mware = func.AsgiMiddleware(app)
    return asgi_mware.handle(req, context)
