# Python — Audit Patterns

Covers Django, Flask, FastAPI, Starlette, Tornado, plus SQLAlchemy / Django ORM. Python 3.

## A01 Broken Access Control

- **Django `@login_required` only** without object-level permission check. `Post.objects.get(pk=pk)` without `.filter(author=request.user)`.
- **Django REST Framework view** with `permission_classes = [AllowAny]` on sensitive endpoints.
- **FastAPI** route without a `Depends(get_current_user)` on mutating routes.
- **Flask** route without `@login_required` and `current_user` check.
- **`redirect(request.GET.get('next'))`** — open redirect (Django has `url_has_allowed_host_and_scheme` to use).

## A02 Security Misconfiguration

- **Django `DEBUG = True` in production** — `settings.py` with no env-based override.
- **Django `ALLOWED_HOSTS = ['*']`** in production settings.
- **Django `SECRET_KEY` hardcoded** in settings (not loaded from env/secret store).
- **`SECURE_SSL_REDIRECT = False`**, `SESSION_COOKIE_SECURE = False`, `CSRF_COOKIE_SECURE = False` on a production settings file.
- **Flask `app.run(debug=True)`** in committed code.
- **CORS** — `flask-cors` with `CORS(app, origins='*', supports_credentials=True)`.

## A03 Software Supply Chain Failures

- **`requirements.txt` without pinning** — `django` instead of `django==4.2.7`.
- **No lockfile** when using Pipenv/Poetry (`Pipfile.lock` / `poetry.lock` missing).
- **`pip install --extra-index-url`** from untrusted source.

## A04 Cryptographic Failures

- **`random` module** for tokens / passwords / session IDs — must be `secrets` module.
- **`hashlib.md5` / `hashlib.sha1`** for passwords.
- **Bare `hashlib.sha256(password)`** for password hashing — must use `bcrypt`, `argon2-cffi`, or `passlib` with PBKDF2 high iterations.
- **`Crypto.Cipher.AES.new(key, AES.MODE_ECB)`** — ECB mode.
- **`Crypto.Cipher.AES.new(key, AES.MODE_CBC, iv=b'\x00'*16)`** — fixed IV.
- **`requests.get(url, verify=False)`** — TLS verification disabled.
- **`ssl._create_unverified_context()`** — explicitly unverified.

## A05 Injection

### SQL injection
- **Django ORM** — `.raw("SELECT * FROM x WHERE id = " + id)` or `.extra(where=["col = '%s'" % x])`.
- **`connection.cursor().execute(f"SELECT ... {var}")`** — must use `%s` params, not f-strings.
- **SQLAlchemy** — `session.execute(f"...{x}")` instead of `session.execute(text("..."), {"x": x})` or parameterized.
- **`Engine.execute(query_string)`** with concatenation.

### Command injection
- **`os.system(cmd_str)`** with user input.
- **`subprocess.run(cmd, shell=True)`** with concatenated user input. Use `shell=False` + list args.
- **`subprocess.Popen(f"sh -c '{user}'")`** — same.
- **`os.popen(user)`** — eval-style command exec.

### Template injection (SSTI)
- **Jinja2** — `Template(user_input).render()`. Critical, RCE.
- **Django** — `Template(user_input).render(Context())`.
- **Mako** — `Template(user_input).render()`.

### Deserialization (covered also in A08)
- **`pickle.loads(user_data)`** — RCE. Always.
- **`yaml.load(user_data)`** without `Loader=yaml.SafeLoader` — RCE.
- **`marshal.loads(user_data)`** — RCE.
- **`shelve.open(user_path)`** — uses pickle.

### XXE
- **`xml.etree.ElementTree.parse`** with user data — varies by Python version; older stdlib parsed external entities. Prefer `defusedxml`.
- **`lxml.etree.XMLParser(resolve_entities=True)`** — XXE.

### Path traversal
- **`open(os.path.join(BASE, user_input))`** without `os.path.realpath` + prefix check.
- **`send_file(request.args['f'])`** in Flask without sanitization.
- **`os.path.join` does not prevent `..` traversal.**

## A06 Insecure Design

- **Password reset tokens from `random`** module instead of `secrets.token_urlsafe`.
- **Reset tokens with no expiry**.
- **Django `User.objects.create_user(password=raw)`** when `raw` is from URL params — exposes password in logs.

## A07 Authentication Failures

- **Django session settings**: `SESSION_COOKIE_HTTPONLY = False` or `SESSION_COOKIE_SAMESITE = None` without `Secure`.
- **JWT** (`PyJWT`) `decode(token, secret, algorithms=None)` — accepts any algorithm including `none`.
- **`PyJWT.decode(..., options={"verify_signature": False})`** in code paths that touch user-controlled tokens.
- **Hardcoded `SECRET_KEY`** used as session signing key.

## A08 Software or Data Integrity Failures

The Python deadly deserializers:
- **`pickle` / `cPickle` / `dill`** — all RCE on untrusted input.
- **`yaml.load` without SafeLoader**.
- **`marshal.loads`**.
- **`shelve`** on attacker-controlled paths.
- **`fastapi` / `pydantic`** parsing untrusted JSON into models with `arbitrary_types_allowed = True` and custom `__init__` that does file I/O. Rare but real.

## A10 Mishandling of Exceptional Conditions

- **`except Exception: pass`** around auth/permission checks.
- **Django middleware that returns `None` on exception** instead of erroring — request proceeds without auth.

## Common files / locations to prioritize

- `settings.py`, `settings/*.py`, `config.py`
- `urls.py`, `routes.py`
- `views.py`, `viewsets.py`, `views/**`
- `models.py`, `serializers.py`
- `requirements*.txt`, `Pipfile`, `pyproject.toml`, lockfiles
- `manage.py` (less relevant), `wsgi.py`, `asgi.py`
- `.env*`
