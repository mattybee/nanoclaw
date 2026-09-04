#!/usr/bin/env bash
# Host-container entrypoint. The checkout is bind-mounted at the same path
# as on the Docker host (see deploy/README.md). This script only fills in
# missing install artefacts, then execs the CMD.
set -euo pipefail

ROOT="${NANOCLAW_ROOT:-/home/matty/nanoclaw}"
cd "$ROOT"

if [ ! -d node_modules ]; then
  echo "nanoclaw-entrypoint: node_modules missing — running pnpm install"
  corepack enable
  pnpm install --frozen-lockfile
fi

if [ ! -f dist/index.js ]; then
  echo "nanoclaw-entrypoint: dist/ missing — running pnpm run build"
  pnpm run build
fi

exec "$@"
