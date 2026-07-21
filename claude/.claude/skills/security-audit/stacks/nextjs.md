# Next.js — Audit Patterns

Covers Next.js 12 (Pages Router), 13/14/15 (App Router), Server Components, Server Actions, Route Handlers, Middleware, and `getServerSideProps` / `getStaticProps`. Pair with `stacks/react.md` for client-component issues, and with the chosen ORM/DB stack file for data-access concerns.

Next.js is full-stack: a finding can live on the server (App Router route handler, server action) or the client (component). **Always note which runtime** in the finding — Server, Edge Middleware, or Client.

## A01 Broken Access Control

### Server Actions (`'use server'`)
- **Public Server Action without auth check** — any function marked `'use server'` becomes a callable POST endpoint reachable by anyone, even if the importing component is "private". The component-level auth gate **does not** protect the action.
  ```ts
  // app/actions.ts
  'use server';
  export async function deleteUser(id: string) {
    // BAD — no session check, callable by anyone
    await db.user.delete({ where: { id } });
  }
  ```
  Mitigation: every Server Action must call `auth()` / `getServerSession()` / equivalent and verify authorization on its own arguments.
- **Server Action using `headers()` / `cookies()`** to read identity but **trusting client-provided IDs** in arguments (IDOR).

### Route Handlers (`app/api/**/route.ts`)
- **Handler without auth check** — App Router route handlers are public by default. Look for `export async function POST/PATCH/DELETE` with no `getServerSession` / `auth()` call.
- **Handler reading `searchParams` or path params and querying the DB by ID** without scoping to the authenticated user (IDOR).

### Pages Router API routes (`pages/api/**`)
- Same issue — `export default async function handler(req, res)` without `getSession(req)` on mutating verbs.

### Middleware (`middleware.ts`) gaps
- **`matcher` config excluding sensitive paths** — a `matcher: ['/((?!api|_next/static).*)']` skips `/api`, leaving API routes unprotected if the only auth check was the middleware.
- **Middleware that only sets headers but doesn't `return NextResponse.redirect()` / `NextResponse.rewrite()` on auth failure** — request proceeds without redirection.
- **`NextResponse.next()` returned in an unauthenticated branch** — auth check effectively bypassed.

### Server Components leaking authz state
- **Server Component fetches data without filtering by session user** and renders it. The component is rendered server-side but the **data shape** ships to the client. Look for:
  ```tsx
  export default async function Page({ params }) {
    const post = await db.post.findUnique({ where: { id: params.id } });
    // BAD — no ownership check
    return <PostView post={post} />;
  }
  ```

### Open redirect via `next` parameter
- **`redirect(searchParams.next)`** without allow-list — `redirect()` from `next/navigation` will happily send users to external URLs. Especially dangerous on login callback pages.

## A02 Security Misconfiguration

### `next.config.js` / `next.config.mjs`
- **`images.domains: ['*']`** or `images.remotePatterns` with wildcard hostname — SSRF via `/_next/image?url=...` (see A05).
- **`async rewrites()` proxying user-controlled paths** to internal services:
  ```js
  rewrites: async () => [{ source: '/proxy/:path*', destination: 'http://internal/:path*' }]
  ```
  An attacker hitting `/proxy/admin` reaches internal admin endpoints.
- **`async redirects()` with user-controlled destination** — open redirect at config level.
- **`async headers()` setting permissive CORS** — same `*` + credentials issue as elsewhere.
- **`experimental.serverActions.allowedOrigins`** not set in Next 14+ where Server Actions are enabled — CSRF surface for Server Actions called from foreign origins.
- **`reactStrictMode: false`** — not a vulnerability; drop.
- **`output: 'export'`** combined with code that uses Server Actions or API routes — those won't work, but not a security issue.

