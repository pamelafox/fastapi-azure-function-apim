import random

from fastapi.testclient import TestClient

from .fastapi_app import create_app

client = TestClient(create_app())


def test_generate_name():
    random.seed(1)
    response = client.get("/generate_name")
    assert response.status_code == 200
    assert response.json() == {"name": "Margaret"}


def test_generate_name_params():
    random.seed(1)
    response = client.get("/generate_name", params={"starts_with": "n"})
    assert response.status_code == 200
    assert response.json() == {"name": "Noa"}


def test_docs():
    response = client.get("/docs")
    assert response.status_code == 200


def test_openapi():
    response = client.get("/openapi.json")
    assert response.status_code == 200
