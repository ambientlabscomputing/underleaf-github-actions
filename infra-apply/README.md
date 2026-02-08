# Underleaf Infrastructure Apply Action

Apply declarative infrastructure manifests to Underleaf from GitHub Actions workflows.

## Usage

```yaml
- name: Apply infrastructure
  uses: ambientlabscomputing/underleaf-github-actions/infra-apply@v2
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    manifest-path: ./infra.yaml
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-url` | Underleaf API URL | No | `https://api.underleafdev.com` |
| `api-token` | Underleaf API token (format: `uf_xxxxx_...`) | Yes | - |
| `organization-id` | Organization ID | Yes | - |
| `manifest-path` | Path to infrastructure manifest file | No | `./infra.yaml` |
| `auto-approve` | Skip confirmation (always true in CI) | No | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `manifest-name` | Name of the manifest that was applied |
| `success` | Whether the apply succeeded (`true`/`false`) |
| `operations-count` | Number of operations successfully executed |

## Example Workflows

### Apply on Push to Main

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths:
      - 'infra.yaml'

jobs:
  apply:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Apply Underleaf infrastructure
        uses: ambientlabscomputing/underleaf-github-actions/infra-apply@v2
        with:
          api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
          organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
          manifest-path: ./infra.yaml
```

### Preview on Pull Request

For PR previews, you can use the plan-only workflow (TODO: create infra-plan action).

## Manifest Format

The manifest file is a YAML file describing deployments and clusters:

```yaml
version: "1"
name: production-edge

deployments:
  - name: Web Proxy
    slug: web-proxy
    targeting:
      mode: tags
      tags:
        environment: production
    services:
      - name: nginx
        image: nginx:1.25
        ports: ["80:80", "443:443"]
        networks: [frontend]
    networks:
      - name: frontend
        driver: bridge

clusters:
  - name: edge-site-alpha
    servers:
      - server-1
      - server-2
      - server-3
```

## How It Works

1. **Validate**: The action validates the manifest file exists
2. **Plan**: Computes what changes would be made (create/update/delete operations)
3. **Display**: Writes the plan to the GitHub Actions step summary
4. **Apply**: Executes the plan on the Underleaf control plane
5. **Results**: Reports success/failure for each operation

The plan and apply results are displayed in the GitHub Actions UI, making it easy to review changes in your CI/CD pipeline.

## State Management

Unlike Terraform, you don't need to manage state files. The Underleaf Server API stores the last-applied manifest for each named infrastructure stack. The action is stateless - it just sends the manifest to the API.

## Authentication

This action requires an Underleaf API token with the following scopes:
- `write:deployments`
- `write:servers`
- `read:servers`

Create a token via:
```bash
ufctl auth login
# Then create token in the UI or via API
```

Store the token as a GitHub secret: `UNDERLEAF_API_TOKEN`

## Entitlements

The apply operation checks your organization's entitlements:
- `max_deployments` - Maximum number of deployments
- `max_nodes` - Maximum number of cluster members
- `deployments_actuations_per_month` - Monthly deployment apply quota

If you exceed limits, the action will fail with a clear error message.

## Support

For issues or questions:
- GitHub: https://github.com/ambientlabscomputing/underleaf
- Docs: https://docs.underleafapp.com
