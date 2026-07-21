# React — Audit Patterns

Covers React 17/18/19 in client-side apps (Vite, Create React App, Remix client, plain Webpack). Pair this with `stacks/nextjs.md` if Next.js is detected, with `stacks/frontend-spa.md` for non-React SPA patterns, and with the backend stack file for any server code.

Reminder from the false-positive filter: **client-side authz is not a vulnerability** — the backend is the trust boundary. Only flag client-side patterns that produce a server-observable issue (XSS, token theft, postMessage origin bypass, etc.).

## A01 Broken Access Control

- **`window.location = userInput`** or `<Navigate to={userInput} />` (React Router) without an allow-list check — drops into the OAuth-callback-theft pattern when chained with a returned auth code.
- **postMessage handlers without origin verification:**
  ```jsx
  useEffect(() => {
    window.addEventListener('message', (e) => {
      // BAD — no e.origin check
      setData(e.data);
    });
  }, []);
  ```
  When the handler performs an auth-relevant action (token storage, API call), this is a cross-origin authz bypass.
- **React Router `Navigate` / `useNavigate` with user-controlled `state`** that the destination route treats as trusted (e.g., a "you are now logged in as X" page reading from `location.state.user`).

## A02 Security Misconfiguration

- **Secrets exposed in client bundles** — anything in `process.env.REACT_APP_*` (CRA), `import.meta.env.VITE_*` (Vite), or just hardcoded constants ships to the browser. Look for keys named `*_SECRET`, `*_PRIVATE_KEY`, `STRIPE_SECRET_*`, AWS access keys.
- **Source maps deployed to production** — `GENERATE_SOURCEMAP=true` (CRA default) or `build.sourcemap: true` (Vite) leaks original source. Only flag when the build clearly targets production.
- **CSP that allows `unsafe-inline` / `unsafe-eval`** in a `<meta http-equiv="Content-Security-Policy">` tag combined with `dangerouslySetInnerHTML` sinks — magnifies XSS impact.

## A05 Injection (XSS, the primary React concern)

React auto-escapes interpolated values. **Only the explicit bypasses below are sinks.**

### HTML injection sinks
- **`dangerouslySetInnerHTML={{ __html: userInput }}`** — XSS. Always flag with attacker-controlled data. Check the source of `__html`:
  - Direct API response → high confidence.
  - Markdown rendered with `marked` / `markdown-it` without sanitizer → flag.
  - Sanitized via `DOMPurify.sanitize` → safe.
- **`Element.prototype.innerHTML = userInput`** via `useRef` + manual DOM:
  ```jsx
  const ref = useRef();
  useEffect(() => { ref.current.innerHTML = userInput; }, [userInput]);
  ```
- **`createPortal(<div dangerouslySetInnerHTML={{...}} />, document.body)`** — same sink, different mount point.

### JavaScript-URI sinks
- **`<a href={userInput}>`** — `userInput` of `javascript:alert(1)` runs on click.
- **`<iframe src={userInput}>`** — `javascript:` URIs execute in the parent context when same-origin.
- **`<form action={userInput}>`** — `javascript:` URI on submit.
- **`window.location.href = userInput`** with attacker-controlled value.

Mitigation expected: an allow-list check (`url.startsWith('https://')` or a URL parser with `protocol === 'https:'`). The bare `<a href={url}>` pattern with `url` from `useState` of an API response is the vulnerable case.

### Markdown / rich-text rendering
- **`marked(userInput)` → dangerouslySetInnerHTML** without `DOMPurify` — XSS.
- **`remark-html` / `react-markdown` with `rehype-raw`** enabled and untrusted markdown — XSS (HTML in markdown is rendered).
- **`react-markdown` default** is safe (escapes HTML); only flag when raw HTML rendering is explicitly enabled.

### Dynamic component / element rendering
- **`React.createElement(userInput, ...)`** where `userInput` is a string from user data — can mount unexpected components. Low signal unless paired with a registry of dangerous components.
- **`<Component {...userObject} />`** spreading attacker-controlled props into a component that has a sink (e.g., spreading `{ dangerouslySetInnerHTML }` from an API response).

### Refs and direct DOM access
- **`ref.current.outerHTML = userInput`**, **`document.write(userInput)`**, **`document.createRange().createContextualFragment(userInput)`** — all XSS sinks.

### Eval-class sinks
- **`eval(userInput)`** anywhere — RCE in the page context.
- **`new Function(userInput)()`** — eval.
- **`setTimeout(userInput, ms)` / `setInterval(userInput, ms)`** where `userInput` is a **string** (not a function).

## A06 Insecure Design

- **JWT or session token in `localStorage`** combined with **any unsanitized HTML sink** in the same app — chained XSS exfiltrates the token. Flag the XSS as the root cause, but call out the token-storage choice as the multiplier.
- **Password reset / verification token in URL fragment** echoed into rendered HTML via `dangerouslySetInnerHTML` — leak via referrer + XSS.
- **Client-side encryption** of data sent to the server (e.g., a homebrew `encrypt(data, hardcodedKey)` in the bundle). The key is in the browser; this is not encryption.

## A07 Authentication Failures (client-observable)

- **Token storage choices** — `localStorage` / `sessionStorage` are XSS-readable; cookies should be `HttpOnly` + `Secure` + `SameSite=Lax|Strict`. Only flag when there's a concrete XSS sink in the same app.
- **OAuth `state` parameter not validated** in the callback handler — CSRF on the OAuth flow.
- **PKCE missing** in public-client OAuth (SPA without backend). The `code_verifier` should be generated and stored before redirect, then sent on exchange.

## A08 Software or Data Integrity Failures

- **`<script src={userInput}>`** — loading a script from a user-controlled URL.
- **Dynamic `import(userInput)`** — loading a module from an attacker URL.
- **Third-party CDN scripts without Subresource Integrity** for high-value scripts (payment, auth widgets, analytics that can be hijacked):
  ```html
  <script src="https://cdn.example.com/widget.js"></script>  <!-- missing integrity= -->
  ```
- **`window.postMessage(token, '*')`** — sending sensitive data with `*` target — any window in the chain receives it.

## A10 Mishandling of Exceptional Conditions

- **Error boundaries that swallow errors and render the protected UI anyway:**
  ```jsx
  class Boundary extends React.Component {
    componentDidCatch(err) { /* log */ }
    render() { return this.props.children; }  // BAD — fall through
  }
  ```
  If the protected tree contains an auth-gated component that throws when not logged in, the fallback can render the protected content. Low signal — only flag when the auth gate itself is structured as a thrown error caught by a boundary.

## Common files / locations to prioritize

- `src/**/*.{jsx,tsx,js,ts}` — grep for:
  - `dangerouslySetInnerHTML`
  - `\.innerHTML\s*=`
  - `href=\{` (then trace the variable)
  - `addEventListener\(['"]message['"]`
  - `localStorage\.setItem.*token` / `\.setItem\(['"]auth`
  - `eval\(`, `new Function\(`, `setTimeout\([^,)]+,` (string first arg)
- `public/index.html` — inline scripts, meta CSP.
- `vite.config.{js,ts}` / `webpack.config.js` / CRA `package.json` — sourcemap and env exposure settings.
- `package.json` `dependencies` — markdown renderers (`marked`, `markdown-it`, `react-markdown`) with their HTML/sanitizer settings.
- `.env*` files in the frontend folder — anything with `REACT_APP_*` / `VITE_*` named like a secret.
