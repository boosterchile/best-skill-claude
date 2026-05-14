---
name: performance-optimization
description: Identify and fix performance regressions or hotspots, ALWAYS guided by measurement. Never optimize on intuition. Use when /test reveals a slowdown, when monitoring flags a regression, or when spec §6 (Constraints) sets a performance budget that is at risk.
requires:
  - A measured performance problem (number, not "feels slow")
produces:
  - Before/after measurements
  - Optimisation in code
  - Note in .specs/<feature>/review.md
phase: review
adapted_from: addyosmani/agent-skills (MIT)
---

# Performance Optimization

> Premature optimization is the root of all evil. Late optimization is also evil — it ships slow software. The middle path is _measured_ optimization at the moment the measurement says it matters.

## The cycle

```
MEASURE → IDENTIFY HOTSPOT → HYPOTHESIZE → CHANGE → RE-MEASURE → COMMIT
```

If you cannot show a measurement that improves, you didn't optimize. You changed code.

## When to use

- Lighthouse / Core Web Vitals miss spec §6 budget
- Backend p95 latency exceeds budget
- Memory growth observable in `top`/`htop`/`Activity Monitor`
- A specific operation (API call, DB query, render) is timed > N ms in monitoring
- User-reported "slowness" — first turn it into a measurement; without a measurement, you cannot optimize

## Process

### Step 1 — Measure first, exactly what's slow

Do not optimize until you have a number. The number should:

- Be reproducible (same input, same output)
- Be from production-like conditions (not your M2 Max debugging locally)
- Be statistically reasonable (median + p95 of N≥20 runs, not single shot)

Tools:

| Concern | Tool |
|---|---|
| Frontend rendering | Chrome DevTools Performance tab, Lighthouse, WebPageTest |
| Frontend bundle size | `npx -y bundle-analyzer`, `npx -y vite-bundle-visualizer` |
| Node backend | `clinic.js`, `0x` for flamegraphs |
| Python | `cProfile` + `snakeviz`, `py-spy` for live processes |
| Rust | `cargo flamegraph`, `criterion` for benchmarks |
| DB queries | `EXPLAIN ANALYZE` (Postgres), slow-query log, `pt-query-digest` |
| Memory | `process.memoryUsage()` (Node), `tracemalloc` (Python), Instruments.app on macOS |

### Step 2 — Identify the hotspot

A profile shows where time/memory is spent. Look for:

- Functions taking > 10% of total time
- Allocations in hot loops
- Synchronous I/O in event-loop / request paths
- N+1 queries
- Re-renders triggered by referential inequality
- Bundle bytes that don't justify their presence

The 80/20 rule: usually one or two hotspots dominate. Fix those.

### Step 3 — Hypothesize the cause

State the hypothesis:

> "The `renderRow` function takes 200ms × 50 rows = 10s because it re-computes derived state on every render. Memoising should drop it to 50ms total."

### Step 4 — Make the smallest change

Apply the optimization. Stay minimal. Resist the urge to "also fix" adjacent inefficiencies — separate commits.

### Step 5 — Re-measure

The same measurement protocol as step 1. Did the hypothesis hold?

- If yes → commit with measurements in the message.
- If partial → the bottleneck moved; re-profile and continue.
- If no → revert. The hypothesis was wrong. Don't keep code that didn't help.

### Step 6 — Document

Commit message includes before/after:

```
perf(dashboard): memoize row derived state

Before: p95 render 2.4s (LCP 3.1s)
After:  p95 render 0.3s (LCP 1.4s)
Method: Lighthouse desktop preset, n=20

Tested at the dashboard page with 50 rows; the renderRow hotspot
came from useDerivedState recomputing identity on every parent re-render.
Wrapped in useMemo with stable deps.
```

For non-trivial perf work, also add an entry to `.specs/<feature>/review.md` perf section with the methodology.

## Common patterns

### Frontend

- **Memoize** when state derives from props (React.useMemo, Vue computed)
- **Virtualise** long lists (react-virtual, tanstack-virtual)
- **Defer non-critical** with `<Suspense>`, dynamic import, idle callbacks
- **Image strategy**: explicit dimensions, modern format (AVIF/WebP), srcset, lazy below-fold
- **Avoid layout thrashing**: batch reads then writes, not interleaved
- **Reduce bundle**: tree-shake, code-split per route, swap heavy deps

### Backend

- **Index**: the right indexes turn O(n) scans into O(log n) seeks
- **Cache**: read-through cache for hot lookups; invalidate carefully
- **Batch**: N requests → 1 request when possible (DataLoader, batch endpoints)
- **Async I/O**: never block the event loop on filesystem or network
- **Connection pools**: size them; don't open per-request

### Memory

- **Streaming** for large I/O instead of buffer-everything
- **Bounded queues** rather than unbounded
- **Weak references** for caches (let GC reclaim under pressure)
- Watch for closures capturing large objects

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "I'm pretty sure this loop is the bottleneck" | Pretty sure isn't measured. Profile. |
| "Async/await everywhere will help" | Async helps I/O-bound code, not CPU-bound. Profile first. |
| "Let's add a cache" | Caches are correctness liabilities. Add only after measurement, with explicit invalidation strategy. |
| "Rewriting in <faster language> will fix it" | Rarely. The algorithmic complexity dominates. Fix the algorithm first. |
| "Let's optimise everything we can while we're in here" | Now you have many changes none of which has a documented before/after. Scope to the measured hotspot. |

## Red Flags

- Optimisation without a before measurement
- Optimisation with a before but no after
- "Faster" code that ships behaviour change ("we no longer fetch X because it's slow" — the spec said you needed X)
- Cache without invalidation strategy
- Hot loop with a `console.log` in production
- Heavy library imported for one function (`lodash` for `debounce`)
- Premature `Worker` / `WebWorker` / multithreading without IPC cost accounted for

## Verification

- [ ] Before measurement captured (reproducible, statistically reasonable)
- [ ] Hypothesis stated explicitly
- [ ] Change is minimal and scoped to the hotspot
- [ ] After measurement captured, same methodology
- [ ] Improvement matches hypothesis (or revert)
- [ ] No behaviour change (existing tests still pass with same outputs)
- [ ] Commit message contains the numbers

## Solo-Developer Adaptation

Pick one perf concern per session. Mixing "fix slow page A" and "fix slow query B" produces interleaved measurements you cannot trust. One concern, one cycle, one commit.

## macOS Notes

```bash
# CPU profile of a Node app:
npm install -g 0x
0x server.js
# Open flamegraph in browser.

# Time a curl request (full breakdown):
curl -w "@-" -o /dev/null -s 'https://localhost:3000/api/...' <<'EOF'
DNS: %{time_namelookup}s
Connect: %{time_connect}s
TLS: %{time_appconnect}s
TTFB: %{time_starttransfer}s
Total: %{time_total}s
EOF

# Disk I/O attribution:
sudo fs_usage -w -f filesystem | grep node
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `performance-optimization`).
