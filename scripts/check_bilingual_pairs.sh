#!/usr/bin/env bash
set -euo pipefail

# Verify zh/en markdown files are paired by relative path.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EN_DIR="$ROOT_DIR/content/en"
ZH_DIR="$ROOT_DIR/content/zh"
IGNORE_FILE="$ROOT_DIR/scripts/bilingual-ignore.txt"

if [ ! -d "$EN_DIR" ] || [ ! -d "$ZH_DIR" ]; then
  echo "Missing content/en or content/zh directory."
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

EN_LIST="$TMP_DIR/en.txt"
ZH_LIST="$TMP_DIR/zh.txt"
IGNORE_LIST="$TMP_DIR/ignore.txt"

find "$EN_DIR" -type f -name '*.md' -print | sed "s|^$EN_DIR/||" | sort > "$EN_LIST"
find "$ZH_DIR" -type f -name '*.md' -print | sed "s|^$ZH_DIR/||" | sort > "$ZH_LIST"

if [ -f "$IGNORE_FILE" ]; then
  # Keep only normalized non-empty entries and drop comments.
  grep -vE '^\s*(#|$)' "$IGNORE_FILE" | sed 's|^\./||' | sort -u > "$IGNORE_LIST" || true
else
  : > "$IGNORE_LIST"
fi

ONLY_EN="$TMP_DIR/only_en.txt"
ONLY_ZH="$TMP_DIR/only_zh.txt"
ONLY_EN_FILTERED="$TMP_DIR/only_en_filtered.txt"
ONLY_ZH_FILTERED="$TMP_DIR/only_zh_filtered.txt"

comm -23 "$EN_LIST" "$ZH_LIST" > "$ONLY_EN"
comm -13 "$EN_LIST" "$ZH_LIST" > "$ONLY_ZH"

if [ -s "$IGNORE_LIST" ]; then
  grep -vFx -f "$IGNORE_LIST" "$ONLY_EN" > "$ONLY_EN_FILTERED" || true
  grep -vFx -f "$IGNORE_LIST" "$ONLY_ZH" > "$ONLY_ZH_FILTERED" || true
else
  cp "$ONLY_EN" "$ONLY_EN_FILTERED"
  cp "$ONLY_ZH" "$ONLY_ZH_FILTERED"
fi

if [ -s "$ONLY_EN_FILTERED" ] || [ -s "$ONLY_ZH_FILTERED" ]; then
  echo "Bilingual mismatch found."
  if [ -s "$ONLY_EN_FILTERED" ]; then
    echo ""
    echo "Files only in content/en:"
    cat "$ONLY_EN_FILTERED"
  fi
  if [ -s "$ONLY_ZH_FILTERED" ]; then
    echo ""
    echo "Files only in content/zh:"
    cat "$ONLY_ZH_FILTERED"
  fi
  echo ""
  echo "Add missing counterparts or list intentional exceptions in scripts/bilingual-ignore.txt"
  exit 1
fi

echo "Bilingual file pairing check passed."
