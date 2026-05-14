# Security Checklist

> Used by `security-auditor` agent and skill `52-security-and-hardening`. The
> agent should walk through this for any change touching auth, input, secrets,
> network, persistence, or dependencies.

## Pre-implementation (during /spec, /plan)

- [ ] Threat model: who, what, how, what stops them
- [ ] Trust boundaries identified
- [ ] Inputs from outside the boundary enumerated
- [ ] Outputs that cross the boundary enumerated
- [ ] Required permissions / authorization rules stated
- [ ] Logging and monitoring requirements stated

## Implementation

### Authentication

- [ ] Every authenticated route actually checks auth (middleware verified)
- [ ] Sessions are server-side invalidatable
- [ ] Tokens short-lived (access ≤ 1h, refresh ≤ 30d typical)
- [ ] Refresh rotation in place if using refresh tokens
- [ ] Password hashes: argon2id (preferred), bcrypt (acceptable), scrypt (acceptable). Never plain SHA/MD5
- [ ] Hashes parameterised correctly (cost factor not too low)
- [ ] Login throttled / rate-limited
- [ ] Failed-login attempts logged
- [ ] Logout invalidates server-side state

### Authorization

- [ ] Every action checks the actor is allowed to perform it
- [ ] Authorization check at the right layer (often: route → service → DB row)
- [ ] Multi-tenant: queries scoped at row level (tenant_id filter or RLS)
- [ ] No IDOR: cannot access another user's resource by changing an ID in the URL
- [ ] Admin endpoints require admin (and explicitly assert role)

### Input validation

- [ ] Every user-controlled input validated for shape, type, range, length
- [ ] Size limits enforced at entry (max request body, max upload, max field length)
- [ ] Allow-list when possible; deny-list only when necessary
- [ ] File uploads: extension, MIME, magic-byte check; stored outside web root
- [ ] Filenames sanitised (no `../`, no special chars, length capped)

### Injection sinks

- [ ] SQL: parameterised queries / prepared statements only (NEVER string concat)
- [ ] Shell: `execFile` / argument arrays / explicit allow-list (NEVER `exec` with user input)
- [ ] HTML: framework auto-escape; `textContent` over `innerHTML`; sanitiser library if HTML must be rendered
- [ ] URL params: `URLSearchParams`, `encodeURIComponent`
- [ ] Regex: not constructed from raw user input (ReDoS risk)
- [ ] `eval` / `Function()` constructor / `setTimeout(string)` / `setInterval(string)`: NEVER with user input
- [ ] LDAP / NoSQL / GraphQL injection considered for those stacks

### Cryptography

- [ ] No MD5, SHA1, DES, RC4 for security purposes
- [ ] AES-GCM or ChaCha20-Poly1305 for symmetric encryption (NOT AES-CBC without HMAC)
- [ ] RSA ≥ 2048-bit, EC ≥ 256-bit
- [ ] Random sources: `crypto.randomBytes` (Node), `secrets` (Python), `os.urandom`, `SecureRandom` (Java)
- [ ] Constant-time comparison for secrets: `crypto.timingSafeEqual`, `hmac.compare_digest`, `MessageDigest.isEqual`
- [ ] TLS 1.2+ only, modern cipher suites
- [ ] Certificate validation NOT disabled

### Secrets

- [ ] No secrets in source code (search with `gitleaks detect`)
- [ ] No secrets in commit history (`gitleaks` scans full history)
- [ ] No secrets in test fixtures, mocks, or comments
- [ ] Secrets via environment / vault, never logged
- [ ] `.env` in `.gitignore`; `.env.example` committed with placeholder values
- [ ] Error responses don't leak secret values or shapes
- [ ] Secrets rotated when exposure suspected

### Transport

- [ ] HTTPS only in production; redirect HTTP → HTTPS
- [ ] HSTS header with reasonable `max-age` (e.g., 1 year)
- [ ] Secure / HttpOnly / SameSite=Strict (or Lax) on session cookies
- [ ] CSP strict: no `unsafe-inline`, no `unsafe-eval`, narrow `script-src`
- [ ] CORS narrow: explicit origins, not `*`
- [ ] Subresource integrity for CDN scripts

### Data at rest

