#!/usr/bin/env bash
# Backup NanoClaw state on the VPS (or any host using deploy/compose.yml).
# Writes a timestamped tar.gz under ./backups/ — keep it off the VPS as well.
set -euo pipefail

ROOT="${NANOCLAW_ROOT:-/home/matty/nanoclaw}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${BACKUP_DIR:-$ROOT/backups}"
mkdir -p "$OUT_DIR"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Backing up files from $ROOT"
tar -C "$ROOT" -czf "$TMP/files.tgz" \
  --exclude='data/v2-sessions' \
  --exclude='backups' \
  --exclude='node_modules' \
  --exclude='.git' \
  groups data/v2.db .env deploy/stack.env 2>/dev/null || \
tar -C "$ROOT" -czf "$TMP/files.tgz" \
  --exclude='data/v2-sessions' \
  --exclude='backups' \
  --exclude='node_modules' \
  groups data/v2.db .env

echo "Backing up OneCLI postgres"
if docker compose -f "$ROOT/deploy/compose.yml" --env-file "$ROOT/deploy/stack.env" ps postgres --status running >/dev/null 2>&1; then
  docker compose -f "$ROOT/deploy/compose.yml" --env-file "$ROOT/deploy/stack.env" exec -T postgres \
    pg_dump -U onecli onecli > "$TMP/onecli.sql"
else
  echo "postgres not running — skipping SQL dump" >&2
fi

if docker volume inspect nanoclaw_onecli-data >/dev/null 2>&1; then
  # userns-remap daemons cannot write a matty-owned TMP without host userns.
  docker run --rm --userns=host \
    -v nanoclaw_onecli-data:/data \
    -v "$TMP":/out \
    alpine tar -czf /out/onecli-data.tgz -C /data .
fi

ARCHIVE="$OUT_DIR/nanoclaw-$STAMP.tar.gz"
tar -C "$TMP" -czf "$ARCHIVE" .
echo "Wrote $ARCHIVE"
ls -lh "$ARCHIVE"
