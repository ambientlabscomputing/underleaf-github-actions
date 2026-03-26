# Underleaf GitHub Actions

Bring your Underleaf platform into your CI/CD pipelines — deploy services from your repo, expose
preview URLs, create secure inter-server channels, and run commands on your fleet, all from
familiar GitHub Actions syntax.

## Available Actions

| Action | What it does |
|--------|--------------|
| [`deploy`](#deploy-action) | Push-to-deploy: automatically deploy your repo to Underleaf servers |
| [`tunnel`](#tunnel-action) | Create a public HTTPS tunnel to a port on a server for the duration of the job |
| [`channel`](#channel-action) | Create a private mTLS relay between two servers and get a signed grant JWT |
| [`wait-for-job`](#wait-for-job-action) | Block until an async Underleaf job completes |
| [`run-command`](#run-command-action) | Execute an ad-hoc shell command on servers |
| [`run-template`](#run-template-action) | Execute a saved command template with input parameters |
| [`infra-apply`](#infra-apply-action) | Apply an infrastructure manifest YAML file |

---

## Quick start

Add these secrets to your repository (**Settings → Secrets → Actions**):

| Secret | Value |
|--------|-------|
| `UNDERLEAF_API_TOKEN` | Your Underleaf API token (`uf_xxxxx_...`) |
| `UNDERLEAF_ORG_ID` | Your organization ID |

Then add a workflow:

```yaml
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Underleaf
        uses: ambientlabscomputing/underleaf-github-actions/deploy@v2
        with:
          api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
          organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
```

That's it. Underleaf reads your `.underleaf/deploy.yaml` manifest from the pushed commit and
takes care of the rest.

---

## Deploy Action

The flagship action: push code and let Underleaf handle the rest. Reads your
`.underleaf/deploy.yaml` manifest from the repository and deploys (or re-deploys) an
application. **Idempotent** — repeated runs on the same branch update the existing deployment
rather than creating a new one.

### Usage

```yaml
- uses: actions/checkout@v4

- name: Deploy
  uses: ambientlabscomputing/underleaf-github-actions/deploy@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
```

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-url` | Underleaf API URL | No | `https://api.underleafdev.com` |
| `api-token` | Underleaf API token | Yes | — |
| `organization-id` | Organization ID | Yes | — |
| `source` | Deployment source ref (`gh:owner/repo@sha` or `local:./path`) | No | auto-detected from `GITHUB_REPOSITORY` + `GITHUB_SHA` |
| `github-token` | Token to authorize Underleaf to pull the repo | No | `github.token` |
| `all-servers` | Deploy to all servers in the organization | No | `false` |
| `server-ids` | Comma-separated list of server IDs (overrides manifest targeting) | No | `''` |
| `tags` | JSON tag filter to select servers (overrides manifest targeting) | No | `''` |
| `wait` | Wait for the deployment to finish before the step completes | No | `true` |
| `timeout` | Max seconds to wait | No | `600` |
| `poll-interval` | Seconds between status checks | No | `10` |

### Outputs

| Output | Description |
|--------|-------------|
| `deployment-id` | Internal deployment ID |
| `job-id` | Job ID for the current apply operation |
| `slug` | Human-readable deployment slug |
| `status` | Final status (`success` / `failure`) — only set when `wait=true` |
| `public-url` | Public URL exposed by the deployment (if configured in the manifest) |

### Examples

#### Push-to-deploy on main
```yaml
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ambientlabscomputing/underleaf-github-actions/deploy@v2
        with:
          api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
          organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
```

#### Deploy and use the public URL downstream
```yaml
- name: Deploy
  id: deploy
  uses: ambientlabscomputing/underleaf-github-actions/deploy@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}

- name: Run smoke tests
  run: npx playwright test --base-url "${{ steps.deploy.outputs.public-url }}"
```

#### Fire-and-forget (don't block the CI job)
```yaml
- uses: ambientlabscomputing/underleaf-github-actions/deploy@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    wait: 'false'
```

---

## Tunnel Action

Expose any port on an Underleaf server as a public HTTPS URL for the lifetime of the GitHub
Actions job. The tunnel is automatically deleted when the job finishes (success or failure).

### Usage

```yaml
- name: Open preview tunnel
  id: tunnel
  uses: ambientlabscomputing/underleaf-github-actions/tunnel@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    port: 3000
    server-id: ${{ vars.STAGING_SERVER_ID }}

- name: Run end-to-end tests
  run: npx playwright test --base-url "${{ steps.tunnel.outputs.public-url }}"
```

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-url` | Underleaf API URL | No | `https://api.underleafdev.com` |
| `api-token` | Underleaf API token | Yes | — |
| `organization-id` | Organization ID | Yes | — |
| `port` | Local port on the target server to expose (1–65535) | Yes | — |
| `server-id` | ID of the server to tunnel into | No | `''` |
| `hostname` | Custom subdomain for the public URL | No | auto-assigned |
| `all-servers` | Target all servers | No | `false` |
| `server-ids` | Comma-separated server IDs | No | `''` |
| `tags` | JSON tag filter | No | `''` |

> **Note:** You must provide either `server-id` or one of the targeting options (`all-servers`,
> `server-ids`, `tags`).

### Outputs

| Output | Description |
|--------|-------------|
| `tunnel-id` | Tunnel ID |
| `public-url` | Public HTTPS URL |
| `hostname` | Assigned subdomain |

### PR preview environment example
```yaml
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy preview
        id: deploy
        uses: ambientlabscomputing/underleaf-github-actions/deploy@v2
        with:
          api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
          organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
          tags: '{"environment":"preview"}'

      - name: Open tunnel
        id: tunnel
        uses: ambientlabscomputing/underleaf-github-actions/tunnel@v2
        with:
          api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
          organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
          port: 8080
          tags: '{"environment":"preview"}'

      - name: Comment preview URL on PR
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `🚀 Preview: ${{ steps.tunnel.outputs.public-url }}`
            })

      # Tunnel auto-closes when the job ends
```

---

## Channel Action

Create a private, mTLS-secured relay channel between two Underleaf servers. Returns a signed
grant JWT that authorizes access to the channel. The channel is automatically deleted when the
job ends.

A typical use case is syncing secrets between a secrets server and an application server during
deployment — without any of the traffic leaving your private mesh.

### Usage

```yaml
- name: Open channel
  id: channel
  uses: ambientlabscomputing/underleaf-github-actions/channel@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    source-server-id: ${{ vars.SECRETS_SERVER_ID }}
    dest-server-id: ${{ vars.APP_SERVER_ID }}
    purpose: 'secret-sync'
    ttl: '120'

- name: Sync secrets to app server
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'ufctl secrets push --channel "$CHANNEL_GRANT"'
    server-ids: ${{ vars.SECRETS_SERVER_ID }}
    env-vars: '{"CHANNEL_GRANT":"${{ steps.channel.outputs.grant }}"}'
```

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-url` | Underleaf API URL | No | `https://api.underleafdev.com` |
| `api-token` | Underleaf API token | Yes | — |
| `organization-id` | Organization ID | Yes | — |
| `source-server-id` | Server that initiates the connection | Yes | — |
| `dest-server-id` | Destination server ID | No | `''` |
| `deployment-slug` | Route to a deployment by slug (alternative to `dest-server-id`) | No | `''` |
| `service-name` | Service within the deployment (required with `deployment-slug`) | No | `''` |
| `purpose` | Human-readable label for the channel | No | `github-actions` |
| `ttl` | Channel lifetime in seconds (max 3600) | No | `300` |

> **Note:** Provide either `dest-server-id` or `deployment-slug` + `service-name`.

### Outputs

| Output | Description |
|--------|-------------|
| `channel-id` | Channel ID |
| `grant` | Signed grant JWT — pass to agent commands to authorize channel access |
| `status` | Channel status after creation |

---

## Wait for Job Action

Block the workflow step until an Underleaf async job finishes. Useful when you have a `job-id`
from an action run with `wait: 'false'` and want to wait later in the workflow.

### Usage

```yaml
- name: Deploy (fire and forget)
  id: deploy
  uses: ambientlabscomputing/underleaf-github-actions/deploy@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    wait: 'false'

# ... do other things concurrently ...

- name: Confirm deployment succeeded
  uses: ambientlabscomputing/underleaf-github-actions/wait-for-job@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    job-id: ${{ steps.deploy.outputs.job-id }}
    timeout: '300'
```

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-url` | Underleaf API URL | No | `https://api.underleafdev.com` |
| `api-token` | Underleaf API token | Yes | — |
| `organization-id` | Organization ID | Yes | — |
| `job-id` | Job ID to poll | Yes | — |
| `timeout` | Max seconds to wait before failing | No | `600` |
| `poll-interval` | Seconds between status checks | No | `10` |

### Outputs

| Output | Description |
|--------|-------------|
| `status` | Final status: `success` or `failure` |
| `duration` | Total seconds spent waiting |

---

## Run Command Action

Execute an ad-hoc shell command on one or more servers.

### Usage

```yaml
- uses: ambientlabscomputing/underleaf-github-actions/run-command@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'systemctl restart myapp'
    tags: '{"environment":"production"}'
    wait: 'true'
```

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-url` | Underleaf API URL | No | `https://api.underleafdev.com` |
| `api-token` | Underleaf API token | Yes | — |
| `organization-id` | Organization ID | Yes | — |
| `command` | Command to execute | Yes | — |
| `work-dir` | Working directory on the server | No | `''` |
| `timeout` | Command timeout in seconds | No | `300` |
| `all-servers` | Run on all servers | No | `false` |
| `server-ids` | Comma-separated server IDs | No | `''` |
| `tags` | JSON tag filter | No | `''` |
| `env-vars` | JSON object of environment variables to inject | No | `''` |
| `wait` | Wait for the command to finish | No | `false` |
| `poll-interval` | Seconds between status checks (when `wait=true`) | No | `10` |

### Outputs

| Output | Description |
|--------|-------------|
| `job-id` | Job ID |
| `timestamp` | Dispatch timestamp |
| `status` | Final status when `wait=true`: `success` or `failure` |

### Server targeting

Exactly one targeting method must be provided:

```yaml
# all servers
all-servers: 'true'

# specific IDs
server-ids: 'srv-abc123,srv-def456'

# tag filter
tags: '{"environment":"production","region":"us-east-1"}'
```

### Examples

#### Run migration and wait for it
```yaml
- uses: ambientlabscomputing/underleaf-github-actions/run-command@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'npm run migrate'
    server-ids: 'db-primary-001'
    wait: 'true'
    timeout: '900'
```

#### Restart services and capture the job ID
```yaml
- name: Restart
  id: restart
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'systemctl restart myapp'
    all-servers: 'true'

- run: echo "Restart job: ${{ steps.restart.outputs.job-id }}"
```

---

## Run Template Action

Execute a saved command template with dynamic input parameters.

### Usage

```yaml
- uses: ambientlabscomputing/underleaf-github-actions/run-template@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    template-id: 'tpl_deploy_webapp'
    inputs: '{"version":"${{ github.ref_name }}","env":"production"}'
    tags: '{"app":"api"}'
    wait: 'true'
```

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-url` | Underleaf API URL | No | `https://api.underleafdev.com` |
| `api-token` | Underleaf API token | Yes | — |
| `organization-id` | Organization ID | Yes | — |
| `template-id` | Template ID | Yes | — |
| `inputs` | JSON object of template variable values | No | `{}` |
| `all-servers` | Run on all servers | No | `false` |
| `server-ids` | Comma-separated server IDs | No | `''` |
| `tags` | JSON tag filter | No | `''` |
| `wait` | Wait for the template to finish | No | `false` |
| `poll-interval` | Seconds between status checks (when `wait=true`) | No | `10` |
| `timeout` | Max seconds to wait when `wait=true` | No | `600` |

### Outputs

| Output | Description |
|--------|-------------|
| `job-id` | Job ID |
| `template-id` | Executed template ID |
| `timestamp` | Dispatch timestamp |
| `trigger-source` | `manual` or `cron` |
| `status` | Final status when `wait=true`: `success` or `failure` |

### Examples

#### Deploy with a version template
```yaml
- uses: ambientlabscomputing/underleaf-github-actions/run-template@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    template-id: 'tpl_deploy_app'
    inputs: '{"version":"${{ github.ref_name }}","rollback":"false"}'
    tags: '{"environment":"production"}'
    wait: 'true'
```

---

## Infra Apply Action

Apply an infrastructure manifest YAML file to provision or update server resources.

### Usage

```yaml
- uses: ambientlabscomputing/underleaf-github-actions/infra-apply@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    manifest-file: './infra/production.yaml'
```

---

## Security

- Store `UNDERLEAF_API_TOKEN` and `UNDERLEAF_ORG_ID` in **GitHub Secrets** (Settings → Secrets → Actions)
- Never commit tokens to your repository
- The `channel` action returns a one-time grant JWT in the `grant` output — treat it like a secret and do not log it
- Tunnel auto-cleanup deletes the public endpoint as soon as the job ends

## API Token Setup

1. In your Underleaf dashboard, navigate to **Settings → API Tokens**
2. Click **Create New Token**
3. Give it a descriptive name (e.g., `GitHub Actions – production`)
4. Select the required scopes: `read:servers`, `write:deployments`, `write:tunnels`, `write:channels`, `write:commands`, `write:templates`
5. Set an appropriate expiration period
6. Copy the token and add it as a GitHub repository secret named `UNDERLEAF_API_TOKEN`

## Backwards Compatibility

The root path (`ambientlabscomputing/underleaf-github-actions@v1`) is deprecated but still
functional — it delegates to `run-command`. New workflows should use the versioned sub-paths.
