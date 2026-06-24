def test_translations_lists_kjv_and_web(client):
    r = client.get("/api/v1/bible/translations")
    assert r.status_code == 200
    codes = {t["code"] for t in r.json()["translations"]}
    assert {"KJV", "WEB"} <= codes


def test_books_grouped_by_testament(client):
    r = client.get("/api/v1/bible/KJV/books")
    assert r.status_code == 200
    body = r.json()
    assert any(b["name"] == "John" for b in body["testaments"]["NT"])
    assert any(b["name"] == "Genesis" for b in body["testaments"]["OT"])


def test_get_john_3_includes_verse_16(client):
    r = client.get("/api/v1/bible/KJV/John/3")
    assert r.status_code == 200
    verses = r.json()["verses"]
    assert any("God so loved the world" in v["text"] for v in verses)


def test_search_finds_hope(client):
    r = client.get("/api/v1/bible/search", params={"q": "hope"})
    assert r.status_code == 200
    assert len(r.json()["results"]) >= 1


def test_missing_chapter_returns_404_envelope(client):
    r = client.get("/api/v1/bible/KJV/John/99")
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "chapter_not_found"


def test_health(client):
    r = client.get("/api/v1/health")
    assert r.status_code == 200 and r.json()["status"] == "ok"
