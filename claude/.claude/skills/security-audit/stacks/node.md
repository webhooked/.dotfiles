# Node.js — Audit Patterns

Covers Express, NestJS, Fastify, Koa, Hapi, plain `http.createServer`. TypeScript and JavaScript both in scope.

## A01 Broken Access Control

- **Missing auth middleware** on routes that mutate user data. Look for routers that don't apply a `requireAuth` / `passport.authenticate` / `@UseGuards()`.
- **IDOR** — `findById(req.params.id)` without `userId: req.user.id` in the query.
- **Mongoose query injection** — `User.find({ username: req.body.username })` where the body sends `{ "$ne": null }`. Always coerce to string or use `mongo-sanitize`.
- **`res.redirect(req.query.returnUrl)`** without allow-list.
- **NestJS missing `@UseGuards(AuthGuard)`** on controllers that shouldn't be public.

## A02 Security Misconfiguration

- **`app.use(cors({ origin: true, credentials: true }))`** — reflects any origin with credentials.
- **`helmet` not used** combined with cookie-based auth and missing CSRF protection.
- **`app.disable('etag')` not done** with sensitive responses (low signal — usually drop).
- **Express `trust proxy`** misconfigured so that `req.ip` returns attacker-controlled header value used in authz/rate-limit decisions.
- **Default JWT secret** like `"secret"` or `"change-me"` in code.
- **`NODE_TLS_REJECT_UNAUTHORIZED=0`** set anywhere in source.

## A03 Software Supply Chain Failures

- **`package.json` deps with `*`, `latest`, or git URLs** without commit pin.
- **Missing or stale lockfile** (`package-lock.json` / `yarn.lock` / `pnpm-lock.yaml`).
- **`postinstall` / `preinstall` scripts** that download from external URLs.
- **`.npmrc` with public registry fallback** for scoped private packages (dependency confusion).

## A04 Cryptographic Failures

- **`Math.random()`** for token / password reset / API key generation. Must be `crypto.randomBytes` or `crypto.randomUUID`.
- **`crypto.createHash('md5')` / `'sha1'`** for password hashing.
- **`bcrypt.hash(pw, 4)`** — cost factor too low (< 10 is borderline; in 2026, < 12 is weak).
- **`jsonwebtoken` `verify` without `algorithms` option** — allows `alg: none` or algorithm confusion.
- **Hardcoded JWT secret** in source.
- **`crypto.createCipher`** (deprecated; doesn't use IV correctly) instead of `createCipheriv`.
- **`https.request({ rejectUnauthorized: false })`**.

## A05 Injection

### SQL injection
- **Raw string concatenation** in `pg`, `mysql2`, `better-sqlite3`:
  ```js
  pool.query(`SELECT * FROM users WHERE id = ${req.params.id}`)  // BAD
  pool.query('SELECT * FROM users WHERE id = $1', [req.params.id])  // OK
  ```
- **Sequelize `query`** with `replacements` is safe; with string concatenation is not.
- **TypeORM `query()`** raw is unsafe; `createQueryBuilder` is safe.
- **Knex `whereRaw('id = ' + id)`** vs `whereRaw('id = ?', [id])`.

### NoSQL injection
- Mongoose `find({ field: req.body.field })` where `req.body.field` can be an object → operator injection (`{ $gt: '' }`).
- Always validate that body fields are strings, or use `express-mongo-sanitize`.

### Command injection
- `child_process.exec(`cmd ${userInput}`)` — use `execFile` with array args.
- `child_process.spawn('sh', ['-c', 'cmd ' + userInput])` — same problem.

### Template injection (SSTI)
- `pug.compile(userInput)`, `handlebars.compile(userInput)`, EJS `render(userInput)` — flag if `userInput` is data, not the template.

### Path traversal
- `fs.readFile(path.join(rootDir, req.params.file))` without `path.normalize` + `startsWith(rootDir)` check.
- `express.static` with a user-controlled root — uncommon.

### Prototype pollution sinks
- `Object.assign({}, userInput)`, `_.merge({}, userInput)`, JSON-parsed input merged into a config object. Only flag when chained to a known sink (template engine, query builder).

## A06 Insecure Design

- **Express-rate-limit absent** on auth endpoints — but per FP rules, rate-limit absence alone is out of scope.
- **JWT with no `exp`** claim, or never rotated.
- **Password reset token = `crypto.randomBytes(8)`** (too short, < 128 bits of entropy).

## A07 Authentication Failures

- **`jsonwebtoken.verify(token, secret)`** without specifying `algorithms` → key confusion (RSA public key used as HMAC secret).
- **JWT in `localStorage`** with no XSS-mitigation strategy (frontend concern, see frontend-spa.md).
- **`express-session`** with `secret: 'keyboard cat'` (default example).
- **`cookie: { secure: false, httpOnly: false }`** on session cookies.
- **`passport-local`** without `failureMessage` rate limiting — drop unless a concrete chain exists.

## A08 Software or Data Integrity Failures

- **`node-serialize`, `serialize-javascript` with `{ isJSON: false }`** on user data — RCE.
- **`vm.runInNewContext(userInput)`** — eval.
- **`eval(userInput)`** / `new Function(userInput)` — eval.
- **`yaml.load(userInput)`** without `safeLoad` / `FAILSAFE_SCHEMA` (older `js-yaml` versions).

## A10 Mishandling of Exceptional Conditions

- **Unhandled promise rejection in auth middleware** that bypasses to `next()` without an error.
- **`try { await authCheck(); } catch { /* log */ } next();`** — proceeds despite auth failure.

## Common files / locations to prioritize

- `app.js`, `server.js`, `src/main.ts`, `src/app.module.ts`
- `routes/**/*.js`, `controllers/**/*.ts`
- `middleware/**`, `guards/**`
- `models/**`, `entities/**`
- `package.json`, `.npmrc`, lockfiles
- `.env*` (for hardcoded secrets in committed env files)
