#!/usr/bin/env bash
# agent-rigor :: collect-metrics.sh
#
# Aggregates ledger events into raw metrics. Output is JSON to stdout.
# Other scripts (score-session.sh, compare-to-baseline.sh) consume it.
#
# Usage:
#   collect-metrics.sh --self-check           # verify install, no metrics
#   collect-metrics.sh --since "7 days ago"   # aggregate range
#   collect-metrics.sh --last                 # only most recent session
#   collect-metrics.sh --all                  # everything in ledger/
#
# bash 3.2 compatible.

set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
LEDGER_DIR="${PROJECT_DIR}/.claude/ledger"
SKILLS_DIR="${PROJECT_DIR}/skills"

# --- Self-check ----------------------------------------------------------------

self_check() {
    local fail=0

    printf "agent-rigor self-check\n"
    printf "  project: %s\n\n" "$PROJECT_DIR"

    # bash version
    if [ -n "${BASH_VERSION:-}" ]; then
        printf "  ✓ bash %s\n" "$BASH_VERSION"
    else
        printf "  ✗ bash not detected\n"; fail=1
    fi

    # jq
    if command -v jq >/dev/null 2>&1; then
        printf "  ✓ jq %s\n" "$(jq --version)"
    else
        printf "  ✗ jq missing (brew install jq)\n"; fail=1
    fi

    # git
    if command -v git >/dev/null 2>&1; then
        printf "  ✓ git %s\n" "$(git --version | awk '{print $3}')"
    else
        printf "  ✗ git missing (xcode-select --install)\n"; fail=1
    fi

    # OS
    case "$(uname -s)" in
        Darwin) printf "  ✓ macOS %s\n" "$(sw_vers -productVersion 2>/dev/null || uname -r)" ;;
        *) printf "  ⚠ non-Darwin OS detected (hooks designed for macOS BSD utils)\n" ;;
    esac

    # Hooks executable (plugin layout)
    local hooks_dir="${PROJECT_DIR}/hooks"
    if [ -d "$hooks_dir" ]; then
        local non_exec=0
        for h in "$hooks_dir"/*.sh; do
            [ -f "$h" ] || continue
            if [ ! -x "$h" ]; then
                non_exec=$((non_exec+1))
            fi
        done
        if [ "$non_exec" -eq 0 ]; then
            printf "  ✓ all hooks executable\n"
        else
            printf "  ✗ %d hooks not executable. Fix: chmod +x %s/*.sh\n" "$non_exec" "$hooks_dir"
            fail=1
        fi
    else
        printf "  ✗ %s missing\n" "$hooks_dir"; fail=1
    fi

    # Skills count
    if [ -d "$SKILLS_DIR" ]; then
        local skill_count
        skill_count="$(find "$SKILLS_DIR" -name 'SKILL.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
        if [ "$skill_count" -ge 20 ]; then
            printf "  ✓ skills/ has %s SKILL.md files\n" "$skill_count"
        else
            printf "  ⚠ skills/ has only %s SKILL.md (expected ≥ 20)\n" "$skill_count"
        fi
    else
        printf "  ✗ skills/ directory missing\n"; fail=1
    fi

    # Ledger writable (will be created at runtime under the user's project)
    mkdir -p "$LEDGER_DIR" 2>/dev/null || true
    if [ -w "$LEDGER_DIR" ]; then
        printf "  ✓ ledger writable\n"
    else
        printf "  ✗ ledger directory not writable: %s\n" "$LEDGER_DIR"; fail=1
    fi

    # plugin.json present and valid
    if [ -f "${PROJECT_DIR}/.claude-plugin/plugin.json" ]; then
        if command -v jq >/dev/null 2>&1 && jq empty "${PROJECT_DIR}/.claude-plugin/plugin.json" 2>/dev/null; then
            printf "  ✓ .claude-plugin/plugin.json valid\n"
        else
            printf "  ⚠ .claude-plugin/plugin.json present but invalid JSON\n"
        fi
    else
        printf "  ✗ .claude-plugin/plugin.json missing\n"; fail=1
    fi

    # marketplace.json present and valid
    if [ -f "${PROJECT_DIR}/.claude-plugin/marketplace.json" ]; then
        if command -v jq >/dev/null 2>&1 && jq empty "${PROJECT_DIR}/.claude-plugin/marketplace.json" 2>/dev/null; then
            printf "  ✓ .claude-plugin/marketplace.json valid\n"
        else
            printf "  ⚠ .claude-plugin/marketplace.json present but invalid JSON\n"
        fi
    else
        printf "  ✗ .claude-plugin/marketplace.json missing\n"; fail=1
    fi

    # hooks/hooks.json present and valid
    if [ -f "${PROJECT_DIR}/hooks/hooks.json" ]; then
        if command -v jq >/dev/null 2>&1 && jq empty "${PROJECT_DIR}/hooks/hooks.json" 2>/dev/null; then
            printf "  ✓ hooks/hooks.json valid\n"
        else
            printf "  ⚠ hooks/hooks.json present but invalid JSON\n"
        fi
    else
        printf "  ✗ hooks/hooks.json missing\n"; fail=1
    fi

    # CLAUDE.md present
    if [ -f "${PROJECT_DIR}/CLAUDE.md" ]; then
        printf "  ✓ CLAUDE.md present\n"
    else
        printf "  ✗ CLAUDE.md missing\n"; fail=1
    fi

    printf "\n"
    if [ "$fail" -eq 0 ]; then
        printf "All checks passed.\n"
        return 0
    else
        printf "Some checks failed. Fix above issues.\n"
        return 1
    fi
}

# --- Time-range filtering ------------------------------------------------------

# Convert "7 days ago" or ISO date to epoch seconds (macOS-compatible).
to_epoch() {
    local input="$1"
    # ISO 8601 with Z
    if printf '%s' "$input" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z?$'; then
        local clean="${input%Z}"
        date -u -j -f "%Y-%m-%dT%H:%M:%S" "$clean" +%s 2>/dev/null && return 0
    fi
    # ISO date only
    if printf '%s' "$input" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
        date -u -j -f "%Y-%m-%d" "$input" +%s 2>/dev/null && return 0
    fi
    # Relative: "7 days ago"
    case "$input" in
        *"days ago"|*"day ago")
            local n="${input%% *}"
            date -u -j -v-"${n}d" +%s 2>/dev/null && return 0
            ;;
        *"hours ago"|*"hour ago")
            local n="${input%% *}"
            date -u -j -v-"${n}H" +%s 2>/dev/null && return 0
            ;;
        *"weeks ago"|*"week ago")
            local n="${input%% *}"
            local d=$((n * 7))
            date -u -j -v-"${d}d" +%s 2>/dev/null && return 0
            ;;
    esac
    # Fallback: assume now
    date -u +%s
}

# --- Argument parsing ----------------------------------------------------------

MODE="last"
SINCE=""
UNTIL=""

while [ $# -gt 0 ]; do
    case "$1" in
        --self-check)         self_check; exit $? ;;
        --last)               MODE="last" ;;
        --all)                MODE="all" ;;
        --since)              shift; SINCE="$1"; MODE="range" ;;
        --until)              shift; UNTIL="$1" ;;
        -h|--help)
            sed -n '3,15p' "$0" | sed 's/^# //; s/^#//'
            exit 0
            ;;
        *) printf "Unknown arg: %s\n" "$1" >&2; exit 64 ;;
    esac
    shift
done

if ! command -v jq >/dev/null 2>&1; then
    printf '{"error":"jq required"}\n'
    exit 1
fi

# --- Locate ledger files -------------------------------------------------------

if [ ! -d "$LEDGER_DIR" ]; then
    printf '{"error":"no ledger directory","path":"%s"}\n' "$LEDGER_DIR"
    exit 1
fi

LEDGER_FILES=""
case "$MODE" in
    last)
        LEDGER_FILES="$(ls -t "${LEDGER_DIR}"/*.jsonl 2>/dev/null | head -n 1 || true)"
        ;;
    all)
        LEDGER_FILES="$(ls "${LEDGER_DIR}"/*.jsonl 2>/dev/null || true)"
        ;;
    range)
        LEDGER_FILES="$(ls "${LEDGER_DIR}"/*.jsonl 2>/dev/null || true)"
        ;;
esac

if [ -z "$LEDGER_FILES" ]; then
    printf '{"error":"no ledger files found","mode":"%s"}\n' "$MODE"
    exit 1
fi

# --- Aggregate -----------------------------------------------------------------

SINCE_EPOCH="0"
UNTIL_EPOCH="$(date -u +%s)"
if [ -n "$SINCE" ]; then SINCE_EPOCH="$(to_epoch "$SINCE")"; fi
if [ -n "$UNTIL" ]; then UNTIL_EPOCH="$(to_epoch "$UNTIL")"; fi

# Read all in-range events into a JSON array via jq.
EVENTS="$(
    for f in $LEDGER_FILES; do
        [ -f "$f" ] || continue
        # JSONL → JSON array of objects, with epoch derived from ts
        jq -c --arg since "$SINCE_EPOCH" --arg until "$UNTIL_EPOCH" '
            select(.ts) |
            . + {epoch: (.ts | sub("Z$"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime)} |
            select(.epoch >= ($since | tonumber) and .epoch <= ($until | tonumber))
        ' "$f" 2>/dev/null || true
    done | jq -s '.' 2>/dev/null
)"

if [ -z "$EVENTS" ] || [ "$EVENTS" = "[]" ]; then
    printf '{"error":"no events in range","since":"%s","until":"%s"}\n' "$SINCE" "$UNTIL"
    exit 1
fi

# --- Metric extraction via jq --------------------------------------------------

printf '%s\n' "$EVENTS" | jq '
    def count_type(t): map(select(.type == t)) | length;
    def count_artifact(k): map(select(.type == "artifact_produced" and .kind == k)) | length;

    {
        range: {
            event_count: length,
            first_ts: (sort_by(.ts) | first.ts),
            last_ts:  (sort_by(.ts) | last.ts),
            sessions: ([.[] | select(.type == "session_start") | .session_id] | unique | length)
        },
        events: {
            phase_enter:        count_type("phase_enter"),
            phase_exit:         count_type("phase_exit"),
            session_start:      count_type("session_start"),
            turn_end:           count_type("turn_end"),
            skill_read:         count_type("skill_read"),
            drift_detected:     count_type("drift_detected"),
            drift_blocked:      count_type("drift_blocked"),
            drift_justified:    count_type("drift_justified"),
            action_blocked:     count_type("action_blocked"),
            skip_cycle_declared: count_type("skip_cycle_declared"),
            waiver_granted:     count_type("waiver_granted"),
            subagent_invoked:   count_type("subagent_invoked"),
            subagent_returned:  count_type("subagent_returned")
        },
        artifacts: {
            spec:           count_artifact("spec"),
            plan:           count_artifact("plan"),
            verify:         count_artifact("verify"),
            review:         count_artifact("review"),
            ship:           count_artifact("ship"),
            design_master:  count_artifact("design_master"),
            design_page:    count_artifact("design_page"),
            adr:            count_artifact("adr"),
            test:           count_artifact("test"),
            source:         count_artifact("source")
        },
        drift_top_triggers: (
            [.[] | select(.type | startswith("drift_")) | .triggers // empty]
            | flatten
            | map(split(",") | .[]) | map(. | gsub("^ +| +$"; ""))
            | reduce .[] as $t ({}; .[$t] = (.[$t] // 0) + 1)
        ),
        skills_read: (
            [.[] | select(.type == "skill_read") | .file]
            | reduce .[] as $s ({}; .[$s] = (.[$s] // 0) + 1)
        ),
        subagents_invoked: (
            [.[] | select(.type == "subagent_invoked") | .agent]
            | reduce .[] as $a ({}; .[$a] = (.[$a] // 0) + 1)
        )
    }
'
