#!/usr/bin/env bash
# chat-to.sh — Send a message to a specific NanoClaw CLI instance.
#
# Usage:
#   bash scripts/chat-to.sh <instance> <message...>
#
# Examples:
#   bash scripts/chat-to.sh orchestrator "Hello! Who are you?"
#   bash scripts/chat-to.sh travel-guide "Recommend a hotel in Tokyo"
#   bash scripts/chat-to.sh cli "ping"  # default instance
#
# The default CLI instance is "cli". The orchestrator instance is "orchestrator".
#
# Prerequisites: NanoClaw host running, data/cli.sock present.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOCKET="$SCRIPT_DIR/data/cli.sock"

if [ "$#" -lt 2 ]; then
  echo "Usage: bash scripts/chat-to.sh <instance> <message...>"
  echo ""
  echo "Known CLI instances:"
  echo "  cli           — default Terminal Agent"
  echo "  orchestrator  — Chief of Staff orchestrator"
  echo "  travel-guide  — Travel-Guide agent"
  exit 1
fi

INSTANCE="$1"
shift
TEXT="$*"

if [ ! -S "$SOCKET" ]; then
  echo "Error: NanoClaw socket not found at $SOCKET"
  echo "Is the host service running?"
  exit 2
fi

# Build the JSON payload with routing address
PAYLOAD=$(cat <<EOF
{"text":"$TEXT","to":{"channelType":"cli","platformId":"local","instance":"$INSTANCE"}}
EOF
)

# Send via Unix socket, read replies
echo "→ [$INSTANCE] $TEXT"
echo ""

# Use a node one-liner to connect, send, and read responses
node -e "
const net = require('net');
const sock = '$SOCKET';
const payload = JSON.stringify({
  text: '$TEXT',
  to: { channelType: 'cli', platformId: 'local', instance: '$INSTANCE' }
});

const socket = net.connect(sock, () => {
  socket.write(payload + '\n');
});

let firstReply = false;
let silenceTimer = null;

socket.on('data', (chunk) => {
  const lines = chunk.toString().trim().split('\n');
  for (const line of lines) {
    try {
      const msg = JSON.parse(line);
      if (typeof msg.text === 'string') {
        process.stdout.write('← ' + msg.text + '\n');
        firstReply = true;
        if (silenceTimer) clearTimeout(silenceTimer);
        silenceTimer = setTimeout(() => {
          socket.end();
          process.exit(0);
        }, 2000);
      }
    } catch (_) {}
  }
});

socket.on('error', (err) => {
  console.error('Socket error:', err.message);
  process.exit(1);
});

setTimeout(() => {
  if (!firstReply) {
    console.log('(no reply within 30s — agent may be waking up, try again)');
  }
  socket.end();
  process.exit(firstReply ? 0 : 1);
}, 30000);
"