# Run Template Action

_(Coming Soon)_

Execute pre-configured command templates on your Underleaf servers with parameter substitution.

## Planned Features

- Execute command templates by name or ID
- Parameter substitution with validation
- Template-specific defaults
- Reusable configurations across workflows

## Planned Usage

```yaml
- name: Run deployment template
  uses: ambientlabscomputing/underleaf-github-actions/run-template@v1
  with:
    api-token: ${{ secrets.UNDERLEAF_API_TOKEN }}
    organization-id: ${{ secrets.UNDERLEAF_ORG_ID }}
    template-name: 'production-deploy'
    parameters: |
      {
        "version": "${{ github.sha }}",
        "environment": "production"
      }
    tags: '{"environment":"production"}'
```

## Roadmap

This action is planned for a future release. It will support:

1. **Template Execution**: Run pre-configured commands from your Underleaf dashboard
2. **Parameter Validation**: Ensure required parameters are provided
3. **Smart Defaults**: Use template defaults with override capability
4. **Targeting Options**: Same flexible server targeting as run-command

---

Stay tuned for updates!
