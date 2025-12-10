# Underleaf GitHub Action

Execute commands on your Underleaf-managed servers directly from GitHub Actions workflows.

## Quick Start

```yaml
- uses: ambientlabscomputing/underleaf-github-actions@v1
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    command: 'npm run deploy'
    tags: '{"environment":"production"}'
```

See [ACTION_README.md](ACTION_README.md) for full documentation.

## License

MIT License - see [LICENSE](LICENSE) for details.
