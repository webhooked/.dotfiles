# .NET / ASP.NET / EF — Audit Patterns

Covers .NET Framework and .NET (Core/5+), ASP.NET MVC, Web API 2/Core, Entity Framework 6 / EF Core, Forms Auth, OWIN, SignalR.

## A01 Broken Access Control

- **Missing `[Authorize]`** on controllers/actions that read/write user data. Verify `[AllowAnonymous]` is only on login, password reset request (not reset itself), public marketing pages.
- **`[AllowAnonymous]` inheritance** — `[AllowAnonymous]` on a base controller silently disables auth on every action below it.
- **IDOR** — Actions accepting an `id` parameter that load entities by ID without scoping to the current user/tenant: `db.Orders.Find(id)` instead of `db.Orders.FirstOrDefault(o => o.Id == id && o.UserId == currentUserId)`.
- **`returnUrl` open redirect** — `return Redirect(returnUrl)` without `Url.IsLocalUrl(returnUrl)` check.
- **Custom authz with bypassable string comparison** — Role checks like `User.IsInRole("admin")` vs. `role == "Admin"` — case mismatches that fail open.
- **RBAC cascading bugs** — When permissions cascade (parent → child resources), check the cascade direction is consistently enforced. Look for places that check parent-level permission but the resource is accessed by child ID without confirming the child belongs to a permitted parent.
- **Impersonation endpoints** — Any `ImpersonateUser` / `SwitchUser` endpoint must require admin role **and** log the action **and** be protected by anti-forgery token.

## A02 Security Misconfiguration

- **`Web.config` insecurities:**
  - `<compilation debug="true">` in production
  - `<customErrors mode="Off">` or `mode="RemoteOnly"` with stack traces in `<trace>`
  - `<httpCookies requireSSL="false" httpOnlyCookies="false">`
  - `<forms requireSSL="false">` under `<authentication mode="Forms">`
  - `<sessionState cookieless="UseUri">` (session token in URL)
  - `<machineKey validationKey="AutoGenerate,IsolateApps">` in a load-balanced setup (causes ViewState validation issues; or if hardcoded, key disclosure)
- **CORS** — `EnableCorsAttribute("*", "*", "*")` or `app.UseCors(x => x.AllowAnyOrigin().AllowCredentials())` — the combo of `*` + credentials is invalid in spec but some middleware allows it; flag.
- **Missing security headers** — Only flag when chained into a real attack (e.g., no CSP **plus** a stored-XSS sink).

## A03 Software Supply Chain Failures

- **`packages.config` / `*.csproj` package references** without version pinning (rare in .NET, but check `Version="*"`).
- **Private NuGet feed fallback to nuget.org** — dependency confusion risk if internal package names collide.
- **`Install-Package` in build scripts** without `-Version`.

## A04 Cryptographic Failures

- **`System.Random`** used to generate tokens, password reset codes, session IDs, API keys — must be `RandomNumberGenerator` / `RNGCryptoServiceProvider`.
- **Hardcoded `Rfc2898DeriveBytes` salt** — same salt for every password.
- **PBKDF2 iteration count < 100,000** for password hashing in 2026.
- **`AesManaged` / `AesCryptoServiceProvider` with hardcoded `Key` or `IV`** — especially in `Crypto.cs` / `Encryption.cs` helper files.
- **`MD5.Create()` / `SHA1.Create()`** used for password hashing or integrity verification of trust-boundary-crossing data.
- **`ServicePointManager.ServerCertificateValidationCallback = (s, c, ch, e) => true`** — cert validation disabled.
- **JWT signing key hardcoded** in source or with very short HS256 secret (< 32 bytes).

## A05 Injection

### SQL injection
- **EF6/Core raw SQL** with concatenation/interpolation:
  ```csharp
  db.Database.SqlQuery<User>("SELECT * FROM Users WHERE Name = '" + name + "'")  // BAD
  db.Database.ExecuteSqlCommand($"DELETE FROM Logs WHERE Id = {id}")  // BAD (ExecuteSqlCommand doesn't parameterize $-interpolation)
  ```
  Note: `FromSqlInterpolated` and `ExecuteSqlInterpolated` **are** safe (they parameterize). `FromSqlRaw($"...")` is **not**.
- **`SqlCommand.CommandText`** built with concatenation, `Parameters.AddWithValue` not used.
- **Dynamic LINQ** with `System.Linq.Dynamic` parsing user input into `Where("Name = " + userInput)`.

