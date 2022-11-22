import azure.functions as func
import nest_asyncio

from .fastapi_app import create_app

nest_asyncio.apply()

fastapi_app = create_app()


async def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    return await func.AsgiMiddleware(fastapi_app).handle_async(req, context)
