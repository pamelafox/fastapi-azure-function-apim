import random

from fastapi.testclient import TestClient

from . import app

client = TestClient(app)


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
