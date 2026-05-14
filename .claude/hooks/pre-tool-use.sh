#!/usr/bin/env bash
# agent-rigor :: PreToolUse hook
#
# THIS IS THE MOST IMPORTANT HOOK.
#
# Runs before each Write, Edit, MultiEdit, or Bash tool call.
# Blocks when discipline violations are detected.
#
# Exits:
#   0 — allow
#   2 — block (stderr message shown to agent; agent must reformulate)
#
# Decisions are made on:
#   1. Has CLAUDE.md been read this session?
#   2. Has the current phase's SKILL.md been read?
#   3. Does the file content / bash command contain drift vocabulary without a
#      preceding drift_justified entry in the ledger?
#   4. For Write to source files: is there a spec.md for an inferred feature?
#
# bash 3.2 compatible.

set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LEDGER_DIR="${PROJECT_DIR}/.claude/ledger"
LEDGER_FILE="$(cat "${LEDGER_DIR}/.current" 2>/dev/null || echo "")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

INPUT="$(cat || true)"

# Without jq we cannot reliably parse; fail open to avoid bricking the workflow,
# but log a warning to the ledger.
if ! command -v jq >/dev/null 2>&1; then
    if [ -n "$LEDGER_FILE" ]; then
        printf '{"ts":"%s","type":"hook_degraded","reason":"jq missing"}\n' "$TS" >> "$LEDGER_FILE"
    fi
    exit 0
fi

TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"
TOOL_INPUT_JSON="$(printf '%s' "$INPUT" | jq -c '.tool_input // {}')"

# --- 1. Verify CLAUDE.md was read this session ---------------------------------
# We trust the ledger: a skill_read or read of CLAUDE.md must appear before any
# Write/Edit. Heuristic: count entries with "CLAUDE.md" in the file path field.

if [ -n "$LEDGER_FILE" ] && [ -f "$LEDGER_FILE" ]; then
    CLAUDE_MD_READS="$(grep -c '"file":"[^"]*CLAUDE.md"' "$LEDGER_FILE" 2>/dev/null || true)"
    CLAUDE_MD_READS="${CLAUDE_MD_READS:-0}"
else
    CLAUDE_MD_READS=0
fi

case "$TOOL_NAME" in
    Write|Edit|MultiEdit)
        if [ "$CLAUDE_MD_READS" -lt 1 ]; then
            cat >&2 <<EOF
[agent-rigor BLOCK]

You attempted a $TOOL_NAME but the session ledger shows no read of CLAUDE.md.
Before writing or editing any file in this project, read:

  ${PROJECT_DIR}/CLAUDE.md

Then log the read in the ledger by writing this line:

  echo '{"ts":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","type":"skill_read","file":"${PROJECT_DIR}/CLAUDE.md"}' >> ${LEDGER_FILE:-<ledger>}

Reformulate your action after reading.
EOF
            if [ -n "$LEDGER_FILE" ]; then
                printf '{"ts":"%s","type":"action_blocked","reason":"claude_md_not_read","tool":"%s"}\n' \
                    "$TS" "$TOOL_NAME" >> "$LEDGER_FILE"
            fi
            exit 2
        fi
        ;;
esac

# --- 2. Drift vocabulary in tool input -----------------------------------------

