#!/usr/bin/env bash
# agent-rigor :: PostToolUse hook
#
# Runs after each Write, Edit, MultiEdit.
# Logs artifact_produced events to the ledger so the benchmark can score
# whether phase artifacts were actually created.
#
# bash 3.2 compatible.

set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LEDGER_DIR="${PROJECT_DIR}/.claude/ledger"
LEDGER_FILE="$(cat "${LEDGER_DIR}/.current" 2>/dev/null || echo "")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

INPUT="$(cat || true)"

if ! command -v jq >/dev/null 2>&1 || [ -z "$LEDGER_FILE" ]; then
    exit 0
fi

TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"
TARGET_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

# Skip ledger entries for hook-internal writes to avoid recursion.
case "$TARGET_PATH" in
    *"/.claude/ledger/"*) exit 0 ;;
esac

# Log Read operations on contract / skill files as skill_read events.
# This closes the loop for pre-tool-use's CLAUDE.md-read check.
case "$TOOL_NAME:$TARGET_PATH" in
    Read:*CLAUDE.md|Read:*SKILL.md|Read:*/skills/*|Read:*/references/*|view:*CLAUDE.md|view:*SKILL.md|view:*/skills/*|view:*/references/*)
        printf '{"ts":"%s","type":"skill_read","tool":"%s","file":"%s"}\n' \
            "$TS" "$TOOL_NAME" "$TARGET_PATH" >> "$LEDGER_FILE"
        exit 0
        ;;
esac

if [ -n "$TARGET_PATH" ] && [ -f "$TARGET_PATH" ]; then
    SHA="$(shasum -a 256 "$TARGET_PATH" 2>/dev/null | awk '{print $1}' || echo 'unknown')"
    SIZE="$(wc -c < "$TARGET_PATH" 2>/dev/null | tr -d ' ' || echo 0)"

    # Classify the artifact. Patterns accept both absolute and relative paths
    # (i.e. `.specs/foo/spec.md` and `/repo/.specs/foo/spec.md`).
    KIND="other"
    case "$TARGET_PATH" in
        *.specs/*/spec.md)   KIND="spec" ;;
        *.specs/*/plan.md)   KIND="plan" ;;
        *.specs/*/verify.md) KIND="verify" ;;
        *.specs/*/review.md) KIND="review" ;;
        *.specs/*/ship.md)   KIND="ship" ;;
        *design-system/MASTER.md) KIND="design_master" ;;
        *design-system/pages/*)   KIND="design_page" ;;
        *docs/adr/*)         KIND="adr" ;;
        *_test.*|*_spec.*|*test_*|*.test.*|*.spec.*) KIND="test" ;;
        *) KIND="source" ;;
    esac

    printf '{"ts":"%s","type":"artifact_produced","tool":"%s","path":"%s","kind":"%s","sha256":"%s","bytes":%s}\n' \
        "$TS" "$TOOL_NAME" "$TARGET_PATH" "$KIND" "$SHA" "$SIZE" \
        >> "$LEDGER_FILE"
fi

exit 0
