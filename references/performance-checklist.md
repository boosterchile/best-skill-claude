# Performance Checklist

> Used by skill `53-performance-optimization`. Walk through before declaring
> performance work done. Always with measurements — no item passes by intuition.

## Budgets (spec §6 should set these)

Typical defaults; adjust per project:

### Frontend

- LCP (Largest Contentful Paint) ≤ 2.5s on mobile 4G
- CLS (Cumulative Layout Shift) ≤ 0
- INP (Interaction to Next Paint) ≤ 200ms
- TTFB ≤ 600ms (cold), ≤ 200ms (cached)
- Total JS payload ≤ 200KB gzipped (initial route)
- Total CSS payload ≤ 50KB gzipped
- Above-fold images ≤ 200KB total

### Backend

- p50 API latency ≤ 100ms
- p95 API latency ≤ 500ms
- p99 API latency ≤ 1000ms
- Error rate ≤ 0.1%
- DB query p95 ≤ 50ms
- DB connection pool not saturated under expected load

### Mobile / desktop apps

- Cold launch ≤ 1.5s
- Memory steady-state within app's documented budget
- Battery: no background work > 5% CPU average

## Before changing anything

- [ ] Reproducible measurement of the problem
- [ ] Number, not "feels slow"
- [ ] From production-like conditions, not just dev laptop
- [ ] Statistical: n ≥ 20, report median + p95

## Frontend — bundle

- [ ] Bundle analyzer run; understand what's in each chunk
- [ ] Route-level code splitting in place
- [ ] Dynamic imports for below-fold or low-frequency features
- [ ] Tree-shaking working (import specific symbols, not whole packages)
- [ ] No giant dep imported for one function (lodash for debounce; date-fns instead of moment)
- [ ] Source maps generated but not served to production
- [ ] CSS critical-path inlined or preloaded
- [ ] Fonts: `font-display: swap`; only weights actually used; preload the critical font

## Frontend — runtime

- [ ] No unnecessary re-renders (React: memo, useMemo, useCallback; Vue: computed; Svelte: reactive declarations)
- [ ] Long lists virtualised (tanstack-virtual, react-virtual)
- [ ] Images: explicit width/height (no layout shift), modern format (AVIF/WebP), `loading="lazy"` below fold, `decoding="async"`, `srcset` for responsive
- [ ] Heavy computations off the main thread (Web Workers) when measured to help
- [ ] Avoid layout thrashing: batch reads then writes; use `requestAnimationFrame` for visual updates
- [ ] Animations use `transform` / `opacity` only (GPU compositing)
- [ ] `will-change` used sparingly (it has a cost)
- [ ] `IntersectionObserver` instead of scroll listeners

## Frontend — network

- [ ] HTTP/2 or HTTP/3
- [ ] Compression (Brotli > gzip)
- [ ] CDN for static assets
- [ ] Cache headers (`Cache-Control: max-age=31536000, immutable` for hashed assets)
- [ ] Service worker for offline / repeat visit speed (when appropriate)
- [ ] No render-blocking third-party scripts above the fold
- [ ] Subresource integrity for third-party scripts
- [ ] Resource hints: `preconnect` to third-party origins, `dns-prefetch` for low-priority

## Backend — runtime

- [ ] No synchronous I/O in request path (filesystem, network)
- [ ] Event-loop unblocked (Node specifically: no CPU-bound work without offloading)
- [ ] N+1 query pattern absent (use DataLoader, joins, batch endpoints)
- [ ] Connection pool sized appropriately (`max` = min(CPU * 4, DB max connections))
- [ ] No tight retry loops (exponential backoff with jitter)
- [ ] Timeouts on every outbound call (connect, read, total)
- [ ] Graceful shutdown drains in-flight requests

## Backend — DB

- [ ] Indexes on every WHERE / JOIN / ORDER BY column that matters
- [ ] `EXPLAIN ANALYZE` run on the queries the change adds/modifies
- [ ] No SELECT *; explicit columns
- [ ] No correlated subqueries when JOIN suffices
- [ ] Pagination is keyset (cursor) when ordered, not OFFSET for large offsets
- [ ] Transactions short; long-running locks avoided
- [ ] Connection pool monitored
- [ ] Read replicas used for read-heavy paths (when applicable)

## Backend — cache

- [ ] Caching introduced only after measurement (not preemptively)
- [ ] Cache key strategy documented
- [ ] Invalidation strategy explicit (TTL, event-based, manual)
- [ ] Cache stampede protected (single-flight, locking, request coalescing)
- [ ] Cache hit ratio monitored
- [ ] Cache miss path always works (don't depend on the cache)

## Memory

- [ ] Streaming for large I/O (uploads, exports), not buffer-everything
- [ ] Bounded queues / channels
- [ ] No closures capturing large objects in long-lived scope
- [ ] Periodic memory profile to detect leaks (Node `--inspect`, Python `tracemalloc`, Activity Monitor)
- [ ] GC tuned only after evidence (default is usually right)

## Latency — instrumentation

- [ ] Request lifecycle: timestamp at each meaningful boundary (received, parsed, db-start, db-end, sent)
- [ ] Slowest spans identifiable in a trace
- [ ] Per-route latency percentiles reported (p50, p95, p99)
- [ ] Latency alerts at p95 threshold

## After change

- [ ] Re-measure with same protocol as the baseline
- [ ] Improvement matches the hypothesis (or revert — don't keep code that didn't help)
- [ ] Commit message contains before/after numbers
- [ ] Regression test (perf test) added if the spec has a budget
- [ ] Monitoring continues to confirm the improvement in production

## Common red flags

- Caches without invalidation strategy
- "Async/await everywhere" without distinguishing I/O-bound from CPU-bound
- Premature workers / threading
- Heavy logging in hot paths (synchronous file I/O on every request)
- Repeated computation that should be memoised
- Computation done on the client that the server already has
- Computation done on the server that the client already has
- N+1 queries hidden by an ORM

## macOS-local tools

```bash
# Node profiling
npm install -g 0x clinic
0x server.js
clinic doctor -- node server.js
clinic flame -- node server.js

# Python
pip3 install py-spy snakeviz
py-spy record -o profile.svg -- python app.py
python -m cProfile -o p.prof script.py && snakeviz p.prof

# Rust
cargo install flamegraph
cargo flamegraph

# Frontend
npx -y lighthouse https://localhost:3000 --view
npx -y bundle-buddy stats.json   # or webpack-bundle-analyzer

# Network
curl -w '@-' -o /dev/null -s URL <<'EOF'
DNS: %{time_namelookup}s
Connect: %{time_connect}s
TLS: %{time_appconnect}s
TTFB: %{time_starttransfer}s
Total: %{time_total}s
EOF

# Disk I/O attribution
sudo fs_usage -w -f filesystem | grep node
```
