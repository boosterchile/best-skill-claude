#!/usr/bin/env bash
# agent-rigor :: score-session.sh
#
# Reads metrics from collect-metrics.sh, applies the baseline, and prints a
# human-readable scorecard.
#
# Usage:
#   score-session.sh --last
#   score-session.sh --since "7 days ago"
#   score-session.sh --since "7 days ago" --format json
#   score-session.sh --capture-baseline --since "30 days ago"
#
# bash 3.2 compatible.

set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
BASELINE_FILE="${PROJECT_DIR}/benchmark/baseline.json"
COLLECT="${PROJECT_DIR}/benchmark/scripts/collect-metrics.sh"

FORMAT="text"
CAPTURE=0
PASS_ARGS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --format)             shift; FORMAT="$1" ;;
        --capture-baseline)   CAPTURE=1 ;;
        *) PASS_ARGS="$PASS_ARGS $1" ;;
    esac
    shift
done

# shellcheck disable=SC2086
METRICS="$(bash "$COLLECT" $PASS_ARGS 2>/dev/null)"

if [ -z "$METRICS" ] || printf '%s' "$METRICS" | jq -e '.error' >/dev/null 2>&1; then
    printf "No metrics available.\n%s\n" "$METRICS" >&2
    exit 1
fi

if ! [ -f "$BASELINE_FILE" ]; then
    printf "Baseline file missing: %s\n" "$BASELINE_FILE" >&2
    exit 1
fi

# --- Compute compliance ratios -------------------------------------------------