# Concatenate likely text fields from tool_input for scanning.
CONTENT="$(printf '%s' "$TOOL_INPUT_JSON" | jq -r '
    [(.content // ""), (.new_string // ""), (.command // ""), (.file_text // "")]
    | map(tostring) | join("\n")
' 2>/dev/null || true)"

# Strip <quote>...</quote> regions to allow meta-discussion.
STRIPPED="$(printf '%s' "$CONTENT" | sed -E 's|<quote>[^<]*</quote>||g')"

DRIFT_PATTERN='for now|por ahora|más adelante|mas adelante|\bMVP\b|quick fix|hack|temporal|temporary|good enough|TODO: test later|HACK:|XXX:|FIXME[^:]'

MATCHED=""
if [ -n "$STRIPPED" ]; then
    MATCHED="$(printf '%s' "$STRIPPED" | grep -ioE "$DRIFT_PATTERN" | sort -u | tr '\n' ',' | sed 's/,$//' || true)"
fi

if [ -n "$MATCHED" ]; then
    # Check if there's a recent drift_justified entry in the ledger.
    HAS_JUSTIFICATION=0
    if [ -n "$LEDGER_FILE" ] && [ -f "$LEDGER_FILE" ]; then
        # Look at the last 20 ledger entries for a drift_justified within 10 minutes.
        # Portable to BSD (macOS) and GNU (Linux) date.
        NOW_EPOCH="$(date -u +%s)"
        CUTOFF_EPOCH=$((NOW_EPOCH - 600))
        if command -v gdate >/dev/null 2>&1; then
            TEN_MIN_AGO="$(gdate -u -d "@${CUTOFF_EPOCH}" +%Y-%m-%dT%H:%M:%SZ)"
        else
            TEN_MIN_AGO="$(date -u -r "${CUTOFF_EPOCH}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
                || date -u -d "@${CUTOFF_EPOCH}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
                || echo '1970-01-01T00:00:00Z')"
        fi
        RECENT_JUSTIFIED="$(tail -n 20 "$LEDGER_FILE" \
            | jq -r --arg cutoff "$TEN_MIN_AGO" \
                'select(.type == "drift_justified" and .ts > $cutoff) | .triggers' \
                2>/dev/null | head -n 1 || true)"
        if [ -n "$RECENT_JUSTIFIED" ]; then
            HAS_JUSTIFICATION=1
        fi
    fi

    if [ "$HAS_JUSTIFICATION" -eq 0 ]; then
        cat >&2 <<EOF
[agent-rigor BLOCK]

Drift vocabulary detected in $TOOL_NAME content: $MATCHED

Before this action proceeds, stop and:
  1. Quote the offending fragment to the user.
  2. Ask whether this represents deliberate technical debt.
  3. If the user justifies, write to the ledger:
       echo '{"ts":"$TS","type":"drift_justified","triggers":"$MATCHED","justification":"<verbatim>"}' >> $LEDGER_FILE
  4. Then reformulate.
  If the user rejects, rewrite the content without the drift wording.

Rationale: the agent-rigor contract treats this vocabulary as a signal of
unintentional MVP behaviour. Silent acceptance breaks the contract.
EOF
        if [ -n "$LEDGER_FILE" ]; then
            printf '{"ts":"%s","type":"drift_blocked","tool":"%s","triggers":"%s"}\n' \
                "$TS" "$TOOL_NAME" "$MATCHED" >> "$LEDGER_FILE"
        fi
        exit 2
    fi
fi

# --- 3. Source-file Write without spec.md (lightweight check) ------------------

# Heuristic: Write to a path under src/, lib/, app/, components/ etc. with no
# corresponding .specs/<inferred-feature>/spec.md in the repo gets flagged.
# We DO NOT block by default here — too noisy — but we record to the ledger so
# the benchmark can score it.

TARGET_PATH="$(printf '%s' "$TOOL_INPUT_JSON" | jq -r '.file_path // .path // empty' 2>/dev/null || true)"

case "$TOOL_NAME:$TARGET_PATH" in
    Write:*src/*|Write:*app/*|Write:*lib/*|Write:*components/*|Edit:*src/*|Edit:*app/*|Edit:*lib/*|Edit:*components/*)
        SPEC_COUNT="$(find "${PROJECT_DIR}/.specs" -maxdepth 2 -name 'spec.md' 2>/dev/null | wc -l | tr -d ' ')"
        if [ "$SPEC_COUNT" = "0" ]; then
            if [ -n "$LEDGER_FILE" ]; then
                printf '{"ts":"%s","type":"spec_missing_warning","tool":"%s","path":"%s"}\n' \
                    "$TS" "$TOOL_NAME" "$TARGET_PATH" >> "$LEDGER_FILE"
            fi
            cat >&2 <<EOF
[agent-rigor WARN]
Writing to "$TARGET_PATH" but no .specs/<feature>/spec.md exists in the project.
Continuing (warning only). Consider running /spec first.
EOF
            # Do not exit 2 here — warning only. Hook returns success.
        fi
        ;;
esac

exit 0
