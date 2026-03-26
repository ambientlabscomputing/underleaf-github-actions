# Underleaf GitHub Actions

CI/CD integration for the [Underleaf](https://underleafdev.com) platform. Deploy services,
expose preview URLs, sync secrets, and run commands on your server fleet — all from GitHub
Actions.

## Actions

| Action | Description |
|--------|-------------|
| [`deploy`](deploy/) | Push-to-deploy from your repo. Reads `.underleaf/deploy.yaml` and applies it. Idempotent — re-runs update the existing deployment. |
| [`tunnel`](tunnel/) | Open a public HTTPS endpoint to a port on a server for the lifetime of the job. Auto-closes on finish. |
| [`channel`](channel/) | Create a private mTLS relay between two servers. Returns a signed grant JWT. Auto-closes on finish. |
| [`wait-for-job`](wait-for-job/) | Block until an async Underleaf job completes, fails, or times out. |
| [`run-command`](run-command/) | Execute an ad-hoc shell command on one or more servers. |
| [`run-template`](run-template/) | Execute a saved command template with input parameters. |
| [`infra-apply`](infra-apply/) | Apply an infrastructure manifest YAML file. |

## Quick start

```yaml
# .github/workflows/deploy.yml
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

Add `UNDERLEAF_API_TOKEN` and `UNDERLEAF_ORG_ID` to your repository secrets
(**Settings → Secrets → Actions**) and you're done.

## Documentation

See [ACTION_README.md](ACTION_README.md) for the full reference — inputs, outputs, and
examples for every action.

## License

MIT License — see [LICENSE](LICENSE) for details.
