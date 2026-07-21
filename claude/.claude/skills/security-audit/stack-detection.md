# Tech Stack Detection

The audit must adapt to whatever the repo actually uses. Run these checks against the current working directory using `Glob` / `Read` (not `Bash`). Detect **all** stacks present — many repos are polyglot (backend + SPA + IaC).

## Detection signals

| Stack | Strong signals (file globs or contents) | Stack file |
|-------|------------------------------------------|------------|
| .NET Framework / .NET (Core) | `*.sln`, `*.csproj`, `*.vbproj`, `Web.config`, `App.config`, `global.json`, `nuget.config`, `Directory.Packages.props` | `stacks/dotnet.md` |
| Node.js (server) | `package.json` containing `"express"`, `"@nestjs/*"`, `"fastify"`, `"koa"`, `"hapi"`, or a `server.js` / `app.js` with `http.createServer` | `stacks/node.md` |
| **Next.js** | `package.json` containing `"next"`; presence of `next.config.{js,mjs,ts}`, `app/**/page.{tsx,jsx}`, `pages/**/*.{tsx,jsx}`, `middleware.{ts,js}`, files starting with `'use server'` | `stacks/nextjs.md` (also load `react.md` and `node.md`) |
| **React** (client app) | `package.json` containing `"react"` and `"react-dom"`. Distinguish from Next.js: if `"next"` is also present, treat as Next.js + React (load both). Otherwise it's a CRA/Vite/Webpack SPA. | `stacks/react.md` |
| Python web | `requirements.txt` / `pyproject.toml` / `Pipfile` containing `django`, `flask`, `fastapi`, `starlette`, `tornado`, `bottle`; or `manage.py`, `wsgi.py`, `asgi.py` | `stacks/python.md` |
| Java / JVM | `pom.xml`, `build.gradle`, `build.gradle.kts`, `*.java`, `*.kt` with `@RestController` / `@Controller` / `@SpringBootApplication` | `stacks/java.md` |
| Go | `go.mod`, `go.sum`, `*.go` importing `net/http`, `github.com/gin-gonic/gin`, `github.com/labstack/echo`, `github.com/gofiber/fiber` | `stacks/go.md` |
| Ruby / Rails | `Gemfile` containing `rails`, `sinatra`, `roda`; `config/routes.rb`; `app/controllers/**/*.rb` | `stacks/ruby.md` |
| PHP | `composer.json` containing `laravel/framework`, `symfony/symfony`, `slim/slim`; `artisan`; `*.php` with `<?php` | `stacks/php.md` |
| Vue / Angular / Svelte / Solid / Astro SPA | `package.json` containing `vue`, `@angular/core`, `svelte`, `solid-js`, `astro`, `nuxt` | `stacks/frontend-spa.md` |
| Infrastructure / DevOps | `Dockerfile`, `docker-compose.yml`, `*.tf`, `*.bicep`, `k8s/**/*.yaml`, `.github/workflows/*.yml`, `azure-pipelines.yml`, `.gitlab-ci.yml`, `Jenkinsfile` | `stacks/infrastructure.md` |

## Database / data-layer signals (informs SQL-injection patterns)

Worth noting in the stack profile, even though they don't have their own pattern files:

- **SQL Server** — `Web.config` with `Data Source=`, `*.csproj` referencing `System.Data.SqlClient` / `Microsoft.Data.SqlClient`
- **PostgreSQL** — `Npgsql`, `psycopg2`, `pg`, `pgx`, `database/sql` with `pq`
- **MySQL / MariaDB** — `MySql.Data`, `mysql2`, `PyMySQL`, `mysql-connector`
- **MongoDB** — `mongoose`, `pymongo`, `MongoDB.Driver`
- **Elasticsearch / OpenSearch** — `NEST`, `Elasticsearch.Net`, `@elastic/elasticsearch`, `elasticsearch-py`
- **Redis** — `StackExchange.Redis`, `redis`, `ioredis`, `aioredis`
- **RabbitMQ / Kafka / SQS** — `RabbitMQ.Client`, `amqplib`, `pika`, `confluent-kafka`, `kafkajs`

## Authentication signals (informs A07 audit)

- **Forms Auth (.NET classic)** — `<authentication mode="Forms">` in `Web.config`
- **ASP.NET Identity / Identity Server** — `Microsoft.AspNet.Identity`, `IdentityServer4`
- **JWT** — `System.IdentityModel.Tokens.Jwt`, `jsonwebtoken`, `PyJWT`, `jjwt`, `golang-jwt`
- **OAuth/OIDC** — `Microsoft.Owin.Security.OpenIdConnect`, `passport`, `authlib`, `spring-security-oauth2`
- **Session cookies** — `express-session`, `Flask-Session`, custom cookie middleware

Capture these in the Phase 1 stack profile so Phase 2 sub-agents can target them.

## Polyglot examples

A repo with `*.csproj` + `package.json` (with `react`, no `next`) + `Dockerfile` + `.github/workflows/*.yml` should load:

- `stacks/dotnet.md`
- `stacks/react.md`
- `stacks/infrastructure.md`

A Next.js app with `package.json` containing both `next` and `react` should load:

- `stacks/nextjs.md` (primary)
- `stacks/react.md` (client component patterns)
- `stacks/node.md` (general Node patterns for server code)

Findings still bucket by OWASP, not by stack. When a finding lives on the Next.js server side, label it explicitly (`runtime: Server | Edge | Client`) so reviewers can tell which environment is affected.

## Unknown / exotic stacks

If none of the signals match (Elixir/Phoenix, Rust/Actix, Clojure, Crystal, Haskell, …):

1. Identify the HTTP framework and ORM by reading the entry-point file.
2. Apply the OWASP Top 10:2025 categories with first-principles analysis.
3. Add a coverage note: "No stack pattern file existed for `<lang/framework>`; applied general OWASP framework. Consider adding `stacks/<name>.md`."

Never skip the audit because the stack is unknown.
