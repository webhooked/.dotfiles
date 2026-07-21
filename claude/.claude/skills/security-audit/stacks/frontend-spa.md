# Frontend SPA — Audit Patterns

Covers Vue, Angular, Svelte, Solid, Astro, Nuxt. **For React, see `stacks/react.md`. For Next.js, see `stacks/nextjs.md`.** Server-rendered parts go in the matching backend stack file.

Reminder from the false-positive filter: **client-side authz checks are not security**. The backend is the source of truth. Only flag client-side patterns when they produce a server-observable vulnerability (XSS that steals tokens, etc.).

## A01 Broken Access Control

- **JWT in `localStorage` displayed alongside any XSS sink** — combined risk; flag the XSS, not the storage.
- **postMessage handlers without origin check** — `window.addEventListener('message', e => /* trust e.data */)` without `e.origin === expected`. This can be cross-origin authz bypass.
- **OAuth callback page** that accepts `code` from `window.location` and posts it back to any `state.return_url` (open-redirect-as-OAuth-theft).

## A02 Security Misconfiguration

- **Sensitive config bundled into client JS** — API secrets, signing keys in `import.meta.env.VITE_*` / `process.env.VUE_APP_*` / equivalent that should be server-only.
- **Dev tooling reachable in production** — usually deployment misconfig, drop unless concrete.

## A05 Injection (XSS, the main frontend concern)

### Vue
- **`v-html="userInput"`** — XSS sink.
- **`<a :href="userInput">`** with `javascript:` URI.
- **Vue 2 `Vue.compile(userTemplate)`** — template injection / XSS.

### Angular
- **`[innerHTML]="userInput"`** without `DomSanitizer.bypassSecurityTrustHtml` (and even with it, the `bypass*` calls are the red flag).
- **`bypassSecurityTrustHtml`, `bypassSecurityTrustUrl`, `bypassSecurityTrustResourceUrl`** with user data.

### Svelte
- **`{@html userInput}`** — XSS sink.

### DOM-based XSS (framework-agnostic)
- **`element.innerHTML = userInput`** anywhere in plain JS.
- **`document.write(userInput)`**.
- **`eval(userInput)`, `new Function(userInput)`, `setTimeout(userInput, ...)` with a string**.

### Server-side rendering pitfalls
- **Nuxt/Astro server-rendered components emitting unescaped HTML** that the client then hydrates — verify the SSR output sanitizes user data the same way the client would.

## A06 Insecure Design

- **API keys exposed in client bundles** — `process.env.STRIPE_SECRET_KEY` in code that ends up in the browser (instead of `STRIPE_PUBLIC_KEY`).
- **Tokens stored without `Secure`/`HttpOnly` cookie** when a cookie option exists — see backend.

## A07 Authentication Failures

- **JWT validation done on the client only**. The backend must re-validate.
- **OAuth state parameter not used / not checked**.

## A08 Software or Data Integrity Failures

- **Loading third-party scripts via `<script src="https://...">`** without Subresource Integrity (`integrity="sha384-..."`). Only flag for high-value scripts (payment, auth widgets).
- **`fetch('/api/x').then(r => eval(r.text()))`** — eval over network response.
- **Dynamic `import()` of attacker-controlled URLs**.

## Common files / locations to prioritize

- `src/**/*.{vue,svelte,ts,js}` and Angular `*.component.ts` / `*.component.html` — search for `v-html`, `{@html`, `[innerHTML]`, `bypassSecurityTrust`.
- `vite.config.{js,ts}`, `nuxt.config.{js,ts}`, `astro.config.{mjs,ts}`, `angular.json` — CSP headers, env exposure.
- `public/index.html` for inline scripts.
- Any `window.addEventListener('message', ...)`.
- Bundled output: spot-check for committed secrets in `dist/`, `build/`.
