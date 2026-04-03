#!/usr/bin/env bash
set -euo pipefail

# Validate critical Hugo configuration values for deployment.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN_CONFIG="$ROOT_DIR/config/_default/hugo.toml"
LANG_EN="$ROOT_DIR/config/_default/languages.en.toml"
LANG_ZH="$ROOT_DIR/config/_default/languages.zh.toml"

if [ ! -f "$MAIN_CONFIG" ] || [ ! -f "$LANG_EN" ] || [ ! -f "$LANG_ZH" ]; then
  echo "Missing Hugo config files."
  exit 1
fi

assert_match() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  if ! grep -qE "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_match '^baseURL\s*=\s*"https://ttw225\.github\.io/blog/"' "$MAIN_CONFIG" \
  "baseURL is not the expected production URL."
assert_match '^defaultContentLanguage\s*=\s*"zh"' "$MAIN_CONFIG" \
  "defaultContentLanguage must remain 'zh'."
assert_match '^contentDir\s*=\s*"content/en"' "$LANG_EN" \
  "languages.en.toml contentDir must be content/en."
assert_match '^contentDir\s*=\s*"content/zh"' "$LANG_ZH" \
  "languages.zh.toml contentDir must be content/zh."
assert_match '^\[permalinks\]' "$MAIN_CONFIG" \
  "hugo.toml must define [permalinks] for stable /posts/:slug/ URLs."
assert_match '^\s*posts\s*=\s*"/posts/:slug/"' "$MAIN_CONFIG" \
  "hugo.toml permalinks.posts must be /posts/:slug/."

echo "Core Hugo config assertions passed."