### Command injection
- `Process.Start(new ProcessStartInfo { FileName = "cmd.exe", Arguments = "/c " + userInput })`
- `System.Diagnostics.Process.Start("powershell", $"-Command {userInput}")`

### XXE
- `XmlReader.Create(stream)` without an `XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null }`.
- `XmlDocument.Load(...)` — `XmlDocument` resolves DTDs by default on .NET Framework. Must set `XmlResolver = null` before `Load`.
- `XPathDocument` with default settings on .NET Framework.

### Razor / template injection
- `@Html.Raw(userInput)` in `.cshtml` views.
- `@MvcHtmlString.Create(userInput)`.
- `Response.Write(userInput)` from controllers.

### Path traversal
- `File.ReadAllText(Server.MapPath("~/uploads/" + filename))` without `Path.GetFileName(filename)` to strip `../`.
- `Path.Combine(rootPath, userInput)` — `Path.Combine` does **not** prevent traversal; `..` in input still works.

## A06 Insecure Design

- **Password reset by email-only verification** with predictable token (`Guid.NewGuid()` is technically random but check it's actually used, not `DateTime.Now.Ticks`).
- **Tokens not expiring** — `PasswordResetToken` with no `ExpiresAt` check.
- **MFA can be skipped** by hitting the post-login endpoint directly with the partial-auth cookie.

## A07 Authentication Failures

- **Forms Auth cookie** without `HttpOnly` or `Secure` (check `Web.config` `<httpCookies>` and `<forms>`).
- **JWT `ValidateIssuerSigningKey = false`** or `ValidateLifetime = false` in `TokenValidationParameters`.
- **JWT `RequireSignedTokens = false`** — accepts `alg: none`.
- **Session fixation** — session cookie not regenerated on login.
- **`PasswordSignInAsync` with `lockoutOnFailure: false`** — credential stuffing exposure (medium).

## A08 Software or Data Integrity Failures (unsafe deserialization — HIGH RISK)

These are the .NET-specific deadly deserializers. Any use on attacker-influenced input is High:

- **`BinaryFormatter`** — `new BinaryFormatter().Deserialize(stream)`. Microsoft has officially declared this insecure; flag every use on non-trusted data.
- **`NetDataContractSerializer`**
- **`SoapFormatter`**
- **`LosFormatter`** / **`ObjectStateFormatter`** — ViewState class; flag if used outside the framework's own ViewState path.
- **`JavaScriptSerializer` with `SimpleTypeResolver`** — gadget chain.
- **`Json.NET` with `TypeNameHandling = All / Objects / Auto`** — `JsonConvert.DeserializeObject<T>(input, new JsonSerializerSettings { TypeNameHandling = TypeNameHandling.All })`. RCE via gadget chains.
- **`System.Text.Json` with custom `TypeInfoResolver`** that allows polymorphic deserialization on user input.
- **`XmlSerializer` with type-name-driven polymorphism** via `XmlInclude` — generally safer than `BinaryFormatter` but flag if attacker can influence the included types.
- **`DataContractSerializer` with `KnownTypes`** dynamically built from user input.

### ViewState
- `<pages enableViewStateMac="false">` or `<%@ Page EnableViewStateMac="false" %>` — disables MAC validation. RCE.
- Missing `<machineKey>` in load-balanced setup → ViewState validation failures that some apps "work around" by disabling MAC.

## A09 Security Logging & Alerting Failures

- Per the FP filter: only flag if missing logs concretely enable an attack. Generally drop.

## A10 Mishandling of Exceptional Conditions

- **`try { CheckAuthorization(); } catch { /* swallow */ }`** — allows action to proceed when authz throws.
- **Custom `IAuthorizationFilter` that returns `true` on exception**.
- **Global `Application_Error` handlers that swallow auth exceptions** and continue the request.

## Common files / locations to prioritize

- `Web.config`, `App.config`, `appsettings*.json`
- `Global.asax.cs` (`Application_Start`, `Application_BeginRequest`)
- `App_Start/*.cs` (`FilterConfig.cs`, `RouteConfig.cs`, `WebApiConfig.cs`)
- `Controllers/**/*.cs`, `**/*Controller.cs`
- `**/*Hub.cs` (SignalR)
- `Crypto.cs`, `Encryption.cs`, `Security.cs`, `Auth*.cs`
- `Areas/**/Controllers/**`
- `*.cshtml` (Razor injection)
