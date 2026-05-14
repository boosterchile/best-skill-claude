#!/usr/bin/env bash
# agent-rigor :: UserPromptSubmit hook
#
# Runs every time the user submits a message.
#
# Responsibilities:
#   1. Detect drift vocabulary in the user's message and surface it as
#      additional context for the agent (so it cannot pretend it didn't see).
#   2. If the message is a slash command for a phase, remind the agent of the
#      artifact it must produce.
#   3. Log the prompt-submit event to the ledger.
#
# Does NOT block. Drift detection is informational at this layer; the block
# happens at PreToolUse if the agent attempts an action based on drift wording.
#
# bash 3.2 compatible.

set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
LEDGER_DIR="${PROJECT_DIR}/.claude/ledger"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

INPUT="$(cat || true)"

# Extract user prompt text. jq is required for parsing; degrade gracefully.
PROMPT_TEXT=""
if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    PROMPT_TEXT="$(printf '%s' "$INPUT" | jq -r '.prompt // .user_message // .message // empty' 2>/dev/null || true)"
fi

# --- Drift vocabulary scan -----------------------------------------------------

# Pattern is case-insensitive. Anchored with word-boundary-ish.
# Excluded inside <quote>...</quote> blocks (handled by simple stripping).
STRIPPED="$(printf '%s' "$PROMPT_TEXT" | sed -E 's|<quote>[^<]*</quote>||g')"

DRIFT_PATTERN='for now|por ahora|más adelante|mas adelante|\bMVP\b|quick fix|hack|temporal|temporary|good enough|skip the test|skip tests|TODO: test later|prototype|prototipo|por mientras'

MATCHED=""
if [ -n "$STRIPPED" ]; then
    MATCHED="$(printf '%s' "$STRIPPED" | grep -ioE "$DRIFT_PATTERN" | sort -u | tr '\n' ',' | sed 's/,$//' || true)"
fi

# --- Slash command detection ---------------------------------------------------

PHASE_REMINDER=""
case "$PROMPT_TEXT" in
    "/spec"*)
        PHASE_REMINDER="DEFINE phase. Produce .specs/<feature>/spec.md before any code. Read skills/11-spec-driven-development/SKILL.md first."
        ;;
    "/plan"*)
        PHASE_REMINDER="PLAN phase. Requires existing spec.md. Produce .specs/<feature>/plan.md."
        ;;
    "/build"*)
        PHASE_REMINDER="BUILD phase. Requires existing plan.md. Implement one vertical slice per commit (~100 LOC)."
        ;;
    "/design"*)
        PHASE_REMINDER="DESIGN (UI/UX) phase. Produce design-system/MASTER.md or pages/<page>.md. Apply pre-delivery checklist."
        ;;
    "/test"*)
        PHASE_REMINDER="VERIFY phase. TDD: red → green → refactor. Tests must precede the code that makes them pass."
        ;;
    "/review"*)
        PHASE_REMINDER="REVIEW phase. Five-axis review. Invoke code-reviewer AND devils-advocate sub-agents. Verify 30-min cooling-off."
        ;;
    "/ship"*)
        PHASE_REMINDER="SHIP phase. Pre-launch checklist, feature flags, rollback plan, monitoring. Produce .specs/<feature>/ship.md."
        ;;
    "/benchmark"*)
        PHASE_REMINDER="BENCHMARK. Run benchmark/scripts/score-session.sh and report scorecard."
        ;;
esac

# --- Ledger entry --------------------------------------------------------------

LEDGER_FILE="$(cat "${LEDGER_DIR}/.current" 2>/dev/null || echo "")"
if [ -n "$LEDGER_FILE" ] && [ -w "$(dirname "$LEDGER_FILE")" ]; then
    if [ -n "$MATCHED" ]; then
        printf '{"ts":"%s","type":"drift_detected","source":"user_prompt","triggers":"%s"}\n' \
            "$TS" "$MATCHED" >> "$LEDGER_FILE"
    fi
    if [ -n "$PHASE_REMINDER" ]; then
        printf '{"ts":"%s","type":"phase_enter_requested","reminder":"%s"}\n' \
            "$TS" "$(printf '%s' "$PHASE_REMINDER" | sed 's/"/\\"/g')" >> "$LEDGER_FILE"
    fi
fi

# --- Emit context to agent -----------------------------------------------------

if [ -n "$MATCHED" ] || [ -n "$PHASE_REMINDER" ]; then
    echo "[agent-rigor context]"
fi

if [ -n "$PHASE_REMINDER" ]; then
    echo "  Phase reminder: $PHASE_REMINDER"
fi

if [ -n "$MATCHED" ]; then
    cat <<EOF
  Drift vocabulary detected in user message: $MATCHED
  Before acting, ask the user to clarify or justify. If they confirm intent,
  log a drift_justified entry to the ledger with the justification verbatim.
  Do NOT silently proceed as if the language were neutral.
EOF
fi

exit 0
