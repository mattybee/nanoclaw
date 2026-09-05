#!/usr/bin/env bash
# setup-orchestrator.sh — Create and wire the Chief of Staff orchestrator agent.
#
# This script:
#   1. Creates the orchestrator agent group (idempotent — safe to re-run)
#   2. Sets cli_scope to global (needed for agent discovery)
#   3. Sets the model to a high-end thinking model
#   4. Wires agent-to-agent destinations between orchestrator and all workers
#
# Usage:
#   bash scripts/setup-orchestrator.sh
#
# Depends on: ncl (installed and the host service running),
#             jq (for JSON parsing, optional but recommended)
#
# Environment variables (optional):
#   ORCHESTRATOR_MODEL — model name for the orchestrator (default: claude-sonnet-4-20250514)
#   ORCHESTRATOR_PROVIDER — provider for the orchestrator (default: claude)
#   SKIP_MODEL_UPDATE — set to "true" to skip model/provider config (use default)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

ORCHESTRATOR_FOLDER="orchestrator"
ORCHESTRATOR_NAME="Chief of Staff"

# Model configuration (overridable via env)
ORCHESTRATOR_MODEL="${ORCHESTRATOR_MODEL:-claude-sonnet-4-20250514}"
ORCHESTRATOR_PROVIDER="${ORCHESTRATOR_PROVIDER:-claude}"

# Worker groups — name is what gets wired as the destination local_name.
# Format: "name|group_id|folder"
# Keep this synced with groups/orchestrator/agents-index.md
WORKERS=(
  "research|ag-d56914f9-51f7-408b-9e46-214776e7365b|research"
  "travel-guide|ag-d50bfd8f-8618-40c3-a028-0dc84061f2ed|travel"
  "terminal-agent|ag-1788095399180-c84lpg|ping_test"
  "ray|ag-8993327b-3673-4951-9061-37d8c2fbd2a3|accountant"
  "scout|ag-c7a4d6e8-da16-4792-8691-e91e1cb19e30|scout"
  "kit|ag-82ec9e83-bb7d-49f4-8832-a113e6e36168|kit"
  "rick|ag-d2d05ab8-a2b8-4978-a70d-a2f4fe3a698d|rick"
)

# --- Helpers ---

log() { echo "[setup-orchestrator] $*"; }
warn() { echo "[setup-orchestrator] WARNING: $*" >&2; }
fail() { echo "[setup-orchestrator] FAILED: $*" >&2; exit 1; }

# Check ncl is reachable
check_ncl() {
  if ! command -v ncl &>/dev/null; then
    # Try the host socket directly
    if [ -S "data/ncl.sock" ]; then
      log "ncl binary not found, but socket exists at data/ncl.sock"
      log "Ensure the NanoClaw host service is running, then re-run."
      fail "ncl not found in PATH"
    fi
    fail "ncl not found in PATH and data/ncl.sock not found. Is the host running?"
  fi
  log "ncl found: $(command -v ncl)"
}

# Wait for ncl to be responsive
wait_for_ncl() {
  local max_attempts=10
  for ((i=1; i<=max_attempts; i++)); do
    if ncl groups list &>/dev/null; then
      return 0
    fi
    log "Waiting for ncl to respond (attempt $i/$max_attempts)..."
    sleep 2
  done
  fail "ncl not responding after $max_attempts attempts. Is the host service running?"
}

# Get the orchestrator's group ID after creation
get_orchestrator_id() {
  ncl groups list --json 2>/dev/null | \
    python3 -c "import sys,json; data=json.load(sys.stdin)['data']; matches=[g for g in data if g['folder']=='$ORCHESTRATOR_FOLDER']; print(matches[0]['id'] if matches else '')" 2>/dev/null || \
    ncl groups list 2>/dev/null | grep "$ORCHESTRATOR_FOLDER" | awk '{print $1}'
}

# Check if a destination already exists for an agent
destination_exists() {
  local agent_id="$1"
  local local_name="$2"
  ncl destinations list --id "$agent_id" 2>/dev/null | grep -q "$local_name"
}

# --- Main ---

log "=== Setting up Chief of Staff Orchestrator ==="
log "Orchestrator: $ORCHESTRATOR_NAME (folder: $ORCHESTRATOR_FOLDER)"
log "Model: $ORCHESTRATOR_MODEL | Provider: $ORCHESTRATOR_PROVIDER"
log ""

