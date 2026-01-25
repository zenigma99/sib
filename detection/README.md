# Detection Stack

This directory contains the Falco runtime security engine configuration.

## Components

| Service | Port | Description |
|---------|------|-------------|
| **Falco** | - | Runtime security detection engine |

## What Falco Detects

Falco monitors system calls and Kubernetes audit events to detect:

- **Container Escapes**: Privileged container access, namespace changes
- **File Integrity**: Writes to sensitive directories (/etc, /usr/bin)
- **Process Anomalies**: Shells in containers, unexpected binaries
- **Network Activity**: Unexpected connections, port scanning
- **Credential Access**: Shadow file access, SSH key theft
- **Persistence**: Cron/systemd modifications

## Configuration

### Falco Configuration
Edit `config/falco.yaml`:
- `json_output`: Enable JSON output for Falcosidekick
- `priority`: Minimum alert priority
- `buffered_outputs`: Performance optimization
- `http_output`: Output destination (Falcosidekick)

### mTLS Configuration

For production deployments, enable mTLS to encrypt communication with Falcosidekick.

```bash
# Set environment variable
echo "MTLS_ENABLED=true" >> .env

# Generate certificates (if not already done)
make generate-certs

# Reinstall detection stack
make install-detection
```

When `MTLS_ENABLED=true`, Falco's http_output is configured with:

```yaml
http_output:
  enabled: true
  url: "https://sib-sidekick:2801/"
  insecure: false
  ca_cert: /etc/falco/certs/ca/ca.crt
  client_cert: /etc/falco/certs/clients/local.crt
  client_key: /etc/falco/certs/clients/local.key
  mtls: true
```

See [Security Hardening](../docs/security-hardening.md) for complete mTLS documentation.

### Rules
- `config/rules/falco_rules.yaml`: Default rules (from Falco)
- `config/rules/custom_rules.yaml`: Your custom rules

## Custom Rules Example

```yaml
- rule: Detect Cryptocurrency Mining
  desc: Detect crypto mining processes
  condition: >
    spawned_process and 
    proc.name in (xmrig, minerd, cpuminer)
  output: "Crypto miner detected (user=%user.name cmd=%proc.cmdline)"
  priority: CRITICAL
  tags: [cryptomining]
```

## Troubleshooting

### Falco Won't Start

Falco requires privileged access:
```bash
docker run --rm --privileged alpine echo "test"
```

### High CPU Usage

Adjust buffer sizes in `falco.yaml`:
```yaml
syscall_buf_size_preset: 4
```

### Check Dropped Events

```bash
docker exec sib-falco falco --stats-interval=1
```
