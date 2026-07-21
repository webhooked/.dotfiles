# PHP — Audit Patterns

Covers Laravel, Symfony, Slim, CodeIgniter, and vanilla PHP. PDO, Eloquent, Doctrine.

## A01 Broken Access Control

- **Laravel route without `middleware('auth')`** on sensitive endpoints.
- **`Model::find($id)`** without `->where('user_id', auth()->id())` — IDOR.
- **`$request->validate(['admin' => 'boolean'])`** then `User::create($request->all())` — mass assignment letting attackers set `is_admin`. Use `$fillable` / `$guarded`.
- **Open redirect** — `return redirect($request->input('next'));` without `url->isValidHost`.

## A02 Security Misconfiguration

- **`APP_DEBUG=true`** in `.env` committed for production.
- **`APP_ENV=local`** in production.
- **Laravel `config/app.php` with `'debug' => true`**.
- **`display_errors = On`** in `php.ini` for production.
- **`session.cookie_httponly = 0`**, `session.cookie_secure = 0`, `session.cookie_samesite = 'None'` (without `Secure`).
- **CORS** — Laravel `config/cors.php` with `'allowed_origins' => ['*']` and `'supports_credentials' => true`.

## A03 Software Supply Chain Failures

- **`composer.json` with `dev-master`** or non-pinned versions.
- **`composer install --no-dev` not used** in production deploys (less critical).
- **Custom repositories over HTTP**.

## A04 Cryptographic Failures

- **`mt_rand` / `rand`** for tokens — must be `random_bytes` / `random_int`.
- **`md5($password)`, `sha1($password)`** for password hashing — must use `password_hash` with `PASSWORD_BCRYPT` or `PASSWORD_ARGON2ID`.
- **`password_hash($pw, PASSWORD_BCRYPT, ['cost' => 4])`** — cost too low.
- **`openssl_encrypt($data, 'AES-256-ECB', $key)`** — ECB.
- **Fixed IV with `'AES-256-CBC'`**.
- **`curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false)`**.
- **`curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0)`**.
- **Hardcoded `APP_KEY`** in committed `.env`.

## A05 Injection

### SQL injection
- **Vanilla mysqli** — `$mysqli->query("SELECT * FROM x WHERE id = " . $id)` — concat. Use prepared statements.
- **PDO** — `$pdo->query("... $id")` vs `$pdo->prepare("... :id")->execute([':id' => $id])`.
- **Laravel `DB::select("... $id")`** with concat. Use `DB::select('... ?', [$id])` or query builder.
- **Eloquent** — generally safe via parameter binding; `whereRaw("col = $x")` is unsafe.
- **Doctrine** — `$conn->query("... $x")` unsafe; `$conn->prepare(...)` safe.

### Command injection
- **`exec("cmd $user")`, `shell_exec("cmd $user")`, `system("cmd $user")`, `passthru("cmd $user")`**.
- **Backticks** — `` `cmd $user` ``.
- **`proc_open("sh -c 'cmd $user'", ...)`**.
- Use `escapeshellarg` and `escapeshellcmd` (and prefer `exec` with array-style commands in PHP 8+).

### Code injection
- **`eval($user)`** — RCE.
- **`assert($user)`** — historically used `eval`; deprecated but still RCE on older PHP.
- **`create_function`** — deprecated, RCE.
- **`preg_replace` with `/e` modifier** — eval (removed in PHP 7+).

### File inclusion (PHP-specific A05)
- **`include $_GET['page']`** or `require($_REQUEST['p'])` — Local/Remote File Inclusion. RCE.
- **`include "./pages/" . $_GET['p'] . ".php"`** — path traversal + LFI.
- **`allow_url_include = On`** in `php.ini` combined with the above = Remote File Inclusion. Always high.

### Template injection
- **Twig** — generally safe, but `{{ user_input|raw }}` defeats escaping.
- **Blade** — `{!! $userInput !!}` defeats escaping.
- **Smarty `{eval}`** tag with user input.

### Path traversal
- **`file_get_contents("uploads/" . $_GET['file'])`** without `basename()` / realpath check.
- **`readfile($_GET['path'])`**.

### XXE
- **`libxml_disable_entity_loader(false)`** (or its absence in older PHP) when parsing user XML.
- **`simplexml_load_string($xml, 'SimpleXMLElement', LIBXML_DTDLOAD)`** — DTD loading enabled.

## A06 Insecure Design

- **Password reset by `md5(uniqid())`** — predictable.
- **Reset tokens without expiry**.

## A07 Authentication Failures

- **`firebase/php-jwt` `JWT::decode($token, $key)`** with no algorithm whitelist (older versions) — algorithm confusion.
- **`session.use_strict_mode = 0`** — session fixation.
- **Laravel `Auth::login($user, true)`** with `true` (remember me) without rotating session.
- **Custom session cookie `setcookie('PHPSESSID', $id, 0, '/', '', false, false)`** — not Secure, not HttpOnly.

## A08 Software or Data Integrity Failures

- **`unserialize($user_input)`** — RCE via PHP object injection / magic methods (`__wakeup`, `__destruct`).
- Even with `['allowed_classes' => false]` in PHP 7+, the surrounding logic must validate types before use.
- **`phar://` stream wrapper** — accessing a user-controlled path with `file_exists`, `file_get_contents`, etc., on a `phar://` URL triggers deserialization. Subtle but real.

## A10 Mishandling of Exceptional Conditions

- **`@function_call()`** (error suppression) on auth checks.
- **`try { authorize(); } catch (Exception $e) { /* log */ }`** — proceeds without authz.

## Common files / locations to prioritize

- `.env`, `.env.example` (often committed)
- `composer.json`, `composer.lock`
- `config/**` (especially `app.php`, `auth.php`, `session.php`, `cors.php`)
- `routes/web.php`, `routes/api.php`
- `app/Http/Controllers/**`, `app/Http/Middleware/**`
- `public/index.php`
- Any `unserialize`, `eval`, `include $`, `exec(`, `system(`
