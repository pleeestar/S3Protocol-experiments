#!/usr/bin/env bash
set -e

OUT="project_snapshot.md"

echo "# Project Snapshot" > "$OUT"
echo "" >> "$OUT"

echo "## Directory Tree" >> "$OUT"
echo '```' >> "$OUT"

# tree があれば使う（なければ find）
if command -v tree >/dev/null 2>&1; then
  tree -a -I '.git|node_modules|dist|build|__pycache__' >> "$OUT"
else
  find . \
    -path './.git' -prune -o \
    -path './node_modules' -prune -o \
    -path './dist' -prune -o \
    -path './build' -prune -o \
    -print >> "$OUT"
fi

echo '```' >> "$OUT"
echo "" >> "$OUT"

echo "## File List" >> "$OUT"
echo '```' >> "$OUT"

find . -type f \
  ! -path './.git/*' \
  ! -path './node_modules/*' \
  ! -path './dist/*' \
  ! -path './build/*' \
  | sort >> "$OUT"

echo '```' >> "$OUT"

echo "Saved to $OUT"
