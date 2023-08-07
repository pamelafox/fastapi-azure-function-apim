import random

import pytest
from fastapi.testclient import TestClient

from api.fastapi_app import create_app


@pytest.fixture
def client():
    return TestClient(create_app())


def test_generate_name(client):
    random.seed(1)
    response = client.get("/generate_name")
    assert response.status_code == 200
    assert response.json() == {"name": "Margaret"}


def test_generate_name_params(client):
    random.seed(1)
    response = client.get("/generate_name", params={"starts_with": "n"})
    assert response.status_code == 200
    assert response.json() == {"name": "Noa"}


def test_docs(client):
    response = client.get("/docs")
    assert response.status_code == 200


def test_openapi(client):
    response = client.get("/openapi.json")
    assert response.status_code == 200