check_ncl
wait_for_ncl

# Step 1: Create the agent group directory (if it doesn't exist)
log "Step 1: Ensuring group directory exists..."
mkdir -p "groups/$ORCHESTRATOR_FOLDER"
# Group files (instructions.prepend.md, agents-index.md, orchestration-protocol.md)
# should already be in place from the skill installation. Verify:
if [ ! -f "groups/$ORCHESTRATOR_FOLDER/instructions.prepend.md" ]; then
  warn "instructions.prepend.md not found in groups/$ORCHESTRATOR_FOLDER/"
  warn "Create it before proceeding, or re-run after placing the file."
fi
log "  ✓ Directory ready: groups/$ORCHESTRATOR_FOLDER/"
echo ""

# Step 2: Create the agent group
log "Step 2: Creating agent group 'Chief of Staff'..."
CREATE_OUTPUT=$(ncl groups create --folder "$ORCHESTRATOR_FOLDER" --name "$ORCHESTRATOR_NAME" 2>&1) || true

if echo "$CREATE_OUTPUT" | grep -q "already exists\|already\|returning existing"; then
  log "  ✓ Agent group already exists (idempotent)"
elif echo "$CREATE_OUTPUT" | grep -q "approval-pending\|approval"; then
  warn "  Group creation requires admin approval. Check your notifications and approve it."
  warn "  After approval, re-run this script to continue wiring."
  warn "  Output: $CREATE_OUTPUT"
  exit 0
elif echo "$CREATE_OUTPUT" | grep -q "Error\|error\|failed"; then
  fail "Group creation failed: $CREATE_OUTPUT"
else
  log "  ✓ Agent group created"
  log "  Output: $CREATE_OUTPUT"
fi
echo ""

# Get the orchestrator's group ID
ORCHESTRATOR_ID=$(get_orchestrator_id)
if [ -z "$ORCHESTRATOR_ID" ]; then
  fail "Could not find orchestrator group ID. Run 'ncl groups list | grep $ORCHESTRATOR_FOLDER' to debug."
fi
log "  Orchestrator ID: $ORCHESTRATOR_ID"
echo ""

# Step 3: Set cli_scope to global
log "Step 3: Setting cli_scope to global..."
CURRENT_SCOPE=$(ncl groups config get --id "$ORCHESTRATOR_ID" 2>/dev/null | grep "cli_scope" | awk '{print $2}' || echo "")
if [ "$CURRENT_SCOPE" = "global" ]; then
  log "  ✓ cli_scope is already global"
else
  SCOPE_OUTPUT=$(ncl groups config update --id "$ORCHESTRATOR_ID" --cli-scope global 2>&1) || true
  if echo "$SCOPE_OUTPUT" | grep -q "approval-pending"; then
    log "  ⏳ cli_scope update requires approval. Check your notifications."
  else
    log "  ✓ cli_scope set to global"
  fi
fi
echo ""

# Step 4: Set model and provider (unless skipped)
if [ "${SKIP_MODEL_UPDATE:-}" != "true" ]; then
  log "Step 4: Setting model to $ORCHESTRATOR_MODEL and provider to $ORCHESTRATOR_PROVIDER..."
  
  PROVIDER_OUTPUT=$(ncl groups config update --id "$ORCHESTRATOR_ID" --provider "$ORCHESTRATOR_PROVIDER" 2>&1) || true
  if echo "$PROVIDER_OUTPUT" | grep -q "approval-pending"; then
    log "  ⏳ Provider update requires approval."
  else
    log "  ✓ Provider set to $ORCHESTRATOR_PROVIDER"
  fi

  MODEL_OUTPUT=$(ncl groups config update --id "$ORCHESTRATOR_ID" --model "$ORCHESTRATOR_MODEL" 2>&1) || true
  if echo "$MODEL_OUTPUT" | grep -q "approval-pending"; then
    log "  ⏳ Model update requires approval."
  else
    log "  ✓ Model set to $ORCHESTRATOR_MODEL"
  fi
else
  log "Step 4: Skipped (SKIP_MODEL_UPDATE=true)"
fi
echo ""

