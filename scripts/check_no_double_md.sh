#!/usr/bin/env bash
set -euo pipefail

# Fail if any markdown file ends with .md.md.
matches="$(find content -type f -name '*.md.md' -print | sort || true)"

if [ -n "$matches" ]; then
  echo "Found invalid *.md.md files:"
  echo "$matches"
  exit 1
fi

echo "No *.md.md files found."
