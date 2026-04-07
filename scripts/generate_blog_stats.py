#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from urllib.parse import quote


REPO_ROOT = Path(__file__).resolve().parents[1]
CONTENT_ROOT = REPO_ROOT / "content"
DOCS_ROOT = REPO_ROOT / "docs"

README_PATH = REPO_ROOT / "README.md"
LATEST_JSON_PATH = DOCS_ROOT / "stats-latest.json"
ENDPOINT_PAIRS_PATH = DOCS_ROOT / "stats-endpoint-pairs.json"
ENDPOINT_CHARS_PATH = DOCS_ROOT / "stats-endpoint-chars.json"
ENDPOINT_PATH = DOCS_ROOT / "stats-endpoint.json"
HISTORY_PATH = DOCS_ROOT / "stats-history.jsonl"

README_START = "<!-- stats:auto:start -->"
README_END = "<!-- stats:auto:end -->"


@dataclass(frozen=True)
class LocaleStats:
    posts: int
    chars: int


def strip_front_matter(text: str) -> str:
    if not text.startswith("---\n"):
        return text
    end_idx = text.find("\n---\n", 4)
    if end_idx == -1:
        return text
    return text[end_idx + len("\n---\n") :]


def content_chars(text: str) -> int:
    no_front_matter = strip_front_matter(text)
    # Count non-whitespace characters as "content chars".
    return len(re.sub(r"\s+", "", no_front_matter, flags=re.UNICODE))


def list_posts(locale: str) -> list[Path]:
    base = CONTENT_ROOT / locale / "posts"
    return sorted(base.rglob("*.md"))


def paired_count(en_posts: list[Path], zh_posts: list[Path]) -> int:
    en_keys = {p.relative_to(CONTENT_ROOT / "en" / "posts").as_posix() for p in en_posts}
    zh_keys = {p.relative_to(CONTENT_ROOT / "zh" / "posts").as_posix() for p in zh_posts}
    return len(en_keys & zh_keys)


def collect_locale_stats(locale: str) -> tuple[list[Path], LocaleStats]:
    posts = list_posts(locale)
    chars = 0
    for post in posts:
        chars += content_chars(post.read_text(encoding="utf-8"))
    return posts, LocaleStats(posts=len(posts), chars=chars)


def read_history() -> list[dict[str, Any]]:
    if not HISTORY_PATH.exists():
        return []
    rows: list[dict[str, Any]] = []
    for line in HISTORY_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        rows.append(json.loads(line))
    return rows


def append_history(snapshot: dict[str, Any]) -> list[dict[str, Any]]:
    history = read_history()
    day = snapshot["date"]
    if history and history[-1].get("date") == day:
        history[-1] = snapshot
    else:
        history.append(snapshot)
    HISTORY_PATH.write_text(
        "".join(json.dumps(row, ensure_ascii=False) + "\n" for row in history),
        encoding="utf-8",
    )
    return history


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def endpoint_url(path: Path) -> str:
    rel = path.relative_to(REPO_ROOT).as_posix()
    encoded = quote(f"https://raw.githubusercontent.com/ttw225/blog/main/{rel}", safe="")
    return f"https://img.shields.io/endpoint?url={encoded}"


def mermaid_xychart(history: list[dict[str, Any]]) -> str:
    dates = [f'"{row["date"][5:]}"' for row in history]
    pairs = [str(int(row["pairs"])) for row in history]
    total_chars_values = [int(row["en_chars"]) + int(row["zh_chars"]) for row in history]
    total_chars = [str(v) for v in total_chars_values]
    y_max = max([10, *total_chars_values]) + 100
    return "\n".join(
        [
            "```mermaid",
            "xychart-beta",
            '  title "Post Pairs and Total Content Chars (Last 10 snapshots)"',
            f"  x-axis [{', '.join(dates)}]",
            f'  y-axis "Count" 0 --> {y_max}',
            f"  bar [{', '.join(pairs)}]",
            f"  line [{', '.join(total_chars)}]",
            "```",
        ]
    )


def render_stats_section(latest: dict[str, Any], history: list[dict[str, Any]]) -> str:
    pairs_badge = endpoint_url(ENDPOINT_PAIRS_PATH)
    chars_badge = endpoint_url(ENDPOINT_CHARS_PATH)
    release_badge = "https://img.shields.io/github/v/release/ttw225/blog?display_name=tag"
    release_link = "https://github.com/ttw225/blog/releases/latest"

    lines = [
        "## Statistics",
        "",
        f"[![latest-release]({release_badge})]({release_link})",
        "[![pages-build-deployment](https://github.com/ttw225/blog/actions/workflows/pages/pages-build-deployment/badge.svg?branch=gh-pages)](https://github.com/ttw225/blog/actions/workflows/pages/pages-build-deployment)",
        "",
        f"![post-pairs]({pairs_badge})",
        f"![total-content-chars]({chars_badge})",
        "",
        f"Last updated: `{latest['date']}`",
        "Counting rule: content chars are non-whitespace characters after front matter removal.",
        "",
        "| Metric | EN | ZH | Total |",
        "| --- | ---: | ---: | ---: |",
        f"| Posts | {latest['en_posts']} | {latest['zh_posts']} | {latest['en_posts'] + latest['zh_posts']} |",
        f"| Content chars (no whitespace) | {latest['en_chars']} | {latest['zh_chars']} | {latest['en_chars'] + latest['zh_chars']} |",
        f"| Paired posts | - | - | {latest['pairs']} |",
        "",
        "Trend (all snapshots):",
        "",
        mermaid_xychart(history),
    ]
    return "\n".join(lines)


def update_readme(section: str) -> None:
    text = README_PATH.read_text(encoding="utf-8")
    block = f"{README_START}\n{section}\n{README_END}"
    if README_START in text and README_END in text:
        text = re.sub(
            rf"{re.escape(README_START)}.*?{re.escape(README_END)}",
            block,
            text,
            count=1,
            flags=re.DOTALL,
        )
    else:
        text = text.replace("## Statistics", block, 1)
    README_PATH.write_text(text, encoding="utf-8")


def main() -> None:
    DOCS_ROOT.mkdir(parents=True, exist_ok=True)
    en_posts, en_stats = collect_locale_stats("en")
    zh_posts, zh_stats = collect_locale_stats("zh")
    pairs = paired_count(en_posts, zh_posts)

    today = datetime.now(UTC).date().isoformat()
    latest = {
        "date": today,
        "pairs": pairs,
        "en_posts": en_stats.posts,
        "zh_posts": zh_stats.posts,
        "en_chars": en_stats.chars,
        "zh_chars": zh_stats.chars,
    }
    write_json(LATEST_JSON_PATH, latest)
    write_json(
        ENDPOINT_PAIRS_PATH,
        {"schemaVersion": 1, "label": "paired posts", "message": str(pairs), "color": "blue"},
    )
    total_chars = en_stats.chars + zh_stats.chars
    write_json(
        ENDPOINT_CHARS_PATH,
        {
            "schemaVersion": 1,
            "label": "total chars",
            "message": f"{total_chars}",
            "color": "6f42c1",
        },
    )
    write_json(
        ENDPOINT_PATH,
        {
            "schemaVersion": 1,
            "label": "post pairs",
            "message": str(pairs),
            "color": "blue",
        },
    )

    history = append_history(latest)
    if not history:
        history = [latest]
    section = render_stats_section(latest, history)
    update_readme(section)


if __name__ == "__main__":
    main()