### Environment variable exposure
- **`NEXT_PUBLIC_*` variables containing secrets** — `NEXT_PUBLIC_STRIPE_SECRET`, `NEXT_PUBLIC_API_KEY`, `NEXT_PUBLIC_DB_URL`. Any env var prefixed `NEXT_PUBLIC_` is **inlined into the client bundle**. Treat as if it's in the browser console.
- **Importing a server-only module from a client component** — Next 13+ has `import 'server-only'` and `import 'client-only'` guards. Modules that read `process.env.SECRET` and then get imported into a `'use client'` component will inline that secret. Look for shared utility files imported from both runtimes.

### Build / runtime
- **`x-powered-by: Next.js` header** — `poweredByHeader: true` (default). Hardening, drop.
- **Debug overlay in production** — usually only enabled in dev, but flag if `NODE_ENV=development` is reachable in deployed config.

## A03 Software Supply Chain Failures

- **Vercel deploy hooks committed** as URLs in code — anyone with the URL can trigger deploys.
- **Custom `next.config.js` `webpack` block** that pulls remote loaders or plugins via `require('https://...')` (very rare, but a clear finding).
- See `stacks/node.md` A03 for general npm supply-chain patterns.

## A04 Cryptographic Failures

- **`crypto.randomBytes` vs `Math.random`** — same as Node.js. Server Actions / API routes that generate tokens with `Math.random` are a clear finding.
- **NextAuth.js / Auth.js `secret`** hardcoded or set to `"secret"`. The `secret` signs JWT session cookies; weak value = forge-able sessions.
- **Custom JWT verification in middleware** without algorithm allow-list:
  ```ts
  jwt.verify(token, secret)  // BAD — accepts any alg
  jwt.verify(token, secret, { algorithms: ['HS256'] })  // OK
  ```

## A05 Injection

### SSRF via Image Optimization
**The big Next.js-specific finding.** The `/_next/image?url=...` endpoint fetches the URL server-side to optimize it. If `images.domains` or `images.remotePatterns` is too permissive, this becomes an SSRF primitive.

- **`domains: ['*']`** or any wildcard — full SSRF (host + protocol controlled).
- **`remotePatterns: [{ hostname: '**' }]`** — same.
- **`remotePatterns: [{ hostname: 'user-content.example.com' }]`** where `user-content.example.com` resolves to the same VPC as production services — partial SSRF.

Per the FP filter, SSRF is only valid when host or protocol is controllable. Image Optimization SSRF gives **both**, so it's always flaggable when domains are too open.

### Server-side `fetch` in Route Handlers / Server Components
- **`fetch(searchParams.url)`** in a route handler — SSRF.
- **`fetch(\`https://api.example.com/\${params.id}\`)`** where `params.id` can contain `../` — path manipulation, lower signal unless it crosses an auth boundary on the upstream API.

### SQL injection (server-side)
- Server Actions and Route Handlers run Node.js. Refer to `stacks/node.md` A05 SQL injection patterns. Prisma is generally safe (parameterized); `prisma.$queryRawUnsafe` and `$executeRawUnsafe` are the unsafe variants.
- **Prisma `$queryRawUnsafe(query)`** with concatenation — SQL injection.
- **Drizzle ORM `sql.raw(...)`** with user input — SQL injection.

### XSS (client + server)
- **Server Component returning `<div dangerouslySetInnerHTML={{ __html: data }} />`** — same sink as client React, but rendered server-side. Still XSS.
- **`response.write(userInput)`** in a route handler returning `text/html`.

### Command injection
- Server Actions / Route Handlers using `child_process.exec` with concatenated user input. See `stacks/node.md` A05.

## A06 Insecure Design

### CSRF on Server Actions
Server Actions are POST endpoints. Next.js 14+ has built-in same-origin protection via `Origin` header check, but:
- **`experimental.serverActions.allowedOrigins`** set too permissively (e.g., `['*']`) — disables the protection.
- **Older Next.js (13.4–13.5)** had weaker CSRF handling for Server Actions — flag if pinned to those versions and Server Actions are used.

