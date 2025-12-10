# Contributing to Underleaf GitHub Actions

Thank you for your interest in contributing! This document provides guidelines for contributing to this repository.

## Development Setup

### Prerequisites

- Bash (for composite actions)
- `jq` command-line JSON processor
- `curl` for API requests
- A GitHub account
- Access to a Underleaf organization for testing

### Local Testing

Since these are composite actions, you can test them locally by:

1. Creating a test workflow in your repository
2. Referencing your local branch:
   ```yaml
   uses: your-username/underleaf-github-actions/run-command@your-branch
   ```
3. Running the workflow

## Adding a New Action

### Structure

Each action should be in its own directory:

```
action-name/
├── action.yml      # Action definition
└── README.md       # Documentation
```

### Action Definition Requirements

1. **Metadata**: Include name, description, author, and branding
2. **Inputs**: Document all inputs with descriptions, required status, and defaults
3. **Outputs**: Define all outputs clearly
4. **Validation**: Validate inputs before making API calls
5. **Error Handling**: Provide clear error messages
6. **Security**: Never log sensitive data (tokens, secrets)

### Example Structure

```yaml
name: 'Action Name'
description: 'Clear description'
author: 'Ambient Labs'

branding:
  icon: 'icon-name'  # From feather icons
  color: 'green'

inputs:
  api-token:
    description: 'API token'
    required: true
  # ... other inputs

outputs:
  result:
    description: 'Output description'
    value: ${{ steps.main.outputs.result }}

runs:
  using: 'composite'
  steps:
    - name: Validate
      shell: bash
      run: |
        # Validation logic
    
    - name: Execute
      id: main
      shell: bash
      run: |
        # Main logic
```

## Documentation Standards

### README Structure

Each action should have:

1. **Title and description**
2. **Usage example** (minimal)
3. **Inputs table** (all parameters)
4. **Outputs table** (all outputs)
5. **Detailed examples** (common use cases)
6. **Security notes**
7. **Troubleshooting** (if applicable)

### Code Comments

- Comment complex logic
- Explain API interactions
- Document environment variable usage

## Testing

### Manual Testing Checklist

Before submitting a PR, test:

- [ ] Valid inputs work correctly
- [ ] Invalid inputs fail with clear errors
- [ ] API errors are handled gracefully
- [ ] Outputs are set correctly
- [ ] Secrets are not exposed in logs
- [ ] Works with all targeting options (if applicable)

### Test Cases

Create test workflows for:

1. Happy path (valid inputs)
2. Missing required inputs
3. Invalid input formats
4. API errors (401, 403, 500)
5. Network failures

## Pull Request Process

1. **Fork** the repository
2. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make changes** following the guidelines
4. **Test thoroughly** using the checklist above
5. **Update documentation** (README, examples)
6. **Commit** with clear messages:
   ```
   feat: add new action for X
   fix: resolve issue with Y
   docs: update README for Z
   ```
7. **Push** to your fork
8. **Open a PR** with:
   - Clear title and description
   - Link to related issues
   - Test results
   - Breaking changes (if any)

## Code Review

PRs will be reviewed for:

- Functionality and correctness
- Code quality and style
- Documentation completeness
- Security considerations
- Test coverage

## Versioning

We follow [Semantic Versioning](https://semver.org/):

- **Major** (v1.0.0): Breaking changes
- **Minor** (v1.1.0): New features (backwards compatible)
- **Patch** (v1.0.1): Bug fixes

## Security

### Reporting Vulnerabilities

**DO NOT** open public issues for security vulnerabilities.

Instead, email: security@ambientlabs.io

### Security Best Practices

- Never log sensitive data
- Validate all inputs
- Use secure API communication (HTTPS)
- Follow principle of least privilege
- Keep dependencies updated

## Style Guide

### Bash Scripts

```bash
# Use set -e for error handling
set -e

# Quote variables
echo "$variable"

# Use meaningful variable names
api_token="$1"

# Add comments for complex logic
# Build JSON payload for API request
payload=$(cat <<EOF
{
  "key": "value"
}
EOF
)
```

### YAML

```yaml
# Use 2 spaces for indentation
# Keep lines under 100 characters
# Use single quotes for strings
# Add blank lines between logical sections
```

## Getting Help

- 📖 Read the [documentation](https://docs.underleaf.dev)
- 💬 Join our [Discord](https://discord.gg/underleaf)
- 📧 Email: support@ambientlabs.io

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Underleaf! 🚀
