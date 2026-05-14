#!/usr/bin/env bash
# agent-rigor :: compare-to-baseline.sh
#
# Side-by-side comparison of current ratios vs baseline targets and the
# "without_agent_rigor" reference values. Useful to track progress over weeks.
#
# Usage:
#   compare-to-baseline.sh --since "7 days ago"
#   compare-to-baseline.sh --last
#
# bash 3.2 compatible.

set -eu

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
SCORE="${PROJECT_DIR}/benchmark/scripts/score-session.sh"

# shellcheck disable=SC2068
JSON="$(bash "$SCORE" --format json $@ 2>/dev/null || true)"

if [ -z "$JSON" ] || printf '%s' "$JSON" | jq -e '.error // empty' >/dev/null 2>&1; then
    printf "No metrics to compare.\n" >&2
    exit 1
fi

printf "agent-rigor — Comparison vs baseline\n\n"
printf "  %-35s %10s %10s %10s   %s\n" "Metric" "Current" "Target" "Without" "Δ vs target"
printf "  %-35s %10s %10s %10s   %s\n" "------" "-------" "------" "-------" "------------"

printf '%s' "$JSON" | jq -r '
    .compliance[]
    | [
        .metric,
        (.value   | (. * 100 | floor | tostring) + "%"),
        (.target  | (. * 100 | floor | tostring) + "%"),
        (.without | (. * 100 | floor | tostring) + "%"),
        ((.value - .target) | (. * 100 | floor | tostring) + " pp")
      ]
    | @tsv
' | while IFS="$(printf '\t')" read -r metric current target without delta; do
    printf "  %-35s %10s %10s %10s   %s\n" "$(printf '%s' "$metric" | tr '_' ' ')" "$current" "$target" "$without" "$delta"
done

printf "\n  ✓ at-or-above target | ⚠ above baseline but below target | ✗ at-or-below baseline\n"
