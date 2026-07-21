# Go — Audit Patterns

Covers `net/http`, Gin, Echo, Fiber, chi. `database/sql`, GORM, sqlx.

## A01 Broken Access Control

- **Handlers that read `r.URL.Query().Get("id")` and call `db.Find(&user, id)`** without filtering by authenticated user.
- **Middleware not applied** — `r.Use(AuthMiddleware)` missing on a subrouter.
- **Gin `r.Use(cors.New(cors.Config{AllowOrigins: []string{"*"}, AllowCredentials: true}))`** — invalid combo.
- **`http.Redirect(w, r, r.URL.Query().Get("return"), http.StatusFound)`** — open redirect.

## A02 Security Misconfiguration

- **`http.ListenAndServe` with `pprof` registered on the main mux** in prod (`net/http/pprof` registers on `DefaultServeMux` as a side effect of import).
- **`gin.SetMode(gin.DebugMode)`** in prod.
- **`expvar` registered on a public mux** — leaks runtime info.
- **`fmt.Fprintf(w, err.Error())`** returning raw error messages to the client.

## A03 Software Supply Chain Failures

- **`replace` directives in `go.mod` pointing to forks of unknown origin**.
- **Missing `go.sum`**.
- **`go install pkg@latest`** in build scripts.

## A04 Cryptographic Failures

- **`math/rand`** for tokens, password reset, session IDs — must be `crypto/rand`.
- **`crypto/md5` / `crypto/sha1`** for password hashing.
- **`crypto/aes` in ECB mode** — Go doesn't ship an `ECB` mode (intentional), but custom block-by-block AES = ECB. Flag.
- **CBC with fixed/zero IV**:
  ```go
  iv := make([]byte, aes.BlockSize)  // zero IV
  mode := cipher.NewCBCEncrypter(block, iv)
  ```
- **`bcrypt.GenerateFromPassword(pw, bcrypt.MinCost)`** — cost 4.
- **`tls.Config{InsecureSkipVerify: true}`**.
- **Hardcoded keys** — `key := []byte("hardcoded-32-byte-key-here...")`.

## A05 Injection

### SQL injection
- **`db.Query(fmt.Sprintf("SELECT ... WHERE id = %s", id))`** — must use placeholders.
- **`db.Exec("DELETE FROM x WHERE id = " + id)`** — concat.
- **GORM** — `.Where("name = '" + name + "'")` vs `.Where("name = ?", name)`. The first is unsafe; the second is parameterized.
- **GORM `.Raw(sql)`** with concatenation.

### Command injection
- **`exec.Command("sh", "-c", "cmd " + userInput)`** — shell with concatenation.
- **`exec.Command(userInput, args...)`** — attacker controls the binary path.

### Template injection
- **`html/template`** is safe by default. But:
- **`text/template.Execute`** to a `http.ResponseWriter` with user data — **does not auto-escape**, so XSS sink.
- **`html/template` `template.HTML(userInput)`** explicit bypass.

### Path traversal
- **`filepath.Join(base, userInput)`** — does not prevent `..` traversal. Use `filepath.Clean` and check `strings.HasPrefix(filepath.Clean(joined), base)`.
- **`http.ServeFile(w, r, "/static/" + r.URL.Query().Get("f"))`** — `ServeFile` has some `..` protection if the path comes via `URL.Path` but not via concatenated user data.

### XML
- Less common in Go; `encoding/xml` doesn't process external entities by default. Drop XXE flags unless using a third-party XML library that does.

## A06 Insecure Design

- **Token generation via `uuid.New()` (random v4 UUID)** is OK. Via `uuid.NewMD5` / `uuid.NewSHA1` namespace-deterministic — predictable.
- **`base64.URLEncoding.EncodeToString(make([]byte, 8))`** — 64-bit tokens.

## A07 Authentication Failures

- **`golang-jwt/jwt` `Parse(token, keyFunc)`** where `keyFunc` doesn't check the algorithm against an allow-list → key confusion (RS256 → HS256 attack).
- **`jwt.ParseUnverified`** used in code paths that trust the result.
- **Session cookies set with `http.Cookie{Secure: false, HttpOnly: false}`** for auth.

## A08 Software or Data Integrity Failures

- **`encoding/gob`** deserialization of untrusted data — Go's gob is type-aware but can be abused; lower severity than Java but still worth flagging.
- **`yaml.Unmarshal`** generally safe in Go (no code execution), but `mapstructure` decoders with custom hooks can be abused. Usually low signal.

## A10 Mishandling of Exceptional Conditions

- **`if err != nil { /* log */ }`** continuing through an auth check.
- **`defer recover()` swallowing panics** in auth middleware so the handler proceeds.

## Common files / locations to prioritize

- `main.go`, `cmd/**/main.go`
- `internal/handlers/**`, `internal/api/**`
- `internal/auth/**`, `middleware/**`
- `go.mod`, `go.sum`
- Anywhere with `database/sql`, `gorm.io/gorm`, `jmoiron/sqlx`
