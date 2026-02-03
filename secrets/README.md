# Secrets Directory

This directory stores file-based secrets for SIB services. Files here are **gitignored** and should never be committed.

## Usage

Instead of putting secrets directly in `.env`:

```bash
# Don't do this in production:
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
```

Store the secret in a file and reference it with `_FILE` suffix:

```bash
# In .env:
ANTHROPIC_API_KEY_FILE=/path/to/sib/secrets/anthropic_api_key

# In secrets/anthropic_api_key (this file):
sk-ant-api03-xxxxx
```

## Supported Secrets

| Environment Variable | File-based Alternative |
|---------------------|------------------------|
| `ANTHROPIC_API_KEY` | `ANTHROPIC_API_KEY_FILE` |
| `OPENAI_API_KEY` | `OPENAI_API_KEY_FILE` |
| `SLACK_WEBHOOK_URL` | `SLACK_WEBHOOK_URL_FILE` |
| `PAGERDUTY_ROUTING_KEY` | `PAGERDUTY_ROUTING_KEY_FILE` |
| `AWS_SECRET_ACCESS_KEY` | `AWS_SECRET_ACCESS_KEY_FILE` |

## Creating Secret Files

```bash
# Create a secret file (ensure no trailing newline)
echo -n "sk-ant-api03-xxxxx" > secrets/anthropic_api_key

# Set restrictive permissions
chmod 600 secrets/anthropic_api_key
```

## Docker Compose Secrets

For production deployments, you can also use Docker Compose secrets:

```yaml
services:
  analysis:
    secrets:
      - anthropic_key
    environment:
      - ANTHROPIC_API_KEY_FILE=/run/secrets/anthropic_key

secrets:
  anthropic_key:
    file: ./secrets/anthropic_api_key
```

## Why File-based Secrets?

1. **Process isolation**: Secrets don't appear in `/proc/*/environ`
2. **Logging safety**: Secrets won't leak into debug logs or error messages
3. **Rotation**: Update the file without restarting containers (for some services)
4. **Integration**: Works with secret managers that write to files (Vault Agent, etc.)
