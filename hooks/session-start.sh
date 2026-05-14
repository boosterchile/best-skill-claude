#!/usr/bin/env bash
# agent-rigor :: SessionStart hook
# Runs once at the start of each Claude Code session.
#
# Responsibilities:
#   1. Verify minimum macOS environment (bash, jq, project layout)
#   2. Create a fresh session ledger in .claude/ledger/
#   3. Emit a context block telling the agent which ledger to use and the
#      operating contract location.
#
# bash 3.2 compatible. BSD utils only.

set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
LEDGER_DIR="${PROJECT_DIR}/.claude/ledger"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TODAY="$(date -u +%Y-%m-%d)"

# Read hook input (we don't strictly need it for SessionStart, but consume stdin
# to avoid SIGPIPE if Claude Code sends data).
INPUT="$(cat || true)"

# Extract session_id from input if present; fallback to timestamp+pid.
if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)"
fi
SESSION_ID="${SESSION_ID:-$(date -u +%s)_$$}"

# --- Environment self-check ----------------------------------------------------

WARNINGS=""

if [ -z "${BASH_VERSION:-}" ]; then
    WARNINGS="${WARNINGS}\n  - Hook ran without BASH_VERSION; ensure /usr/bin/env bash exists."
fi

if ! command -v jq >/dev/null 2>&1; then
    WARNINGS="${WARNINGS}\n  - jq not found. Install with: brew install jq"
fi

if ! command -v git >/dev/null 2>&1; then
    WARNINGS="${WARNINGS}\n  - git not found. Required for benchmark and ledger correlation."
fi

# Detect macOS specifically (vs Linux). Hooks are designed for macOS.
case "$(uname -s)" in
    Darwin) ;;
    *) WARNINGS="${WARNINGS}\n  - Non-Darwin OS detected. Hooks assume macOS; BSD utils may behave differently." ;;
esac

# --- Ledger bootstrap ----------------------------------------------------------

mkdir -p "$LEDGER_DIR"
LEDGER_FILE="${LEDGER_DIR}/${TODAY}_${SESSION_ID}.jsonl"

# Idempotent: only write session_start if file is new or empty.
if [ ! -s "$LEDGER_FILE" ]; then
    printf '{"ts":"%s","type":"session_start","session_id":"%s","cwd":"%s","claude_md_sha":"%s"}\n' \
        "$TS" \
        "$SESSION_ID" \
        "$PROJECT_DIR" \
        "$(shasum -a 256 "${PLUGIN_ROOT}/CLAUDE.md" 2>/dev/null | awk '{print $1}' || echo 'absent')" \
        >> "$LEDGER_FILE"
fi

# Export the ledger path for downstream hooks via a sidecar file.
# (Hooks run in fresh shells, so env vars don't persist across hook invocations.)
printf '%s' "$LEDGER_FILE" > "${LEDGER_DIR}/.current"

# --- Emit context to agent -----------------------------------------------------

# additionalContext appears in the agent's working context for this session.
cat <<EOF
[agent-rigor] Session started.

You are operating under the agent-rigor contract.

  Operating contract:  ${PLUGIN_ROOT}/CLAUDE.md
  Session ledger:      ${LEDGER_FILE}
  Project working dir: ${PROJECT_DIR}

REQUIRED before any non-trivial action:
  1. Read ${PLUGIN_ROOT}/CLAUDE.md in full this session.
  2. When entering a phase, read the corresponding ${PLUGIN_ROOT}/skills/<N>-<name>/SKILL.md.
  3. Write phase_enter / phase_exit / artifact_produced events to the ledger.
  4. Never use drift vocabulary ("for now", "MVP", "later", "quick fix", ...)
     without explicit justification recorded in the ledger.
  5. Solo-developer mode: invoke devils-advocate sub-agent at every phase
     transition into REVIEW or SHIP.

EOF

if [ -n "$WARNINGS" ]; then
    printf '[agent-rigor] Environment warnings:%b\n' "$WARNINGS"
fi

exit 0
