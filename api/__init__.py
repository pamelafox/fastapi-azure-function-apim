import nest_asyncio
import azure.functions as func

from .main import app

nest_asyncio.apply()


async def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    asgi_mware = func.AsgiMiddleware(app)
    return asgi_mware.handle(req, context)
