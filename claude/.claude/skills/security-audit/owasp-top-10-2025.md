# OWASP Top 10:2025 — Reference

The 2025 list (eighth edition, also in effect for 2026) was assembled from 589 CWEs across 248 categories. Two new categories: **A03 Software Supply Chain Failures** and **A10 Mishandling of Exceptional Conditions**. Use these buckets to organize the audit report.

| ID | Title | What it covers (1-liner) |
|----|-------|---------------------------|
| **A01:2025** | Broken Access Control | Users acting outside their permissions: IDOR, missing authz checks, force-browsing, JWT/cookie tampering, CORS misuse, privilege escalation, cascading-permission bypass. |
| **A02:2025** | Security Misconfiguration | Insecure defaults, debug mode in prod, verbose errors, default credentials, missing security headers, open cloud buckets, permissive CORS, exposed admin UIs. |
| **A03:2025** | Software Supply Chain Failures | Compromise of dependencies, build systems, lockfiles, container base images, package registries, CI runners, signing keys. (Expanded successor to "Vulnerable and Outdated Components".) |
| **A04:2025** | Cryptographic Failures | Weak/broken algorithms (MD5, SHA1, DES, ECB, RC4), hardcoded keys, fixed IVs/salts, low PBKDF2/bcrypt cost, plaintext storage of secrets, missing TLS, certificate validation bypass. |
| **A05:2025** | Injection | SQL/NoSQL injection, command injection, LDAP/XPath/SSRF-via-URL, server-side template injection, header injection, XSS (reflected/stored/DOM), XXE, OS command construction from user input. |
| **A06:2025** | Insecure Design | Missing rate limits on auth, lack of trust boundaries, business-logic flaws, predictable secrets, password reset oracles, dangerous-by-design APIs. |
| **A07:2025** | Authentication Failures | Credential stuffing exposure, weak password rules, missing MFA, broken session management, predictable session IDs, JWT `alg=none`, password recovery weaknesses. |
| **A08:2025** | Software or Data Integrity Failures | Unsafe deserialization (`BinaryFormatter`, `pickle`, `ObjectInputStream`, etc.), insecure CI/CD update channels, unsigned artifacts, auto-update without signature verification, prototype pollution leading to gadget chains. |
| **A09:2025** | Security Logging & Alerting Failures | Audit logs missing for security-relevant events. **Note:** the false-positive filter excludes pure "lack of logging" findings — only flag when missing logs concretely enable an attack (e.g., no MFA-failure logging during credential stuffing). |
| **A10:2025** | Mishandling of Exceptional Conditions | "Failing open" on errors, swallowed exceptions around auth/authz checks, error paths that bypass validation, partial-failure states that leave systems in an unauthenticated-but-trusted mode. |

---

## Mapping common vulnerability classes to OWASP IDs

When in doubt, use this table. If a finding spans two categories, pick the one that best describes the **root cause**, not the symptom.

| Finding pattern | Bucket |
|-----------------|--------|
| Missing `[Authorize]` / route lacks auth check | A01 |
| User can pass another user's ID and read their data (IDOR) | A01 |
| `returnUrl` open redirect after login | A01 |
| Tenant isolation bypass | A01 |
| `customErrors="Off"`, `debug="true"` in production config | A02 |
| Permissive `Access-Control-Allow-Origin: *` with credentials | A02 |
| Missing CSP / HSTS / `Secure` cookie flag | A02 |
| `npm install` from unverified registry / typosquat | A03 |
| Unpinned base image with `latest` tag | A03 |
| CI pipeline pulls a script via `curl \| bash` | A03 |
| Hardcoded AES key / fixed IV / fixed salt | A04 |
| Password hashed with MD5/SHA1 / single-round | A04 |
| TLS cert validation disabled | A04 |
| Raw SQL via `SqlQuery()` / string-interpolated query | A05 |
| `Process.Start` / `exec` / `system` with user input | A05 |
| `eval` / `new Function` / Razor `@Html.Raw` | A05 |
| XXE: `XmlReader` with DTD enabled | A05 |
| `dangerouslySetInnerHTML` / `v-html` with untrusted data | A05 |
| Password reset token predictable / non-expiring | A06 |
| Business logic: negative quantity, race in transfer | A06 |
| Forms Auth cookie not `HttpOnly` / not `Secure` | A07 |
| JWT accepts `alg: none` or weak HS256 secret | A07 |
| Session ID predictable / regenerated on privilege change missing | A07 |
| `BinaryFormatter.Deserialize` on user data | A08 |
| Python `pickle.loads` / Java `ObjectInputStream` on untrusted bytes | A08 |
| Auto-update without signature check | A08 |
| Generic `catch (Exception) { /* swallow */ }` around an auth check that lets the request continue | A10 |
| `if (auth.Check()) {} else { /* nothing — fall through */ }` | A10 |

---

## What's **not** in the 2025 list (but commonly conflated)

- **SSRF** — folded into A05 Injection / A10 in some interpretations. Only flag if it controls **host or protocol**, not just path. (Per false-positive filter.)
- **CSRF** — folded into A01 Broken Access Control. Only flag on state-changing POSTs where the framework doesn't already mitigate.
- **Open redirects** — defense-in-depth, very low signal. Only flag when chained into a real attack (e.g., OAuth code theft).
- **DoS / rate limiting** — explicitly excluded.

---

## Two-new-category emphasis (vs 2021)

These are the most likely-to-be-missed-by-old-checklists categories. Pay them extra attention:

### A03:2025 — Software Supply Chain Failures
Look at:
- Lockfile presence and integrity (`package-lock.json`, `yarn.lock`, `Pipfile.lock`, `composer.lock`, `Gemfile.lock`, `go.sum`)
- Dockerfiles: `FROM image:latest`, `curl ... | bash`, unverified `wget`
- CI/CD: pulling scripts from external URLs, `actions/checkout@main`, unpinned third-party actions
- Private package registries: missing auth, fallback to public registry (dependency confusion)
- Build artifacts: unsigned releases, missing SBOM

### A10:2025 — Mishandling of Exceptional Conditions
Look at:
- Auth/authz wrapped in `try { ... } catch { /* log and continue */ }`
- Error handlers that swallow exceptions and return success
- "Failing open" defaults — `if (!CanCheck()) return Allow;`
- Partial state: payment captured but order not recorded, etc.
- `finally` blocks that release locks/permissions before validation completes
