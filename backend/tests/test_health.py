def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"


def test_gemini_test_no_credentials(client):
    """Without GEMINI_API_KEY, test endpoint should return error status gracefully."""
    response = client.get("/api/test/gemini")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "gemini"
    assert data["status"] == "error"
    assert "GEMINI_API_KEY" in data["message"]


def test_databricks_test_no_credentials(client):
    """Without DATABRICKS_HOST, test endpoint should return error status gracefully."""
    response = client.get("/api/test/databricks")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "databricks"
    assert data["status"] == "error"
    assert "DATABRICKS_HOST" in data["message"]