# We compute ratios in jq using the aggregated metrics.
SCORE_JSON="$(printf '%s' "$METRICS" | jq --slurpfile bl "$BASELINE_FILE" '
    . as $m |
    ($bl[0].target_with_agent_rigor) as $target |
    ($bl[0].without_agent_rigor)    as $without |

    # Derived ratios
    {
        spec_before_code_rate: (
            if $m.artifacts.source > 0 then
                (($m.artifacts.spec | tonumber) /
                 ([$m.artifacts.spec, $m.artifacts.source] | max))
            else 0 end
        ),
        tdd_compliance: (
            if $m.artifacts.source > 0 then
                ($m.artifacts.test / ($m.artifacts.test + $m.artifacts.source))
            else 0 end
        ),
        review_before_merge_rate: (
            if $m.artifacts.ship > 0 then
                ($m.artifacts.review / $m.artifacts.ship)
            else
                (if $m.artifacts.review > 0 then 1 else 0 end)
            end
        ),
        devils_advocate_invocation_rate: (
            if $m.events.phase_exit > 0 then
                ([($m.subagents_invoked["devils-advocate"] // 0), $m.events.phase_exit] | min) / $m.events.phase_exit
            else 0 end
        ),
        adr_coverage: (
            if $m.artifacts.spec > 0 then
                ($m.artifacts.adr / $m.artifacts.spec)
            else 0 end
        ),
        skip_cycle_rate: (
            if $m.events.turn_end > 0 then
                ($m.events.skip_cycle_declared / $m.events.turn_end)
            else 0 end
        ),
        cooling_off_respect_rate: (
            if $m.artifacts.review > 0 then
                (1 - (($m.events.waiver_granted // 0) / $m.artifacts.review))
            else 0 end
        ),
        phase_artifact_completeness: (
            # Average completeness across the 5 phases that have artifacts.
            (
                [
                    ($m.artifacts.spec   | if . > 0 then 1 else 0 end),
                    ($m.artifacts.plan   | if . > 0 then 1 else 0 end),
                    ($m.artifacts.verify | if . > 0 then 1 else 0 end),
                    ($m.artifacts.review | if . > 0 then 1 else 0 end),
                    ($m.artifacts.ship   | if . > 0 then 1 else 0 end)
                ] | add / 5
            )
        ),
        drift_block_to_detect_ratio: (
            if $m.events.drift_detected > 0 then
                ($m.events.drift_blocked / $m.events.drift_detected)
            else 0 end
        )
    } as $ratios |

    {
        range: $m.range,
        ratios: $ratios,
        compliance: (
            $ratios | to_entries | map({
                metric: .key,
                value: .value,
                target: $target[.key],
                without: $without[.key],
                glyph: (
                    if .value >= $target[.key] - 0.05 then "✓"
                    elif .value >= $without[.key] + 0.10 then "="
                    elif .value >= $without[.key] then "⚠"
                    else "✗"
                    end
                )
            })
        ),
        drift_top: ($m.drift_top_triggers | to_entries | sort_by(-.value) | .[0:5]),
        skills_top:  ($m.skills_read | to_entries | sort_by(-.value) | .[0:5]),
        subagents:   $m.subagents_invoked,
        raw: $m
    }
')"

# --- JSON output ---------------------------------------------------------------

if [ "$FORMAT" = "json" ]; then
    printf '%s\n' "$SCORE_JSON"
    exit 0
fi

# --- Capture baseline ---------------------------------------------------------

if [ "$CAPTURE" -eq 1 ]; then
    NEW_BASELINE="$(printf '%s' "$SCORE_JSON" | jq --slurpfile bl "$BASELINE_FILE" '
        $bl[0] + {
            captured_on: (now | strftime("%Y-%m-%d")),
            target_with_agent_rigor: (
                $bl[0].target_with_agent_rigor + (.ratios | with_entries(.key as $k | .value = .value))
            )
        }
    ')"
    printf '%s\n' "$NEW_BASELINE" > "$BASELINE_FILE"
    printf "Baseline updated: %s\n" "$BASELINE_FILE"
    exit 0
fi

# --- Text scorecard ------------------------------------------------------------

printf "agent-rigor — Scorecard (%s → %s)\n\n" \
    "$(printf '%s' "$SCORE_JSON" | jq -r '.range.first_ts // "n/a"')" \
    "$(printf '%s' "$SCORE_JSON" | jq -r '.range.last_ts  // "n/a"')"

printf "Compliance:\n"
printf '%s' "$SCORE_JSON" | jq -r '
    .compliance[]
    | "  \(.glyph) \(.metric | gsub("_"; " ") | . + (40 - length) * " "  )  \((.value*100) | floor)%  (target \((.target*100) | floor)%)"
'

printf "\nDrift:\n"
printf "  detected:  %s\n"   "$(printf '%s' "$SCORE_JSON" | jq -r '.raw.events.drift_detected')"
printf "  blocked:   %s\n"   "$(printf '%s' "$SCORE_JSON" | jq -r '.raw.events.drift_blocked')"
printf "  justified: %s\n"   "$(printf '%s' "$SCORE_JSON" | jq -r '.raw.events.drift_justified')"

TOP_DRIFT="$(printf '%s' "$SCORE_JSON" | jq -r '.drift_top | length')"
if [ "$TOP_DRIFT" -gt 0 ]; then
    printf "  top triggers:\n"
    printf '%s' "$SCORE_JSON" | jq -r '.drift_top[] | "    \(.key): \(.value)"'
fi

printf "\nSkills most read:\n"
printf '%s' "$SCORE_JSON" | jq -r '.skills_top[] | "  \(.key | sub(".*/skills/"; "")) — \(.value) read(s)"'

printf "\nSub-agents invoked:\n"
printf '%s' "$SCORE_JSON" | jq -r '.subagents | to_entries[] | "  \(.key): \(.value)"'

printf "\nSession events: %s · range: %s events / %s sessions\n" \
    "$(printf '%s' "$SCORE_JSON" | jq -r '.raw.range.event_count')" \
    "$(printf '%s' "$SCORE_JSON" | jq -r '.raw.range.event_count')" \
    "$(printf '%s' "$SCORE_JSON" | jq -r '.raw.range.sessions')"
