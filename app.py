from __future__ import annotations

import re
from datetime import datetime
from html import unescape
from typing import Any, Dict, List
from urllib.parse import urlparse

import feedparser
import requests
from bs4 import BeautifulSoup
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Cho phép Flutter (web/desktop/mobile) gọi API


def _clean_text(value: str) -> str:
    text = unescape(value or "")
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def _extract_article_content(url: str) -> Dict[str, Any]:
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
        )
    }

    response = requests.get(url, headers=headers, timeout=15)
    response.raise_for_status()

    soup = BeautifulSoup(response.text, "html.parser")

    for tag in soup(["script", "style", "noscript", "iframe"]):
        tag.decompose()

    title = ""
    og_title = soup.find("meta", property="og:title")
    if og_title and og_title.get("content"):
        title = _clean_text(og_title["content"])
    if not title and soup.title and soup.title.string:
        title = _clean_text(soup.title.string)

    image_url = ""
    og_image = soup.find("meta", property="og:image")
    if og_image and og_image.get("content"):
        image_url = og_image["content"].strip()

    description = ""
    og_description = soup.find("meta", property="og:description")
    if og_description and og_description.get("content"):
        description = _clean_text(og_description["content"])

    selectors = [
        "article",
        ".article-content",
        ".article__body",
        ".detail-content",
        ".fck",
        ".content-detail",
        ".main-detail-body",
        ".cms-body",
        ".entry-content",
        ".news-detail",
    ]

    content_root = None
    for selector in selectors:
        content_root = soup.select_one(selector)
        if content_root is not None:
            break

    paragraphs: List[str] = []
    if content_root is not None:
        for node in content_root.select("p, h2, h3, li"):
            text = _clean_text(node.get_text(" ", strip=True))
            if len(text) >= 30:
                paragraphs.append(text)

    if not paragraphs:
        for node in soup.select("p"):
            text = _clean_text(node.get_text(" ", strip=True))
            if len(text) >= 40:
                paragraphs.append(text)

    return {
        "title": title,
        "description": description,
        "imageUrl": image_url,
        "content": paragraphs,
        "sourceHost": urlparse(url).netloc,
        "url": url,
    }


@app.get("/health")
def health():
    return jsonify({"ok": True})


@app.get("/api/news")
def get_news():
    """
    GET /api/news
    Response:
      { "articles": [ {id,title,description,imageUrl,url,source,publishedAt}, ... ] }
    """
    try:
        print("📰 Đang lấy tin tức Việt Nam...")

        feeds = [
            {"url": "https://vnexpress.net/rss/tin-moi-nhat.rss", "source": "VnExpress"},
            {"url": "https://thanhnien.vn/rss/home.rss", "source": "Thanh Niên"},
            {"url": "https://tuoitre.vn/rss/tin-moi-nhat.rss", "source": "Tuổi Trẻ"},
        ]

        articles: List[Dict[str, Any]] = []
        article_id = 1

        for feed_info in feeds:
            try:
                feed = feedparser.parse(feed_info["url"])

                for entry in (feed.entries or [])[:10]:
                    image_url = ""
                    if hasattr(entry, "media_content") and entry.media_content:
                        image_url = entry.media_content[0].get("url", "")
                    elif hasattr(entry, "media_thumbnail") and entry.media_thumbnail:
                        image_url = entry.media_thumbnail[0].get("url", "")
                    elif hasattr(entry, "enclosures") and entry.enclosures:
                        image_url = entry.enclosures[0].get("href", "")

                    published_at = datetime.now().isoformat()
                    if hasattr(entry, "published_parsed") and entry.published_parsed:
                        try:
                            published_at = datetime(*entry.published_parsed[:6]).isoformat()
                        except Exception:
                            pass

                    summary = (
                        entry.get("summary")
                        if isinstance(entry, dict)
                        else getattr(entry, "summary", "")
                    )
                    if summary:
                        summary = _clean_text(str(summary))
                        if len(summary) > 200:
                            summary = summary[:200] + "..."

                    title = entry.get("title") if isinstance(entry, dict) else getattr(entry, "title", None)
                    link = entry.get("link") if isinstance(entry, dict) else getattr(entry, "link", None)

                    articles.append(
                        {
                            "id": str(article_id),
                            "title": title or "Không có tiêu đề",
                            "description": summary or "",
                            "imageUrl": image_url,
                            "url": link or "",
                            "source": feed_info["source"],
                            "publishedAt": published_at,
                        }
                    )
                    article_id += 1

            except Exception as e:
                print(f"Lỗi khi parse feed {feed_info['source']}: {e}")
                continue

        articles.sort(key=lambda x: x.get("publishedAt", ""), reverse=True)
        articles = articles[:30]

        print(f"✅ Tìm thấy {len(articles)} bài báo")
        return jsonify({"articles": articles})

    except Exception as e:
        print(f"❌ Lỗi: {e}")
        return jsonify({"articles": []})


@app.get("/api/news/article")
def get_news_article():
    url = (request.args.get("url") or "").strip()
    if not url:
        return jsonify({"error": "Missing url", "content": []}), 400

    try:
        print(f"📖 Crawl bài báo: {url}")
        article = _extract_article_content(url)
        return jsonify(article)
    except Exception as e:
        print(f"❌ Lỗi crawl bài báo: {e}")
        return jsonify(
            {
                "title": "",
                "description": "",
                "imageUrl": "",
                "content": [],
                "sourceHost": "",
                "url": url,
                "error": str(e),
            }
        ), 500


if __name__ == "__main__":
    print("\n📌 Endpoint có sẵn:")
    print("  • GET /api/news          - Tin tức Việt Nam")
    print("  • GET /api/news/article  - Nội dung bài báo")
    print("  • GET /health            - Health check")
    print("\n" + "=" * 60 + "\n")

    # Chạy Flask server
    app.run(host="0.0.0.0", port=5000, debug=True)