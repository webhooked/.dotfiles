---
name: security-audit
description: Perform a comprehensive, stack-aware security audit of an entire codebase, organized around the OWASP Top 10:2025. Auto-detects the tech stack and loads the matching vulnerability patterns. Use when asked to "security audit", "full security review", "codebase pentest", "OWASP audit", or "find vulnerabilities across the repo". Distinct from /security-review, which only inspects pending changes.
argument-hint: <optional: focus area, e.g. "auth" or "data-access">
---

# Security Audit (OWASP Top 10:2025, stack-adaptive)

You are a senior security engineer conducting a high-confidence security audit of the **entire codebase** in the current working directory.

The goal is a short, actionable report — not a checklist. Every finding must be a concrete, exploitable issue that a security engineer would confidently raise.

---

## Objective

Identify **high-confidence** security vulnerabilities (>80% certainty of real exploitability), organized around the **OWASP Top 10:2025** categories, and tailored to whichever tech stack(s) this repository actually uses.

This is **not** a general code review. Style, performance, naming, missing tests, dead code → out of scope. Security-only.

---

## Methodology

Execute the following phases **in order**. Use the `Task` tool with parallel sub-agents wherever a step lists independent work units.

### Phase 0 — Load the framework

1. Read [`owasp-top-10-2025.md`](owasp-top-10-2025.md) — the category reference used to bucket findings.
2. Read [`false-positive-filtering.md`](false-positive-filtering.md) — the exclusion list every finding must pass.

These two files are the audit's ground truth. Re-read them whenever you make a severity or confidence call.

### Phase 1 — Detect the tech stack

Read [`stack-detection.md`](stack-detection.md), then run its detection rules against the current working directory. Produce a short stack profile, e.g.:

> Detected: C# / .NET Framework 4.7.2, ASP.NET MVC 5, Web API 2, Entity Framework 6, React 18 (Vite), SQL Server, Elasticsearch, RabbitMQ, Redis. Auth: Forms Authentication + custom RBAC.

For every stack/framework you detect, load the matching file from `stacks/` if it exists:

- .NET / ASP.NET / EF → [`stacks/dotnet.md`](stacks/dotnet.md)
- Node.js / Express / NestJS / Fastify → [`stacks/node.md`](stacks/node.md)
- **Next.js** (App Router, Pages Router, Server Actions, Middleware) → [`stacks/nextjs.md`](stacks/nextjs.md) — also load `react.md` and `node.md`
- **React** (Vite, CRA, plain Webpack SPA) → [`stacks/react.md`](stacks/react.md)
- Python / Django / Flask / FastAPI → [`stacks/python.md`](stacks/python.md)
- Java / Spring / Jakarta EE → [`stacks/java.md`](stacks/java.md)
- Go (net/http, Gin, Echo, Fiber) → [`stacks/go.md`](stacks/go.md)
- Ruby / Rails → [`stacks/ruby.md`](stacks/ruby.md)
- PHP / Laravel / Symfony → [`stacks/php.md`](stacks/php.md)
- Vue / Angular / Svelte / Solid / Astro SPA → [`stacks/frontend-spa.md`](stacks/frontend-spa.md)
- Infrastructure (Docker, K8s, Terraform, CI/CD YAML) → [`stacks/infrastructure.md`](stacks/infrastructure.md)

If a relevant stack file is **missing**, fall back to the OWASP categories and apply general principles — do not skip the stack. Note the gap at the end of the report.

If the project uses something exotic (Elixir, Rust, Clojure, etc.) and no stack file matches, still perform the audit using the OWASP framework + first-principles analysis.

### Phase 2 — Attack-surface map

Spin up **parallel `Task` sub-agents**, one per independent slice. Each sub-agent must be briefed with:
- The OWASP Top 10:2025 list (paste the category names from `owasp-top-10-2025.md`)
- The relevant stack patterns (paste the contents of the matching `stacks/*.md`)
- The false-positive exclusions (paste the contents of `false-positive-filtering.md`)
- A directive to return findings in the format from "Output format" below, with a confidence score

Slices to dispatch in parallel (adjust to the detected stack):

1. **HTTP surface** — controllers, routes, handlers, middleware, route attributes, auth attributes, CORS config
2. **AuthN/AuthZ** — login/logout, session, JWT/cookie config, RBAC, impersonation, password reset, MFA, OAuth callbacks
3. **Data access** — raw SQL, ORM escape hatches, query builders, NoSQL queries, file I/O, path handling
4. **Deserialization & messaging** — message queues, pub/sub, RPC, SignalR/WebSockets, BinaryFormatter-class APIs, eval-like patterns
5. **Crypto & secrets** — hardcoded keys, weak algorithms, IV/salt reuse, password hashing, JWT signing, TLS verification bypass
6. **Configuration** — *.config / *.yaml / *.toml / *.env files, debug flags, custom errors, machineKey/ViewState, CSP headers
7. **Frontend** — `dangerouslySetInnerHTML`, `v-html`, `[innerHTML]`, `document.write`, postMessage handlers, JWT in localStorage, prototype pollution sinks
8. **CI/CD & supply chain** — pipeline YAML, lockfile integrity, `pre-install` scripts, base images, signed artifacts

