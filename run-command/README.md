# Run Command Action

Execute commands on your Underleaf servers from GitHub Actions workflows.

## Usage

```yaml
- name: Run deployment command
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v1
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'npm run deploy'
    work-dir: '/var/www/app'
    tags: '{"environment":"production","app":"api"}'
```

## Inputs

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

## Outputs

| Output | Description |
|--------|-------------|
| `job-id` | Job ID for tracking command execution |
| `timestamp` | Timestamp of command execution |

## Server Targeting

You must specify at least one of the following targeting options:

### 1. All Servers
Run on all servers in your organization:
```yaml
with:
  all-servers: 'true'
```

### 2. Specific Server IDs
Target specific servers by ID:
```yaml
with:
  server-ids: 'server-id-1,server-id-2,server-id-3'
```

### 3. Tag-based Filtering
Target servers matching specific tags:
```yaml
with:
  tags: '{"environment":"production","region":"us-east-1"}'
```

## Examples

### Deploy to production servers
```yaml
- name: Deploy to production
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v1
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: './deploy.sh'
    work-dir: '/opt/app'
    timeout: 600
    tags: '{"environment":"production"}'
    env-vars: '{"DEPLOY_VERSION":"${{ github.sha }}"}'
```

### Run database migration
```yaml
- name: Run migrations
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v1
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'npm run migrate'
    server-ids: 'primary-db-server-id'
```

### Restart services across all servers
```yaml
- name: Restart services
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v1
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'systemctl restart myapp'
    all-servers: 'true'
```

### Execute with captured output
```yaml
- name: Deploy application
  id: deploy
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v1
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

## Security

- Store your API token in [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- Never commit tokens to your repository
- Use the minimum required scopes for your API tokens
- API tokens must have `write:commands` scope to execute commands

## API Token Setup

1. Navigate to Settings → API Tokens in your Underleaf dashboard
2. Click "Create New Token"
3. Give it a descriptive name (e.g., "GitHub Actions - Production Deploy")
4. Select scopes: `read:servers`, `write:commands`, and any other required scopes
5. Set an appropriate expiration period
6. Copy the token and add it to your GitHub repository secrets

## Notes

- Commands are executed asynchronously on target servers
- The action returns immediately with a job ID for tracking
- Use the Underleaf dashboard or API to monitor job execution and results
- Command output and results are available through the Underleaf jobs API
