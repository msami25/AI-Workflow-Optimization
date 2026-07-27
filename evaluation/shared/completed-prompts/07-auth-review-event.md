# Completed Prompt - Template 7: auth-review-event

## Shared project context

```text
Project: PromptEvaluation
Framework: .NET 8
Application type: ASP.NET Core Web API
Architecture: Layered API: controllers, services, EF Core DbContext, DTOs, centralized exception handling
Database: SQLite
ORM: EF Core 8
Test stack: xUnit, Moq, WebApplicationFactory, SQLite in-memory
Existing conventions: Nullable enabled, file-scoped namespaces, PascalCase public members, async methods suffixed Async

Work only within the requested scope. Preserve existing behavior unless a
change is explicitly requested. Do not invent files, methods, packages, or
requirements. Do not expose secrets. First state assumptions and the files you
need to inspect. After implementation, list changed files, verification
commands, risks, and any remaining work.
```

## Task

```text
Act as a .NET application security reviewer. Review and harden this
authentication/authorization flow:

Auth flow: JWT bearer access tokens with rotating refresh tokens in Secure, HttpOnly cookies
Roles/policies: Admin and User; Event create/update/delete require Admin
Protected endpoints: POST, PUT, and DELETE /api/events require Admin; GET endpoints are anonymous
Access/refresh token location: Bearer access token in Authorization header; refresh token in Secure, HttpOnly cookie
Allowed frontend origin: https://localhost:5173

Inspect the supplied Program.cs, auth service, token service, controllers,
configuration, and frontend HTTP client before proposing changes.

Check:
- JWT issuer, audience, signature, lifetime, clock skew, and key length.
- Access-token expiry and refresh-token rotation/revocation/reuse detection.
- Whether role claims use the same claim type expected by authorization.
- Explicit authorization on every state-changing/admin endpoint.
- Secure, HttpOnly, SameSite, and HTTPS cookie settings where cookies are used.
- Exact CORS origins; never combine wildcard origins with credentials.
- Rate limiting and generic login errors to reduce brute force/user discovery.
- Secret storage outside committed configuration.
- Logout/session invalidation and audit logging without token leakage.

Output:
1. Findings table: severity, evidence, risk, recommended fix.
2. Minimal patch plan ordered by risk.
3. Code changes only for confirmed issues.
4. Unit/integration tests proving 401 vs 403, role enforcement, expired token,
   invalid signature, refresh rotation, and revoked token behavior.
5. Commands and manual verification steps.

Do not claim compliance or security perfection. State what was not inspected.
Acceptance criteria: anonymous, authenticated, and authorized cases are tested;
no secret/token value appears in source, response bodies, or logs.
```
