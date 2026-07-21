# Ruby / Rails — Audit Patterns

Covers Rails (5/6/7), Sinatra, Roda. ActiveRecord, Devise, Pundit/CanCanCan.

## A01 Broken Access Control

- **Rails controllers without `before_action :authenticate_user!`** on sensitive actions.
- **`Post.find(params[:id])`** without scoping to `current_user.posts.find(params[:id])` — IDOR.
- **Pundit policies returning `true` by default** in `ApplicationPolicy`.
- **`redirect_to params[:return_to]`** — open redirect (Rails 7+ has `protect_from_forgery` and `url_from` helpers; flag missing use).
- **Strong parameters bypass** — `params.require(:user).permit!` (allows mass assignment of every attribute including `admin: true`).

## A02 Security Misconfiguration

- **`config.consider_all_requests_local = true`** in `config/environments/production.rb` — exposes detailed errors.
- **`config.force_ssl = false`** in production.
- **`Rails.application.config.session_store :cookie_store, secure: false, httponly: false`**.
- **Hardcoded `secret_key_base`** in `config/secrets.yml` committed.
- **CORS via `rack-cors`** with `origins '*', credentials: true`.

## A03 Software Supply Chain Failures

- **`Gemfile` with `:git => 'https://...'`** without a `:ref` SHA pin.
- **Stale `Gemfile.lock`** missing.
- **Custom gem sources over HTTP**.

## A04 Cryptographic Failures

- **`Random.rand` / `Kernel#rand`** for tokens — must be `SecureRandom`.
- **`Digest::MD5` / `Digest::SHA1`** for password hashing.
- **`BCrypt::Password.create(pw, cost: 4)`** — cost too low.
- **`OpenSSL::Cipher.new('aes-256-ecb')`** — ECB.
- **Hardcoded encryption key** in source.
- **`OpenSSL::SSL::VERIFY_NONE`** in HTTP clients.

## A05 Injection

### SQL injection
- **ActiveRecord `where("name = '#{name}'")`** — string interpolation.
- **`find_by_sql("... #{x}")`** — interpolation.
- **`where(query_string)`** when `query_string` comes from params.
- **`order(params[:sort])`** — order-based injection in older Rails versions.
- Safe: `where(name: name)`, `where("name = ?", name)`, `sanitize_sql_array`.

### Command injection
- **`` `cmd #{user}` ``** (backticks) with user input.
- **`system("cmd #{user}")`**, `exec("cmd #{user}")`, `IO.popen("sh -c cmd #{user}")`.
- **`Open3.capture2("cmd #{user}")`**.

### Code injection
- **`eval(user_input)`** — RCE.
- **`Object.const_get(user_input)`** without an allow-list — class instantiation attack.
- **`send(user_input)`** — method invocation by name; check for allow-list.

### Template injection
- **ERB** — `<%= raw user_input %>`, `<%== user_input %>`, `user_input.html_safe`.
- **`ERB.new(user_input).result`** — RCE.

### Path traversal
- **`File.read(File.join(base, params[:file]))`** — `File.join` doesn't strip `..`.
- **`send_file(params[:path])`** without verification.

### XXE
- **`Nokogiri::XML(xml)`** — does not resolve external entities by default in modern versions, but `Nokogiri::XML::ParseOptions::DTDLOAD` enabled is a red flag.

## A06 Insecure Design

- **Password reset token = `SecureRandom.hex(8)`** (64 bits — too short).
- **Reset tokens without `reset_password_sent_at` expiry check**.

## A07 Authentication Failures

- **Devise `config.password_length = 4..128`** — minimum password too short.
- **JWT decoding without algorithm allow-list** in `jwt` gem.
- **Custom session cookie with `httponly: false`**.
- **`reset_session` not called on privilege change** — session fixation.

## A08 Software or Data Integrity Failures

- **`Marshal.load(user_data)`** — RCE.
- **`YAML.load(user_data)`** without `safe_load` — RCE on older Psych. Use `YAML.safe_load`.
- **`Oj.load(user_data, mode: :object)`** — RCE via class deserialization.

## A10 Mishandling of Exceptional Conditions

- **`rescue => e; logger.error(e); end`** around auth check.
- **`rescue nil`** that hides authorization exceptions.

## Common files / locations to prioritize

- `config/application.rb`, `config/environments/production.rb`
- `config/initializers/**`
- `config/routes.rb`
- `app/controllers/**`, `app/policies/**`
- `app/models/**` (concerns around mass assignment)
- `Gemfile`, `Gemfile.lock`
