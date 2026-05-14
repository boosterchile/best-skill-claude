---
name: security-and-hardening
description: Apply security thinking to every change that touches authentication, authorization, user input, network, secrets, persistence, or external dependencies. Use during /review when the change touches any of these surfaces. Invokes the security-auditor sub-agent.
requires:
  - Implementation complete
produces:
  - Security section appended to .specs/<feature>/review.md
  - If needed, threat model in .specs/<feature>/threat-model.md
phase: review
adapted_from: addyosmani/agent-skills (MIT)
---

# Security and Hardening

> Security bugs are the only bugs that are simultaneously expensive, irreversible, and embarrassing. Catch them now.

## When to use

**Mandatory** when the change touches:

- Authentication (login, signup, password, token, session)
- Authorization (role checks, permission, ACL, multi-tenancy)
- User input that reaches a query, command, file, eval, or HTML
- Secrets (keys, tokens, credentials) — storage, retrieval, logging
- Network calls (outbound to third parties, webhooks)
- Persistence (DB writes, file writes, cache writes)
- Dependencies (new package, version bump of a security-sensitive lib)
- Anything serialised across a trust boundary

**Recommended** for every `/review`.

## Process

### Step 1 — Threat model in five minutes

Answer the four questions:

1. **What are we protecting?** (data, capability, identity)
2. **From whom?** (anonymous attacker, authenticated user, insider, supply chain)
3. **How might they reach it?** (input field, URL parameter, header, cookie, environment, dependency)
4. **What stops them?** (validation, authorization, sandboxing, rate limit, encryption)

If you cannot answer 4 with concrete mechanisms, that's the work.

### Step 2 — OWASP Top 10 walkthrough

For the change at hand, walk through each:

| Risk | Question |
|---|---|
| Broken access control | Can a user act on data they don't own? Are role checks at the right layer (controller, service, db)? |
| Cryptographic failures | Are secrets in plain text? Are TLS-enforced? Are hashes appropriate (argon2id / bcrypt / scrypt, not MD5/SHA1)? |
| Injection | Are user inputs interpolated into SQL, shell, HTML, eval, file paths? Use parameterized APIs. |
| Insecure design | Is there a missing trust boundary? Is the multi-step flow safe against interruption / repetition? |
| Security misconfiguration | Defaults reviewed? Debug endpoints disabled in prod? CORS narrow? CSP strict? |
| Vulnerable components | New dependency reviewed for known CVEs (`npm audit`, `pip-audit`, `cargo audit`)? |
| Auth and session | Tokens short-lived? Refresh rotated? Logout invalidates server-side? |
| Software / data integrity | Webhook signatures verified? Updates signed? Untrusted serialised data not deserialised? |
| Logging and monitoring | Failed auth logged? PII redacted from logs? Sensitive data not in URLs (referers leak)? |
| SSRF | Outbound URLs validated? Private network ranges blocked? Redirects followed safely? |

### Step 3 — Defence-in-depth check

For each protective mechanism, ask: "if this one fails, what's the next line?"

- Input validation fails → query is parameterised → DB has least-privilege → audit logs catch
- Auth check is missing → tenant isolation is enforced at DB row level → telemetry alerts on cross-tenant queries

Single layers fail. Layered defences absorb individual failures.

### Step 4 — Secrets handling

Verify:

- [ ] No secrets in code, comments, or test fixtures
- [ ] No secrets in commit history (`git log -p | grep -iE '(api[_-]?key|secret|password|token)'`)
- [ ] Secrets in environment or a vault; loaded via well-known paths
- [ ] Secrets never logged, even at debug level
- [ ] Errors don't leak secrets into stack traces or response bodies

### Step 5 — Input boundaries

For every input from outside the trust boundary:

- [ ] Validated (shape, type, range, length)
- [ ] Encoded appropriately at output sinks (HTML escape, URL encode, SQL parameter)
- [ ] Size-limited at the entry point
- [ ] Logged in a sanitised form

### Step 6 — Invoke `security-auditor` sub-agent

```
Task: Use security-auditor sub-agent. Inputs: the diff, spec.md, threat model.
```

Address each objection.

### Step 7 — Run automated scans

```bash
# Dependencies:
npm audit --production       # or yarn npm audit
pip-audit
cargo audit
go list -json -m all | nancy sleuth

# Static analysis for common JS/TS issues:
npx -y eslint . --plugin security

# Secrets in git history:
brew install --cask gitleaks
gitleaks detect --no-banner

# Container if applicable:
docker scout cves <image>
```

Capture results in `review.md` security section.

### Step 8 — Document residual risks

Some risks are accepted (e.g., "we use cookie-based session; XSS would be catastrophic; we mitigate with strict CSP + HttpOnly + SameSite=Strict; residual risk: a CSP bypass via a future third-party script"). Record in `review.md` with an explicit accept-by date.

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "Internal tools don't need security review" | Internal = different threat model, not no threat model. Insider risk, supply chain, lateral movement from compromised endpoints all apply. |
| "We use a framework, it's secure by default" | Frameworks have defaults; your config may have disabled them. Verify. |
| "It's just a small fix" | Single-character bugs ship XSS, SSRF, and SQLi every week. |
| "We'll add rate limiting in v2" | v1 is what gets attacked. v2 is theoretical. |
| "Our users are trusted" | Users get phished. The attacker uses a trusted user's session. |

## Red Flags

- New code path with no authentication check
- User input concatenated into SQL/shell/HTML
- Secrets read from env into log lines
- `eval`, `exec`, `Function()` constructor with any user-influenced input
- HTTP (not HTTPS) outbound calls
- Untrusted JSON deserialised into typed objects without schema validation
- Permissive CORS (`*`)
- Sensitive data in URL query parameters (logged, leaked in referers)

## Verification

- [ ] Threat model documented (even if brief)
- [ ] OWASP Top 10 walkthrough covered
- [ ] Automated scans run; results in review.md
- [ ] `security-auditor` sub-agent invoked; objections addressed
- [ ] Secrets handling verified
- [ ] Input boundaries verified
- [ ] Residual risks recorded with accept-by date

## Solo-Developer Adaptation

Without a security team, you are the security team. The compensation is to invoke `security-auditor` on **every** review touching the mandatory surfaces — no exceptions. The cost of the extra sub-agent call is minutes; the cost of skipping it can be your reputation.

## macOS Notes

```bash
# Local secret scan (pre-commit):
brew install --cask gitleaks
gitleaks protect --staged --no-banner

# Add a pre-commit hook:
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/sh
gitleaks protect --staged --no-banner --redact || exit 1
EOF
chmod +x .git/hooks/pre-commit

# Inspect what a node process opens (occasional leakage signal):
lsof -p $(pgrep -f node) | grep -i '\.env'
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `security-and-hardening`),
with explicit OWASP Top 10 (2021) mapping.