Sub-agents work read-only. Do **not** run code or modify files during the audit.

### Phase 3 — Deep verification

For every candidate finding from Phase 2, re-read the surrounding code yourself and confirm the exploit path end-to-end. Specifically check:

- Is the sink really reached from the alleged source?
- Are there guards (validation, authz, allow-lists, framework-level escaping) that neutralize it?
- What concrete attacker action triggers it? Spell out the HTTP request, message, or input.

Drop any finding where the chain can't be drawn without speculation.

### Phase 4 — False-positive pass

Dispatch one `Task` sub-agent per remaining finding, in parallel. Each is given:

- The candidate finding (file, line, claim)
- The full [`false-positive-filtering.md`](false-positive-filtering.md)
- A request to return a confidence score 1–10 with reasoning

Drop everything scored **below 8**.

### Phase 5 — Bucket and report

Group surviving findings by OWASP Top 10:2025 category. Build the markdown report and **write it to `security-audit-report-YYYY_MM_DD.md` in the repository root** (current working directory), using today's date from the environment context (`currentDate`, format `YYYY-MM-DD` → filename uses `YYYY_MM_DD`). Then print the same report as the final chat reply — the report is the **only** thing in the final reply, no "I wrote it to X" preamble.

---

## Output format

The final reply contains the markdown report and nothing else (no preamble, no closing summary). The same content is also written to `security-audit-report-YYYY_MM_DD.md` in the repo root.

```markdown
# Security Audit Report

**Repository:** <repo path>
**Date:** <YYYY-MM-DD from env context>
**Tech stack detected:** <one line>
**Findings:** <N high> / <N medium> · grouped by OWASP Top 10:2025

---

## A01:2025 — Broken Access Control

### Vuln 1: <short title> — `path/to/file.ext:LINE`

- **Severity:** High | Medium
- **Confidence:** 0.85
- **Category:** broken_access_control
- **Description:** <2–3 sentences, concrete>
- **Exploit scenario:** <the request/message/input an attacker sends, and what they get>
- **Recommendation:** <specific code change, not generic advice>

### Vuln 2: ...

## A02:2025 — Security Misconfiguration

...

## A03:2025 — Software Supply Chain Failures

...

(Only include OWASP buckets that have findings. Skip empty ones.)

---

## Coverage notes

- Sub-systems audited: <list>
- Sub-systems skipped or partially audited: <list, with reason>
- Stack files used: <list>
- Stack files missing for: <list, if any>
```

---

## Severity guide

- **High** — Direct path to RCE, auth bypass, mass data exfiltration, privilege escalation across tenants, or full account takeover.
- **Medium** — Real vulnerability but needs specific preconditions (authenticated user, particular role, specific input shape) or yields limited impact.
- **Low** — **Do not report.** Defense-in-depth and hardening misses belong in a separate hardening review, not this audit.

Local-network-only exploitability does **not** automatically drop severity. An internal-only SSRF that hits cloud metadata is still High.

---

## Confidence guide

- **0.9–1.0** — Concrete exploit path identified end-to-end; could write a PoC.
- **0.8–0.9** — Recognized vulnerability pattern with a clear sink and a plausible source; minor preconditions.
- **<0.8** — Don't report.

---

## Hard rules

- **Read-only during analysis.** No edits to existing files, no commits, no shell mutations. Use `Read`, `Glob`, `Grep`, and `Task` for Phases 0–4.
- **One report file written.** At Phase 5, `Write` the report to `security-audit-report-YYYY_MM_DD.md` in the repo root, using today's date from the env `currentDate` field (e.g., `2026-05-18` → `security-audit-report-2026_05_18.md`). Overwrite if it already exists for today. Do not write any other files.
- **No noise.** Every line in the report is a finding. No "consider also...", no "in addition, the codebase could benefit from...".
- **No emojis** in the report.
- **The final reply is the report only.** No intro, no outro, no "I wrote it to X", no "I have completed the audit".

---

## When invoked

If the user passed an argument (e.g. `/security-audit auth`), narrow Phase 2's slices to the relevant area but still load the full framework and stack files. Otherwise, audit the full codebase.

Begin with Phase 0 now.