# Step 5: Wire destinations — orchestrator → each worker
log "Step 5: Adding destinations (orchestrator → workers)..."
for WORKER_SPEC in "${WORKERS[@]}"; do
  IFS='|' read -r WORKER_NAME WORKER_ID WORKER_FOLDER <<< "$WORKER_SPEC"
  
  if destination_exists "$ORCHESTRATOR_ID" "$WORKER_NAME"; then
    log "  ✓ Destination '$WORKER_NAME' already exists on orchestrator"
  else
    DEST_OUTPUT=$(ncl destinations add \
      --agent-group-id "$ORCHESTRATOR_ID" \
      --local-name "$WORKER_NAME" \
      --target-type agent \
      --target-id "$WORKER_ID" 2>&1) || true
    
    if echo "$DEST_OUTPUT" | grep -q "approval-pending\|approval"; then
      log "  ⏳ Destination '$WORKER_NAME' requires approval."
    elif echo "$DEST_OUTPUT" | grep -q "Error\|error"; then
      warn "  Failed to add destination '$WORKER_NAME': $DEST_OUTPUT"
    else
      log "  ✓ Destination '$WORKER_NAME' added → $WORKER_FOLDER"
    fi
  fi
done
echo ""

# Step 6: Wire destinations — each worker → orchestrator
log "Step 6: Adding reverse destinations (workers → orchestrator)..."
# Use the orchestrator's local name for reverse destinations
ORCHESTRATOR_LOCAL_NAME="orchestrator"
for WORKER_SPEC in "${WORKERS[@]}"; do
  IFS='|' read -r WORKER_NAME WORKER_ID WORKER_FOLDER <<< "$WORKER_SPEC"
  
  if destination_exists "$WORKER_ID" "$ORCHESTRATOR_LOCAL_NAME"; then
    log "  ✓ Reverse destination '$ORCHESTRATOR_LOCAL_NAME' already exists on $WORKER_NAME"
  else
    DEST_OUTPUT=$(ncl destinations add \
      --agent-group-id "$WORKER_ID" \
      --local-name "$ORCHESTRATOR_LOCAL_NAME" \
      --target-type agent \
      --target-id "$ORCHESTRATOR_ID" 2>&1) || true
    
    if echo "$DEST_OUTPUT" | grep -q "approval-pending\|approval"; then
      log "  ⏳ Reverse destination for $WORKER_NAME requires approval."
    elif echo "$DEST_OUTPUT" | grep -q "Error\|error"; then
      warn "  Failed to add reverse destination for $WORKER_NAME: $DEST_OUTPUT"
    else
      log "  ✓ Reverse destination '$ORCHESTRATOR_LOCAL_NAME' added → $WORKER_NAME"
    fi
  fi
done
echo ""

# Step 7: Restart the orchestrator container
log "Step 7: Restarting orchestrator container to apply config..."
RESTART_OUTPUT=$(ncl groups restart --id "$ORCHESTRATOR_ID" --message "Config update: orchestrator setup complete" 2>&1) || true
if echo "$RESTART_OUTPUT" | grep -q "approval-pending"; then
  log "  ⏳ Restart requires approval. Run after approving: ncl groups restart --id $ORCHESTRATOR_ID"
elif echo "$RESTART_OUTPUT" | grep -q "Error\|error"; then
  warn "  Restart failed: $RESTART_OUTPUT"
else
  log "  ✓ Restart initiated"
fi
echo ""

# --- Summary ---
echo ""
log "========================================"
log "  Orchestrator setup complete!"
log "========================================"
log ""
log "  Orchestrator ID:  $ORCHESTRATOR_ID"
log "  Name:             $ORCHESTRATOR_NAME"
log "  Folder:           $ORCHESTRATOR_FOLDER"
log "  Model:            $ORCHESTRATOR_MODEL"
log "  Provider:         $ORCHESTRATOR_PROVIDER"
log "  CLI Scope:        global"
log ""
log "  Worker destinations wired:"
for WORKER_SPEC in "${WORKERS[@]}"; do
  IFS='|' read -r WORKER_NAME _ WORKER_FOLDER <<< "$WORKER_SPEC"
  log "    → $WORKER_NAME ($WORKER_FOLDER)"
done
log ""
log "  Next steps:"
log "    1. Start a conversation with the orchestrator agent and say hello."
log "    2. Confirm it reads agents-index.md and understands the worker landscape."
log "    3. Test with a parallel dispatch involving two workers."
log ""