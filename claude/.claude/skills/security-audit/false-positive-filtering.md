# False-Positive Filtering

Every candidate finding must pass this filter **before** going into the report. Read this in full before Phase 4.

## Hard exclusions — automatic drop

Drop any finding matching these patterns regardless of how confident you are:

1. **DoS / resource exhaustion** — Denial of Service, memory consumption, CPU exhaustion, file-descriptor leaks, ReDoS / regex DoS. Even if exploitable, out of scope.
2. **Rate limiting** — Absence of rate limiting is not a vulnerability for this audit.
3. **Secrets on disk** — Secrets/credentials at rest in `*.env`, `appsettings.*.json`, `*.config` files are out of scope (handled elsewhere). Hardcoded secrets in source **code** are still in scope.
4. **Non-security-critical input validation** — "Field X has no length check" without a proven security impact (XSS/SQLi/injection chain).
5. **CI/CD YAML hardening** — Only flag pipeline YAML when untrusted input directly influences pipeline execution or secrets are exposed in pipeline logs. General "should pin SHAs" → drop.
6. **General hardening** — "Should add CSP", "should use Argon2 instead of bcrypt at cost 10". Code isn't required to implement every best practice. Only flag concrete vulnerabilities.
7. **Theoretical race conditions / timing attacks** — Only report if concretely exploitable with a realistic attacker model.
8. **Outdated third-party libraries** — Managed by dependency-update tooling, not this audit. Exception: A03 supply-chain findings like unpinned base images or lockfile bypass.
9. **Test files** — Files that only run as part of unit/integration tests. Drop.
10. **Log spoofing** — Putting unsanitized user input in logs is not a vulnerability.
11. **SSRF with only path control** — SSRF is only valid if it controls **host or protocol**.
12. **User content in AI prompts** — Putting user content in an LLM system prompt is not, by itself, a vulnerability.
13. **Regex injection / regex DoS** — Not a vulnerability for this audit.
14. **Documentation findings** — Anything in `*.md` / `docs/**`. Drop.
15. **Lack of audit logging** — Pure "should log this event" findings → drop. (Bucket as A09 only when missing logs **concretely enable** an attack, e.g., no MFA-failure logging during a credential-stuffing exposure.)
16. **Client-side authz gaps** — Missing permission checks in JS/JSX/TSX code. Client code is not trusted. Only the server matters.
17. **Open redirects / tabnabbing / XS-Leaks / prototype pollution** — Drop unless chained into a concrete attack (e.g., OAuth code theft via open redirect at callback URL).

## Framework safety precedents — assume safe

The following are **assumed safe** unless you find a clear, named misuse:

1. **EF6 / EF Core parameterized queries** — LINQ queries, `SqlParameter` usage, `FromSqlInterpolated` (which uses parameters). Only flag raw SQL via `SqlQuery(string)` with concatenation/interpolation, `ExecuteSqlCommand(string)` with concatenation, or `string.Format` into a query.
2. **React / Vue / Svelte / Angular templating** — Auto-escapes interpolations. Only flag `dangerouslySetInnerHTML`, `v-html`, `{@html ...}` (Svelte), `[innerHTML]` (Angular) with attacker-controlled data.
3. **ASP.NET MVC model binding** — Generally safe. Flag only:
   - `[AllowAnonymous]` on sensitive endpoints
   - Missing `[ValidateAntiForgeryToken]` on state-changing POSTs where CSRF is a concrete risk (i.e., cookie-based auth, no SameSite, mutation endpoint)
4. **Django ORM** — Safe. Only flag `.raw()`, `.extra()` with concatenation, or `connection.cursor().execute()` with string formatting.
5. **Rails ActiveRecord** — Safe. Only flag `where("col = #{x}")` or `find_by_sql` with interpolation.
6. **Parameterized prepared statements in any language** — Safe.
7. **UUIDs** — Assume unguessable. Don't require validation of UUID format for authz.
8. **Environment variables / CLI flags** — Trusted inputs in a secure deployment. Attacks that require the attacker to set an env var are invalid.
9. **Logging URLs** — Safe. Logging high-value secrets in plaintext **is** a vulnerability.

## SignalR / WebSockets — when to flag

Flag missing `[Authorize]` (or equivalent) on **hub methods** or **socket handlers** that:
- Perform sensitive operations (write to DB, send messages on behalf of others, change permissions)
- Expose sensitive data (user PII, internal IDs, other tenants' data)

Don't flag missing auth on hubs that only broadcast public data.

## Signal quality criteria — for findings that survive the hard filter

For every finding, confirm:

1. **Concrete attack path** — Can you write the exact HTTP request, message, or input the attacker sends? If no, drop.
2. **Real risk vs. theoretical** — Is there a realistic scenario where this fires in production? If only under contrived conditions, drop.
3. **Specific location** — File + line + the exact code excerpt. No "somewhere in the controllers". If you can't pinpoint it, drop.
4. **Actionable fix** — Can you describe the specific code change? If the fix is "review the architecture", drop.

## Confidence scoring rubric (1–10)

Used in the Phase 4 sub-agent pass.

| Score | Meaning |
|-------|---------|
| 9–10 | PoC-grade. Exploit path traced end-to-end, no plausible mitigation in the surrounding code. |
| 8 | Recognized vulnerability pattern, clear sink and source, minor preconditions documented. |
| 6–7 | Suspicious pattern, partial trace, needs investigation. **Below threshold — drop.** |
| 4–5 | Indication only, no confirmed path. Drop. |
| 1–3 | Likely false positive. Drop. |

**Keep only findings scored 8 or higher.**

## Medium-severity findings — extra bar

Medium findings only make the report when they are **obvious and concrete**. Borderline mediums → drop. Better to ship a tight High-only report than a noisy mixed one.
