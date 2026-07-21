# Infrastructure — Audit Patterns

Covers Dockerfile, docker-compose, Kubernetes manifests, Terraform, Bicep, CI/CD YAML (GitHub Actions, Azure DevOps Pipelines, GitLab CI, Jenkinsfile).

Primary OWASP categories: **A02 Security Misconfiguration**, **A03 Software Supply Chain Failures**.

Reminder from the FP filter: pipeline YAML is flagged only when untrusted input directly influences execution or secrets leak in logs.

## A02 Security Misconfiguration

### Dockerfile
- **`USER root`** as the final user in a runtime container (or missing `USER` directive entirely — defaults to root).
- **`--privileged`** in `docker-compose.yml`.
- **Mounting `/var/run/docker.sock`** into containers reachable from user-facing services — container escape.
- **Exposed dev/debug ports** (`6379` for Redis, `5432` for Postgres) bound to `0.0.0.0` instead of `127.0.0.1`.
- **`ENV PASSWORD=...`** with a real password baked into the image layer.

### Kubernetes
- **`securityContext.privileged: true`**.
- **`hostNetwork: true`**, `hostPID: true`, `hostIPC: true`.
- **`runAsUser: 0`** without justification.
- **`allowPrivilegeEscalation: true`** (or default).
- **`RoleBinding` / `ClusterRoleBinding`** granting `cluster-admin` to a namespace service account.
- **Secrets in plain ConfigMaps** instead of `Secret` resources.
- **`hostPath` mounts** of sensitive host paths (`/etc`, `/var/run/docker.sock`).
- **NetworkPolicies absent** with sensitive services — usually drop (hardening).

### Terraform / Bicep
- **S3 bucket with `acl = "public-read"`** or `block_public_acls = false` storing private data.
- **Security Group with `0.0.0.0/0` on port 22 / 3389 / 3306 / 5432**.
- **RDS / SQL with `publicly_accessible = true`**.
- **IAM policies with `"Action": "*", "Resource": "*"`** attached to non-admin principals.
- **KMS `Principal: "*"`** without conditions.

## A03 Software Supply Chain Failures

### Dockerfile
- **`FROM image:latest`** or no tag (`FROM ubuntu`) — non-reproducible. Should be `FROM image@sha256:...` or at minimum a pinned version.
- **`curl ... | bash`**, `wget ... | sh` in `RUN` — pipes external script into shell.
- **`ADD <URL>`** — `ADD` can pull remote files; use `COPY` for local and explicit `curl --tlsv1.2` for remote with checksum.
- **`npm install` / `pip install` without lockfile** — re-resolves versions on each build.

### CI/CD (GitHub Actions example)
- **`actions/checkout@main`** or `@master` — unpinned. Use `@v4` (tag) or commit SHA for third-party actions.
- **Third-party action `org/action@main`** — same.
- **`pull_request_target` trigger combined with `actions/checkout` of the PR ref** — gives the PR's code access to repo secrets. Critical.
- **`run: ${{ github.event.issue.title }}`** — direct interpolation of untrusted text into a shell `run` step → command injection in the runner.
- **`workflow_dispatch` with `inputs.x`** interpolated into `run:` without quoting.
- **Secrets echoed** — `run: echo "${{ secrets.X }}"`.

### Azure DevOps Pipelines
- **`steps: - script: $(params.userInput)`** where `params.userInput` is from an unverified source.
- **`resources.repositories`** pulling from a public repo into a protected pipeline.

## A04 Cryptographic Failures (less common in IaC)

- **Self-signed certs in production** referenced from K8s ingress without `cert-manager` / managed certs.
- **TLS 1.0 / 1.1 enabled** in ingress/listener configs (`ssl_protocols TLSv1 TLSv1.1` in nginx).

## A05 Injection

### Command injection in CI/CD
The big one: any `run:` / `script:` step that **interpolates untrusted Git/issue/PR data into a shell command**:

```yaml
# BAD — title can contain `$(...)` and execute
- run: echo "PR: ${{ github.event.pull_request.title }}"
```

Inputs to treat as untrusted in GitHub Actions:
- `github.event.issue.title`, `.body`, `.comment.body`
- `github.event.pull_request.title`, `.body`, `.head.ref`, `.head.label`, `.head.repo.description`
- `github.head_ref`
- `github.event.review.body`
- `workflow_dispatch` user inputs

Mitigation: pass via env var (`env: TITLE: ${{ ... }}` then use `"$TITLE"` in script) or `actions/github-script`.

## A07 Authentication Failures (infrastructure context)

- **K8s Dashboard exposed without auth**.
- **Elasticsearch / Redis / Mongo / RabbitMQ** with default credentials or no auth, bound to a routable interface.

## A08 Software or Data Integrity Failures

- **Unsigned container images** pulled in production deploys (no `cosign verify`, no admission controller).
- **Helm charts from `helm install x https://random-url/chart.tgz`** without signature.

## Common files / locations to prioritize

- `Dockerfile`, `Dockerfile.*`, `docker-compose*.yml`
- `**/*.tf`, `**/*.bicep`, `**/*.json` (ARM templates)
- `k8s/**`, `**/manifests/*.yaml`, `**/charts/**`
- `.github/workflows/*.yml` (esp. `*.yaml` files with `pull_request_target` or `workflow_run` triggers)
- `azure-pipelines.yml`, `.azure-pipelines/**`
- `.gitlab-ci.yml`
- `Jenkinsfile`, `Jenkinsfile.*`
