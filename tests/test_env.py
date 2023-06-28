import random

import pytest
from fastapi.testclient import TestClient

from api.fastapi_app import create_app


@pytest.fixture
def mock_functions_env(monkeypatch):
    monkeypatch.setenv("SCM_DO_BUILD_DURING_DEPLOYMENT", "true")


def test_functions_env(mock_functions_env):
    random.seed(1)
    client = TestClient(create_app())
    response = client.get("/generate_name")
    assert response.status_code == 200
    assert response.json() == {"name": "Margaret"}


def test_functions_openapi(mock_functions_env):
    client = TestClient(create_app())
    response = client.get("/openapi.json")
    assert response.status_code == 200
    body = response.json()
    assert body["servers"][0]["url"] == "/api"


def test_functions_docs(mock_functions_env):
    client = TestClient(create_app())
    response = client.get("/docs")
    assert response.status_code == 200
    assert b"/public/openapi.json" in response.content
