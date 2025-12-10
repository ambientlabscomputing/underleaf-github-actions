# Underleaf GitHub Actions

A collection of GitHub Actions for integrating [Underleaf](https://underleaf.dev) server management into your CI/CD pipelines.

## Available Actions

### 🚀 [Run Command](./run-command)
Execute commands on your Underleaf-managed servers directly from GitHub Actions workflows.

```yaml
- uses: ambientlabscomputing/underleaf-github-actions/run-command@v1
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'npm run deploy'
    tags: '{"environment":"production"}'
```

**Features:**
- Execute arbitrary commands on remote servers
- Target servers by ID, tags, or all servers
- Set environment variables and working directory
- Configure command timeout
- Asynchronous execution with job tracking

[View documentation →](./run-command/README.md)

---

### 🔮 Run Template _(Coming Soon)_
Execute pre-configured command templates with parameter substitution.

---

## Getting Started

### 1. Create an API Token

1. Log in to your [Underleaf Dashboard](https://underleafdev.com)
2. Navigate to **Settings → API Tokens**
3. Click **Create New Token**
4. Configure token:
   - Name: `GitHub Actions - [Your Workflow]`
   - Scopes: Select required permissions (minimum: `read:servers`, `write:commands`)
   - Expiration: Choose appropriate duration
5. Copy the token (starts with `uf_`)

### 2. Add Secrets to GitHub

Add these secrets to your GitHub repository:

1. Go to your repository **Settings → Secrets and variables → Actions**
2. Add the following secrets:
   - `UNDERLEAF_API_TOKEN`: Your API token from step 1
   - `UNDERLEAF_ORG_ID`: Your organization ID (found in Underleaf dashboard)

### 3. Use in Your Workflow

Create or update `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Deploy application
        uses: ambientlabscomputing/underleaf-github-actions/run-command@v1
        with:
          api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
          organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
          command: './deploy.sh ${{ github.sha }}'
          work-dir: '/var/www/app'
          tags: '{"environment":"production"}'
```

## Common Use Cases

### Deployment Pipeline
```yaml
- name: Deploy to production servers
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v1
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'kubectl apply -f deployment.yaml'
    tags: '{"environment":"production","role":"k8s-master"}'
```

### Database Migration
```yaml
- name: Run database migrations
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v1
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'npm run migrate:prod'
    server-ids: 'db-primary-server-id'
    timeout: 900
```

### Service Restart
```yaml
- name: Restart application services
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v1
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'systemctl restart myapp'
    all-servers: 'true'
```

### Cache Clearing
```yaml
- name: Clear application cache
  uses: ambientlabscomputing/underleaf-github-actions/run-command@v1
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'redis-cli FLUSHALL'
    tags: '{"service":"redis"}'
```

## Security Best Practices

✅ **Do:**
- Store API tokens in GitHub Secrets
- Use scoped tokens with minimum required permissions
- Set appropriate token expiration periods
- Rotate tokens regularly
- Use different tokens for different workflows/environments

❌ **Don't:**
- Commit tokens to your repository
- Share tokens across multiple organizations
- Use overly permissive token scopes
- Log token values in workflow outputs

## API Token Scopes

Different actions require different scopes:

| Action | Required Scopes |
|--------|----------------|
| `run-command` | `read:servers`, `write:commands` |
| `run-template` | `read:servers`, `read:commands`, `write:commands` |

## Support

- 📖 [Documentation](https://docs.underleaf.dev)
- 💬 [Discord Community](https://discord.gg/underleaf)
- 🐛 [Issue Tracker](https://github.com/ambientlabscomputing/underleaf-github-actions/issues)
- 📧 [Email Support](mailto:support@ambientlabs.io)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](LICENSE) for details.

---

**Made with ❤️ by [Ambient Labs](https://ambientlabs.io)**