### Caching auth-gated content
- **`fetch(..., { cache: 'force-cache' })`** with `Authorization` header — cached responses can be served to other users.
- **`unstable_cache(fn, [key], { revalidate })`** without a user-scoped key, wrapping a function that returns user-specific data — cross-user data leak.
- **`export const dynamic = 'force-static'`** on a page that displays user-specific data — the rendered HTML for one user becomes everyone's.

## A07 Authentication Failures

### NextAuth.js / Auth.js
- **`secret` missing or default** — required in production for JWT-signed sessions.
- **`session: { strategy: 'jwt' }`** with no `maxAge` — sessions never expire.
- **Custom `callbacks.jwt` / `callbacks.session`** that pulls user data without re-validating against the DB — stale role bypass after role change.
- **`providers: [CredentialsProvider({...})]`** with `authorize()` that returns the user object without password verification or with a timing-leaky comparison.
- **`pages.signIn` redirect with user-controlled `callbackUrl`** without allow-list — open redirect at login.

### Custom auth in middleware
- **Middleware reading a JWT from a cookie and decoding without verifying signature** (`jwt.decode` vs `jwt.verify`) — full forgery.
- **`cookies().get('token')?.value`** trusted as identity without verification.

### Session in Edge runtime
- **Verifying JWTs in `middleware.ts`** with a Node-only library — middleware runs on Edge by default. Mistakes here often result in `jwt.verify` becoming a no-op or always-throw caught silently. Trace the flow.

## A08 Software or Data Integrity Failures

- **Server Action receiving a serialized payload that gets passed to `eval` / `Function`** — rare but seen in dynamic form-builder apps.
- **`react-server-dom-webpack` payload handling** — generally safe; flag only if there's a custom RSC payload handler that re-serializes user data.
- **`revalidatePath(userInput)` / `revalidateTag(userInput)`** — these don't execute code, but a malicious tag can poison cache keys. Lower signal.

## A09 Security Logging & Alerting Failures

Per FP filter: only when missing logs concretely enable an attack. Generally drop.

## A10 Mishandling of Exceptional Conditions

- **`try { await auth(); } catch { /* fall through */ }`** in a Server Action — the action runs without authentication when `auth()` throws.
- **Middleware `try/catch` returning `NextResponse.next()` on error** — failure to verify a JWT becomes "let the request through".
- **Route Handler `try { ... } catch { return NextResponse.json({ ok: true }) }`** swallowing authz errors and reporting success.
- **`error.tsx` / `global-error.tsx` boundaries** that re-render the failing route's tree without re-checking auth on retry.

## Common files / locations to prioritize

- **App Router**
  - `app/**/route.{ts,js}` — every route handler. Check method + auth.
  - `app/**/page.{tsx,jsx}` — Server Components with data fetching.
  - `app/**/layout.{tsx,jsx}` — auth gates that may or may not apply to nested route handlers.
  - `app/**/actions.{ts,js}` and any file starting with `'use server'` — every exported function is an endpoint.
- **Pages Router**
  - `pages/api/**/*.{ts,js}` — API routes.
  - `pages/**/*.{tsx,jsx}` — `getServerSideProps` / `getStaticProps`.
- **Middleware**
  - `middleware.{ts,js}` — auth logic + `config.matcher`.
- **Configuration**
  - `next.config.{js,mjs,ts}` — `images`, `rewrites`, `redirects`, `headers`, `experimental.serverActions`.
  - `.env*` — `NEXT_PUBLIC_*` naming.
- **Auth**
  - `auth.{ts,js}`, `app/api/auth/[...nextauth]/route.ts`, `lib/auth.ts` — NextAuth config.
- Search the whole tree for: `'use server'`, `dangerouslySetInnerHTML`, `NEXT_PUBLIC_`, `revalidate`, `unstable_cache`, `force-cache`, `$queryRawUnsafe`, `jwt.decode`.
