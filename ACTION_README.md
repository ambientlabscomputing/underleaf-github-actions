# Underleaf GitHub Actions

Execute commands and templates on your Underleaf servers from GitHub Actions workflows.

## Available Actions

### 1. [Run Command](#run-command-action)
Execute arbitrary shell commands on your servers.

### 2. [Run Template](#run-template-action)
Execute pre-defined command templates with input parameters.

---

## Run Command Action

Execute commands on your Underleaf servers from GitHub Actions workflows.

### Usage

```yaml
- name: Run deployment command
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'npm run deploy'
    work-dir: '/var/www/app'
    tags: '{"environment":"production","app":"api"}'
```

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-url` | Underleaf API URL | No | `https://api.underleafdev.com` |
| `api-token` | Underleaf API token (must start with `uf_`) | Yes | - |
| `organization-id` | Organization ID | Yes | - |
| `command` | Command to execute | Yes | - |
| `work-dir` | Working directory for command execution | No | `''` |
| `timeout` | Command timeout in seconds | No | `300` |
| `all-servers` | Run on all servers in the organization | No | `false` |
| `server-ids` | Comma-separated list of server IDs | No | `''` |
| `tags` | JSON object of tags to filter servers | No | `''` |
| `env-vars` | JSON object of environment variables | No | `''` |

### Outputs

| Output | Description |
|--------|-------------|
| `job-id` | Job ID for tracking command execution |
| `timestamp` | Timestamp of command execution |

### Server Targeting

You must specify at least one of the following targeting options:

#### 1. All Servers
Run on all servers in your organization:
```yaml
with:
  all-servers: 'true'
```

#### 2. Specific Server IDs
Target specific servers by ID:
```yaml
with:
  server-ids: 'server-id-1,server-id-2,server-id-3'
```

#### 3. Tag-based Filtering
Target servers matching specific tags:
```yaml
with:
  tags: '{"environment":"production","region":"us-east-1"}'
```

### Examples

#### Deploy to production servers
```yaml
- name: Deploy to production
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: './deploy.sh'
    work-dir: '/opt/app'
    timeout: 600
    tags: '{"environment":"production"}'
    env-vars: '{"DEPLOY_VERSION":"${{ github.sha }}"}'
```

#### Run database migration
```yaml
- name: Run migrations
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'npm run migrate'
    server-ids: 'primary-db-server-id'
```

#### Restart services across all servers
```yaml
- name: Restart services
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'systemctl restart myapp'
    all-servers: 'true'
```

#### Execute with captured output
```yaml
- name: Deploy application
  id: deploy
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'echo "Deploying version $VERSION"'
    tags: '{"app":"web"}'
    env-vars: '{"VERSION":"1.2.3"}'

- name: Print job details
  run: |
    echo "Job ID: ${{ steps.deploy.outputs.job-id }}"
    echo "Executed at: ${{ steps.deploy.outputs.timestamp }}"
```

---

## Run Template Action

Execute pre-defined command templates with dynamic input parameters.

### Usage

```yaml
- name: Deploy using template
  uses: ambientlabscomputing/underleaf-github-actions/run-template@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    template-id: 'tpl_abc123xyz'
    inputs: '{"version":"${{ github.ref_name }}","environment":"production"}'
    tags: '{"app":"api"}'
```

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-url` | Underleaf API URL | No | `https://api.underleafdev.com` |
| `api-token` | Underleaf API token (must start with `uf_`) | Yes | - |
| `organization-id` | Organization ID | Yes | - |
| `template-id` | Template ID to execute | Yes | - |
| `inputs` | JSON object of input values for template variables | No | `{}` |
| `all-servers` | Run on all servers in the organization | No | `false` |
| `server-ids` | Comma-separated list of server IDs | No | `''` |
| `tags` | JSON object of tags to filter servers | No | `''` |

### Outputs

| Output | Description |
|--------|-------------|
| `job-id` | Job ID for tracking template execution |
| `template-id` | Template ID that was executed |
| `timestamp` | Timestamp of template execution |
| `trigger-source` | Source of the trigger (manual, cron) |

### Server Targeting

Templates use the same targeting options as commands (see [Server Targeting](#server-targeting) above).

### Examples

#### Deploy with version parameter
```yaml
- name: Deploy version
  uses: ambientlabscomputing/underleaf-github-actions/run-template@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    template-id: 'tpl_deploy_app'
    inputs: '{"version":"${{ github.ref_name }}","rollback":"false"}'
    tags: '{"environment":"production"}'
```

#### Run maintenance template
```yaml
- name: Clear cache
  uses: ambientlabscomputing/underleaf-github-actions/run-template@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    template-id: 'tpl_clear_cache'
    all-servers: 'true'
```

#### Template with multiple inputs
```yaml
- name: Database backup
  id: backup
  uses: ambientlabscomputing/underleaf-github-actions/run-template@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    template-id: 'tpl_db_backup'
    inputs: |
      {
        "database": "production_db",
        "backup_path": "/backups/${{ github.run_id }}",
        "compress": "true"
      }
    server-ids: 'db-primary-001'

- name: Print backup job details
  run: |
    echo "Job ID: ${{ steps.backup.outputs.job-id }}"
    echo "Template: ${{ steps.backup.outputs.template-id }}"
    echo "Triggered: ${{ steps.backup.outputs.trigger-source }}"
```

---

## Security

- Store your API token in [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- Never commit tokens to your repository
- Use the minimum required scopes for your API tokens
- For commands: API tokens must have `write:commands` scope
- For templates: API tokens must have `write:templates` scope

## API Token Setup

1. Navigate to Settings → API Tokens in your Underleaf dashboard
2. Click "Create New Token"
3. Give it a descriptive name (e.g., "GitHub Actions - Production Deploy")
4. Select scopes: `read:servers`, `write:commands`, `write:templates`, and any other required scopes
5. Set an appropriate expiration period
6. Copy the token and add it to your GitHub repository secrets

## Notes

- Commands and templates are executed asynchronously on target servers
- Both actions return immediately with a job ID for tracking
- Use the Underleaf dashboard or API to monitor job execution and results
- Command/template output and results are available through the Underleaf jobs API
- Templates provide reusability and consistency across deployments

## Backwards Compatibility

The root action path (`ambientlabscomputing/underleaf-github-actions@v1`) is deprecated but still functional. It delegates to the `run-command` action for backwards compatibility. New workflows should use:
- `ambientlabscomputing/underleaf-github-actions/run-command@v2`
- `ambientlabscomputing/underleaf-github-actions/run-template@v2`
