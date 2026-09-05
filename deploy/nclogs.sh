#!/usr/bin/env bash
# Read-only host log tail for the VPS Compose stack.
# Live logs are Docker, not logs/nanoclaw.log (that file is stale under Compose).
set -euo pipefail

CONTAINER="${NCLOGS_CONTAINER:-nanoclaw-host}"
LINES=80
ERRORS_ONLY=0
FOLLOW=0

usage() {
  cat <<'EOF'
nclogs — last lines from nanoclaw-host (read-only)

  nclogs          last 80 lines, then ERROR/WARN hits
  nclogs -e       ERROR/WARN/invalid_blocks/delivery failed only
  nclogs -f       follow
  nclogs -n N     line count (default 80)
EOF
}

while getopts ':efn:h' opt; do
  case "$opt" in
    e) ERRORS_ONLY=1 ;;
    f) FOLLOW=1 ;;
    n)
      case "$OPTARG" in
        ''|*[!0-9]*)
          echo "nclogs: -n needs a positive integer" >&2
          exit 2
          ;;
      esac
      LINES="$OPTARG"
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "nclogs: unknown flag -$OPTARG" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
  echo "nclogs: container $CONTAINER is not running" >&2
  exit 1
fi

PATTERN='ERROR|WARN|invalid_blocks|delivery failed'

if [ "$FOLLOW" -eq 1 ]; then
  exec docker logs -f --tail "$LINES" "$CONTAINER"
fi

if [ "$ERRORS_ONLY" -eq 1 ]; then
  docker logs --tail "$LINES" "$CONTAINER" 2>&1 | grep -E "$PATTERN" || true
  exit 0
fi

echo "=== last $LINES lines ($CONTAINER) ==="
docker logs --tail "$LINES" "$CONTAINER" 2>&1
echo
echo "=== ERROR / WARN / delivery ==="
docker logs --tail "$LINES" "$CONTAINER" 2>&1 | grep -E "$PATTERN" || echo "(none in this window)"
