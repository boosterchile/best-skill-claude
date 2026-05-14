# Testing Patterns

> Catalogue of test patterns the agent should recognise and apply. Pulled from
> the testing skills; this is the quick reference, not a tutorial.

## The pyramid (descriptive, not prescriptive)

```
        E2E (few)
       Integration (some)
      Unit (many)
```

If yours is inverted (mostly E2E), the suite is slow and brittle. Cost of building unit foundation is repaid within weeks.

## Arrange-Act-Assert

Every test, every level:

```typescript
test('refresh token returns 401 when expired', async () => {
  // Arrange
  const store = makeStore({ tokens: [{ id: 'X', expiresAt: longAgo }] });
  const handler = makeRefreshHandler({ store, clock: fixedAt(now) });

  // Act
  const response = await handler({ token: 'X' });

  // Assert
  expect(response.status).toBe(401);
  expect(response.body.error).toBe('auth.refresh_expired');
});
```

Skip blank lines and you get tangled tests. Keep them.

## Naming

The name is the only thing a failure-tail reader sees. Use:

- `test_<subject>_<condition>_<expected>` (Python)
- `it('<does X> when <condition>')` (JS/TS)
- `<Subject>_<Condition>_<Expected>` (Java/Kotlin)

Bad: `test1`, `should work`, `auth test`.

## The four flavours

| Flavour | What it verifies | Cost | Use for |
|---|---|---|---|
| **Unit** | One function/class in isolation | < 100ms | Pure logic, reducers, validators, formatters |
| **Component** | One UI component in isolation | < 500ms | Component rendering, events, state |
| **Integration** | Multiple modules together, no network | < 2s | Wired stacks (router + handler + store) |
| **E2E** | Full stack incl. real browser/network | seconds–minutes | User flows, smoke checks |

## Test doubles

- **Fake**: a working implementation with shortcuts (in-memory store, simplified clock). Prefer.
- **Stub**: returns canned answers. Acceptable for boundaries.
- **Mock**: records interactions and asserts on them. Use sparingly; over-mocking couples tests to implementation.
- **Spy**: observes without changing. Useful for telemetry tests.

Rule of thumb: if a test breaks every time you refactor without changing behaviour, it has too many mocks.

## Property-based tests

For pure functions with clear invariants:

```typescript
// fast-check (JS/TS):
fc.assert(fc.property(fc.string(), (s) => {
  expect(decode(encode(s))).toBe(s);
}));
```

Catches edge cases you didn't think of. One property test ≈ dozens of example tests.

## Snapshot tests

Use with discipline:

- ✅ For complex serialised output where the structure is meaningful
- ❌ For React components where every render produces a giant snapshot

If you can't read the snapshot and verify it's correct, the test isn't testing anything.

## Concurrency

For any code that runs in parallel:

```typescript
test('two concurrent refreshes within window return the same pair', async () => {
  const promise1 = handler.refresh(token);
  const promise2 = handler.refresh(token);
  const [r1, r2] = await Promise.all([promise1, promise2]);
  expect(r1).toEqual(r2);
});
```

Don't forget cancellation, timeouts, and partial failures.

## Time

Inject a clock; never use real time in tests:

```typescript
const clock = makeClock({ now: '2026-05-13T12:00:00Z' });
clock.advance({ minutes: 30 });
```

Real `Date.now()` makes tests flake near boundaries.

## Randomness

Inject. Seed in tests. Same input → same output.

```typescript
const rng = seedRng(42);
```

## Network

Three options, in order of preference:

1. **Don't.** Refactor so the test doesn't need network.
2. **Mock at the HTTP layer** (MSW for JS, `respx`/`pytest-httpx` for Python). Tests run with the real client, fake server.
3. **Hit a sandbox** when the third party offers one. Slowest, most brittle.

Real network in tests: only for one or two smoke tests against staging, separated from the main suite.

## Database

- **Unit/Component**: in-memory fake of the repository interface
- **Integration**: real DB engine, ephemeral DB per test (or per suite), seeded fresh
- Use transactions you roll back, or `BEGIN; ... ROLLBACK;` per test
- Postgres locally: `docker run --rm -p 5432:5432 postgres:16` or `pg_tmp`

## Flake patterns and fixes

| Pattern | Fix |
|---|---|
| `setTimeout`-based assertion | Replace with promises/events |
| Polling with no upper bound | Use a deterministic event |
| Hard-coded ports | Random or fixture-assigned |
| Shared module state | Reset between tests |
| Floating-point equality | `toBeCloseTo(expected, digits)` |
| Date comparison across DST | Compare in UTC |

## What 100% coverage means

It means every line ran during tests. It does **not** mean:

- Every branch ran (set `branch: true` on the coverage tool)
- Every assertion is meaningful (a line with `assert true` adds coverage and proves nothing)
- The behaviour is verified

Target: every behaviour in spec §3 has a test that would fail if the behaviour broke. Coverage falls out of that, not the other way around.

## Stacks (quick map)

| Stack | Test runner | Watch mode | Coverage |
|---|---|---|---|
| Node/TS | vitest, jest | `vitest --watch` / `jest --watch` | `--coverage` |
| Python | pytest | `pytest-watch` (`ptw`) | `pytest --cov` |
| Rust | `cargo test` | `cargo watch -x test` | `cargo tarpaulin` |
| Go | `go test` | `entr` + `go test` | `go test -cover` |
| Swift | XCTest | Xcode auto / `xcodebuild` | Xcode coverage report |

## macOS

```bash
# Always-on test watcher:
brew install fswatch
fswatch -o src/ tests/ | xargs -n1 -I{} <test-runner>

# Quick coverage open:
open coverage/lcov-report/index.html
```
