---
name: api-and-interface-design
description: Design any public surface — HTTP API, GraphQL schema, CLI, library export, gRPC contract, event payload — with explicit thinking about evolution, backward compatibility, error model, and discoverability. Use whenever a change introduces or modifies a public interface.
requires:
  - .specs/<feature>/spec.md exists
produces:
  - Interface definition (OpenAPI / GraphQL schema / CLI spec / type signatures)
  - An ADR documenting the design choices (docs/adr/NNNN-*.md)
phase: build / design
adapted_from: addyosmani/agent-skills (MIT)
---

# API and Interface Design

> Every interface you ship is forever, in the sense that someone will depend on its current behaviour (Hyrum's Law). Design as if you cannot change it; change it deliberately when you must.

## When to use

- New HTTP/GraphQL/gRPC endpoint or schema field
- New CLI command or flag
- New exported function, class, or type from a library
- New event in a pub/sub or queue
- Change to any of the above

## Process

### Step 1 — Name the surface

Identify exactly what you're designing. "Auth API" is too broad; "POST /auth/refresh-token" is specific.

### Step 2 — Identify consumers

Who will call this? Internal teams, public users, both? For each consumer:

- What's their expected pace of change?
- What versioning compatibility do they need?
- How will they discover this interface? (docs, autocomplete, type system, runtime introspection)

### Step 3 — Decide on the contract dimensions

Walk through these explicitly:

1. **Name**: imperative verb for action endpoints, noun for resource endpoints. Match house style.
2. **Inputs**: shape, validation, optional vs required, defaults.
3. **Outputs**: success shape, error shape, status codes / error codes.
4. **Errors**: enumerate. Each error must be detectable and recoverable separately. Don't lump into "400 Bad Request".
5. **Idempotency**: is calling twice safe? Document.
6. **Side effects**: what state changes? What gets logged? What emits events?
7. **Limits**: rate limits, payload sizes, timeouts. Document with concrete numbers.
8. **Authentication**: who can call this, how is it authorised.
9. **Versioning strategy**: URL path, header, query parameter, or "we'll break compat with notice".

### Step 4 — Sketch in the schema language

Use the project's schema language. Examples:

```yaml
# OpenAPI 3.1
paths:
  /auth/refresh-token:
    post:
      operationId: refreshAuthToken
      summary: Exchange a valid refresh token for a new access token.
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [refresh_token]
              properties:
                refresh_token: { type: string, minLength: 20 }
      responses:
        '200':
          description: New access token issued.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TokenPair'
        '401':
          description: Refresh token invalid, expired, or revoked.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/ApiError' }
```

For libraries:

```typescript
/** Exchange a valid refresh token for a new access-refresh pair.
 *  Idempotent: calling with the same token twice within the rotation window
 *  returns the same pair. Outside the window: 401.
 */
export async function refreshAuthToken(
  input: { refreshToken: string }
): Promise<Result<TokenPair, AuthError>>;
```

### Step 5 — Error taxonomy

For every error path, define:

| Code | Meaning | Recoverable how? |
|---|---|---|
| `auth.refresh_expired` | The token's TTL has passed | User must re-login |
| `auth.refresh_revoked` | The token was explicitly invalidated | User must re-login |
| `auth.refresh_unknown` | Token not found in store | User must re-login (signal: possible attack) |
| `rate.exceeded` | Caller exceeded refresh rate limit | Wait `Retry-After` seconds |

Don't ship `400 Bad Request` with no further detail. The error model is part of the contract.

### Step 6 — Backward-compatibility plan

If the change is to an existing surface, decide:

- **Additive**: new optional field, new endpoint. Safe.
- **Behavioural**: same shape, different behaviour. Often breaking even if schema unchanged.
- **Breaking**: removed field, changed type, changed semantics. Needs version bump.

For breaking, define the migration path. See `62-deprecation-and-migration`.

### Step 7 — ADR

Write `docs/adr/NNNN-<surface-name>.md`:

```markdown
# ADR-NNNN: <Surface name>

- Status: Proposed | Accepted | Superseded
- Date: <ISO>
- Spec: .specs/<feature>/spec.md

## Context
<Why does this surface need to exist, what alternatives in shape were considered?>

## Decision
<What we ship: endpoint, name, input, output, errors.>

## Consequences
<Forward compatibility, what we commit to, what we explicitly refuse.>
```

### Step 8 — Devils-advocate

Invoke `devils-advocate` with the schema + ADR as input. Especially relevant for public surfaces; the cost of objections caught here is enormous compared to caught post-launch.

## Rationalizations

| Rationalization | Refutation |
|---|---|
| "It's internal, we can change it anytime" | Internal becomes external by accident (a contractor, a side project, a public demo). Design as if external. |
| "Errors can be a single 400" | Caller can't distinguish a fixable error from a permanent one. They retry, fail, retry, fail. Granular errors save customers. |
| "We'll version when we need to" | You need to now; "v1" in the URL or accept-header is the cheapest insurance you can buy. |
| "Idempotency is overkill" | Until a retry storm doubles your charges. Document the property explicitly. |

## Red Flags

- Endpoints named after database tables (`/users`) when the operation is semantic (`/profile/refresh`)
- Generic `data` blobs in responses (untyped, undocumented)
- 200 OK with `{"error": "..."}` body — status code lies
- No rate-limit documentation
- No timeout documentation
- Identical-looking endpoints with subtly different semantics

## Verification

- [ ] Schema written in project's schema language (OpenAPI / GraphQL / type signatures)
- [ ] Each error has a code, meaning, and recoverability note
- [ ] Idempotency documented
- [ ] Rate-limit / timeout / payload-size documented with numbers
- [ ] ADR exists in `docs/adr/`
- [ ] Devils-advocate output captured

## Solo-Developer Adaptation

You will be the future consumer of this interface. Design as if the future-you forgot why current-you did it this way — because they will have. Strong ADRs save future-you, who is alone with the consequences.

## macOS Notes

OpenAPI tooling:

```bash
brew install --cask insomnia          # GUI for try-out + spec validation
npm i -g @redocly/cli                  # OpenAPI lint + bundle + diff
redocly lint openapi.yaml
redocly diff openapi-v1.yaml openapi-v2.yaml  # show breaking changes
```

## Attribution

Adapted from `addyosmani/agent-skills` (MIT, skill `api-and-interface-design`).
