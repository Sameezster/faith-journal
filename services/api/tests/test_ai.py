def test_categorize_worry_returns_faith_hope_peace(client):
    r = client.post("/api/v1/ai/categorize",
                    json={"text": "I am worried about my future", "context": "reflection"})
    assert r.status_code == 200
    body = r.json()
    slugs = {s["slug"] for s in body["suggestions"]}
    assert body["fallback_used"] is True  # keyword provider in tests
    assert slugs & {"faith", "hope", "peace"}


def test_categorize_prayer_mother_health(client):
    r = client.post("/api/v1/ai/categorize",
                    json={"text": "Please pray for my mother's health", "context": "prayer",
                          "max_suggestions": 3})
    assert r.status_code == 200
    slugs = {s["slug"] for s in r.json()["suggestions"]}
    assert "healing" in slugs
    assert "family" in slugs


def test_categories_taxonomy_has_eleven(client):
    r = client.get("/api/v1/ai/categories")
    assert r.status_code == 200
    assert len(r.json()["categories"]) == 11
