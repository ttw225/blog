#!/usr/bin/env bash
set -euo pipefail

# Verify menu pageRef entries resolve to content in both languages.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MENU_EN="$ROOT_DIR/config/_default/menus.en.toml"
MENU_ZH="$ROOT_DIR/config/_default/menus.zh.toml"

if [ ! -f "$MENU_EN" ] || [ ! -f "$MENU_ZH" ]; then
  echo "Missing menus.en.toml or menus.zh.toml."
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

REFS_FILE="$TMP_DIR/pagerefs.txt"
MISSING_FILE="$TMP_DIR/missing.txt"

grep -hE '^[[:space:]]*pageRef[[:space:]]*=' "$MENU_EN" "$MENU_ZH" \
  | sed -E 's/.*=[[:space:]]*"([^"]+)".*/\1/' \
  | sort -u > "$REFS_FILE"

is_taxonomy_ref() {
  case "$1" in
    tags|categories|authors|series|tags/*|categories/*|authors/*|series/*) return 0 ;;
    *) return 1 ;;
  esac
}

exists_for_lang() {
  local lang="$1"
  local ref="$2"
  local base="$ROOT_DIR/content/$lang/$ref"
  if [ -f "$base.md" ] || [ -f "$base/_index.md" ] || [ -f "$base/index.md" ] || [ -d "$base" ]; then
    return 0
  fi

  # Accept nested section matches such as projects/<slug>.md.
  if find "$ROOT_DIR/content/$lang" -type f \( -name "$ref.md" -o -path "*/$ref/_index.md" -o -path "*/$ref/index.md" \) | grep -q '.'; then
    return 0
  fi

  return 1
}

while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  if is_taxonomy_ref "$ref"; then
    continue
  fi

  if ! exists_for_lang "en" "$ref"; then
    echo "Missing EN target for pageRef '$ref' (expected under content/en/$ref)" >> "$MISSING_FILE"
  fi

  if ! exists_for_lang "zh" "$ref"; then
    echo "Missing ZH target for pageRef '$ref' (expected under content/zh/$ref)" >> "$MISSING_FILE"
  fi
done < "$REFS_FILE"

if [ -f "$MISSING_FILE" ]; then
  echo "Menu pageRef validation failed:"
  sort -u "$MISSING_FILE"
  exit 1
fi

echo "Menu pageRef validation passed."
