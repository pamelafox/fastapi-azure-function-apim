import asyncio
import importlib
import json
import random
import sys

import azure.functions as func
import pytest

from . import main


# Based on https://github.com/Azure/azure-functions-python-library/blob/deafb7972f6562b0c1b700a04b7476df246e53f8/tests/test_http_asgi.py#L121
class MockContext(func.Context):
    @property
    def invocation_id(self):
        return ""

    @property
    def thread_local_storage(self):
        return None

    @property
    def function_name(self):
        return ""

    @property
    def function_directory(self):
        return ""

    @property
    def trace_context(self):
        return None

    @property
    def retry_context(self):
        return None


@pytest.fixture
def mock_functions_env(monkeypatch):
    monkeypatch.setenv("SCM_DO_BUILD_DURING_DEPLOYMENT", "true")
    app_module = sys.modules["api"]
    importlib.reload(app_module)
    from . import main  # noqa


def test_functions_env(mock_functions_env):
    random.seed(1)
    req = func.HttpRequest(method="GET", body=None, url="/generate_name", params={})
    resp = asyncio.get_event_loop().run_until_complete(main(req, MockContext()))

    assert resp.status_code == 200
    body = json.loads(resp.get_body())
    assert body["name"] == "Margaret"


def test_functions_openapi(mock_functions_env):
    req = func.HttpRequest(method="GET", body=None, url="/openapi.json", params={})
    resp = asyncio.get_event_loop().run_until_complete(main(req, MockContext()))

    assert resp.status_code == 200
    body = json.loads(resp.get_body())
    assert body["servers"][0]["url"] == "/api"


def test_functions_docs(mock_functions_env):
    req = func.HttpRequest(method="GET", body=None, url="/docs", params={})
    resp = asyncio.get_event_loop().run_until_complete(main(req, MockContext()))

    assert resp.status_code == 200
    assert b"/public/openapi.json" in resp.get_body()