- [ ] Sensitive fields encrypted at the column level (or DB-level encryption)
- [ ] Backups encrypted
- [ ] Backup retention defined; old backups purged
- [ ] PII identified; deletion path implemented (GDPR / CCPA compliance)

### Dependencies

- [ ] `npm audit --audit-level=high` returns 0 issues
- [ ] `pip-audit` returns 0 issues
- [ ] `cargo audit` returns 0 issues
- [ ] New dependencies vetted: maintainer count, release recency, postinstall scripts
- [ ] Lock files committed (`package-lock.json`, `Pipfile.lock`, `Cargo.lock`)
- [ ] Renovate / Dependabot enabled

### Outbound calls (SSRF)

- [ ] URLs validated (only http/https; no `file://`, `gopher://`, etc.)
- [ ] Private IP ranges blocked: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `127.0.0.0/8`, `169.254.0.0/16`, IPv6 equivalents
- [ ] Redirects: limit count (3-5), re-validate each destination
- [ ] Outbound timeouts set
- [ ] Outbound calls logged

### Logging & monitoring

- [ ] Failed auth logged (IP, UA, attempted user)
- [ ] PII redacted from logs (emails partially, IPs hashed if needed)
- [ ] Tokens and passwords NEVER logged
- [ ] Sensitive data NOT in URL query parameters (logged, referer leak)
- [ ] Stack traces NOT returned to users in production
- [ ] Centralised log aggregation in production
- [ ] Alerts on auth-failure spikes, error-rate spikes, unusual outbound traffic

### Headers

- [ ] `Strict-Transport-Security`
- [ ] `Content-Security-Policy`
- [ ] `X-Frame-Options: DENY` or `frame-ancestors 'none'` in CSP
- [ ] `X-Content-Type-Options: nosniff`
- [ ] `Referrer-Policy: strict-origin-when-cross-origin` or stricter
- [ ] `Permissions-Policy` for unused features

### CSRF

- [ ] CSRF tokens on state-changing requests if using cookie auth
- [ ] SameSite cookies as primary defence
- [ ] Origin / Referer check on sensitive endpoints

### File operations

- [ ] User-provided paths resolved, then verified within allowed root
- [ ] Symlink attacks considered (resolve before check)
- [ ] Temp files in process-specific directory, cleaned up on exit
- [ ] No predictable temp filenames (e.g., `/tmp/upload`)

### Webhooks / signed callbacks

- [ ] Inbound webhook signature verified before any processing
- [ ] Signature comparison constant-time
- [ ] Replay protection (timestamp + nonce, or signature TTL)
- [ ] Webhook secret stored as a secret, not in code

### Serialisation

- [ ] Untrusted JSON → typed schema validation (zod, pydantic, serde with `deny_unknown_fields`)
- [ ] Untrusted YAML → safe loader only (`yaml.safe_load`, not `yaml.load`)
- [ ] Untrusted XML → external entities disabled
- [ ] Untrusted protobuf / pickle / marshal: do not deserialise across trust boundary

## Pre-deploy

- [ ] Pen-test or threat-model-walk through with `devils-advocate` sub-agent
- [ ] Security regressions added to test suite
- [ ] Runbook for incident response exists
- [ ] Rotation plan for the secrets touched by this release
- [ ] Backup of any data being migrated

## After deploy

- [ ] Monitor auth-failure rate for the first 24h
- [ ] Monitor error rate for the first 24h
- [ ] Monitor outbound traffic for unusual patterns
- [ ] Confirm security headers in production responses
- [ ] Re-run dependency audits in CI weekly

## Annual

- [ ] Penetration test (external or self)
- [ ] Review and rotate long-lived secrets
- [ ] Review access lists; remove inactive accounts
- [ ] Update threat model if product surface changed

## macOS-local tools

```bash
brew install --cask gitleaks    # secret scanning
brew install trivy              # vulnerability scanning
brew install cosign             # signing artifacts

# Quick spot checks:
curl -sIL https://your-site.com | grep -iE '(strict-transport|content-security|x-frame|x-content-type|referrer-policy)'
nmap -sV your-site.com           # port and version check (only your own infra!)
```

## When the checklist feels long

Most items are fast. The full walk-through for a small change is ~5 minutes; for a large change ~20 minutes. That cost is paid once. The cost of a breach is paid for months.
