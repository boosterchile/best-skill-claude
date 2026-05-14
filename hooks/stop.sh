#!/usr/bin/env bash
# agent-rigor :: Stop hook
#
# Runs when the agent finishes its turn (no more actions pending).
# Writes a session_end-ish marker, the cooling-off timestamp (used by /review
# enforcement), and a brief scorecard preview if benchmark scripts exist.
#
# bash 3.2 compatible.

set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
LEDGER_DIR="${PROJECT_DIR}/.claude/ledger"
LEDGER_FILE="$(cat "${LEDGER_DIR}/.current" 2>/dev/null || echo "")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

INPUT="$(cat || true)"

if [ -z "$LEDGER_FILE" ]; then
    exit 0
fi

# turn_end is logged on every Stop, since Claude Code can resume a session.
printf '{"ts":"%s","type":"turn_end"}\n' "$TS" >> "$LEDGER_FILE"

# Update the cooling-off timestamp file. /review reads this and refuses to
# start if < 30 minutes have elapsed since the last source-file modification
# (unless a waiver was issued).
if command -v jq >/dev/null 2>&1; then
    LAST_SOURCE_WRITE="$(tail -n 50 "$LEDGER_FILE" \
        | jq -r 'select(.type == "artifact_produced" and .kind == "source") | .ts' \
        2>/dev/null | tail -n 1 || true)"
    if [ -n "$LAST_SOURCE_WRITE" ]; then
        printf '%s' "$LAST_SOURCE_WRITE" > "${LEDGER_DIR}/.last_source_write"
    fi
fi

# Print a tiny end-of-turn summary (visible in the transcript).
# Note on `grep -c ... || echo 0`: when grep matches zero lines it BOTH prints
# "0" AND exits 1. Using `|| echo 0` would double the output. We instead allow
# the non-zero exit through and default to 0 only when the variable is empty.
count() {
    local pattern="$1" file="$2" n
    n="$(grep -c "$pattern" "$file" 2>/dev/null || true)"
    printf '%s' "${n:-0}"
}

if command -v jq >/dev/null 2>&1; then
    SPEC_COUNT="$(count '"kind":"spec"' "$LEDGER_FILE")"
    PLAN_COUNT="$(count '"kind":"plan"' "$LEDGER_FILE")"
    SOURCE_COUNT="$(count '"kind":"source"' "$LEDGER_FILE")"
    TEST_COUNT="$(count '"kind":"test"' "$LEDGER_FILE")"
    DRIFT_BLOCKED="$(count '"type":"drift_blocked"' "$LEDGER_FILE")"
    DRIFT_JUSTIFIED="$(count '"type":"drift_justified"' "$LEDGER_FILE")"

    cat <<EOF

[agent-rigor turn summary]
  Spec artifacts:     $SPEC_COUNT
  Plan artifacts:     $PLAN_COUNT
  Source files:       $SOURCE_COUNT
  Test files:         $TEST_COUNT
  Drift blocked:      $DRIFT_BLOCKED
  Drift justified:    $DRIFT_JUSTIFIED
  Ledger:             $LEDGER_FILE

EOF
fi

exit 0
