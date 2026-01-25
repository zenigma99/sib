---
layout: default
title: Security Hardening - SIEM in a Box
---

# Security Hardening

Practical steps to secure a production SIB deployment.

[← Back to Home](index.md)

---

## 1) Lock Down External Ports

Only expose what you need. By default:
- **Grafana** (3000) is public-facing
- **Sidekick API** (2801) is public-facing (required for fleet)
- **VictoriaLogs** (9428) and **VictoriaMetrics** (8428) should remain internal
- Or **Loki** (3100) and **Prometheus** (9090) if using `STACK=grafana`

Use a firewall to restrict access to trusted IP ranges.

---

## 2) Change Default Passwords

Set a strong Grafana admin password in `.env` before install:

```bash
GRAFANA_ADMIN_PASSWORD=your-strong-password
```

---

## 3) TLS and Reverse Proxy

Place Grafana behind a reverse proxy (Nginx/Caddy/Traefik) and enable TLS.
This lets you:
- Terminate HTTPS
- Add auth (basic auth/OIDC)
- Rate-limit access

---

## 4) Restrict Fleet Ingress

Allow only fleet subnet to reach Sidekick (and storage if remote enabled):

```bash
# Sidekick (always needed for fleet)
ufw allow from 192.168.1.0/24 to any port 2801

# VictoriaMetrics stack (default)
ufw allow from 192.168.1.0/24 to any port 9428  # VictoriaLogs
ufw allow from 192.168.1.0/24 to any port 8428  # VictoriaMetrics

# Or Grafana stack (STACK=grafana)
# ufw allow from 192.168.1.0/24 to any port 3100  # Loki
# ufw allow from 192.168.1.0/24 to any port 9090  # Prometheus
```

---

## 5) Enable mTLS for Fleet Communication

For encrypted and authenticated communication between fleet agents and the SIB server, enable mutual TLS (mTLS).

### Fresh Install with mTLS

For new SIB installations, generate certificates **before** running `make install`:

```bash
# 1. Configure environment
cp .env.example .env
sed -i 's/MTLS_ENABLED=false/MTLS_ENABLED=true/' .env

# 2. Generate certificates (CA, server, local client)
make generate-certs

# 3. Generate client certificates for fleet hosts (optional)
make generate-fleet-certs

# 4. Install SIB (will automatically use mTLS)
make install
```

> **Important:** Certificates must exist before `make install` when `MTLS_ENABLED=true`. The install will fail if certificates are missing.

### Enable mTLS on Existing Install

If SIB is already running without mTLS:

```bash
# 1. Generate certificates
make generate-certs

# 2. Enable mTLS in .env
echo "MTLS_ENABLED=true" >> .env

# 3. Reinstall alerting and detection stacks
make install-alerting
make install-detection

# 4. Deploy to fleet with mTLS
make deploy-fleet
```

### What mTLS Protects

| Communication Path | Without mTLS | With mTLS |
|--------------------|--------------|-----------|
| Falco → Falcosidekick | HTTP (plaintext) | HTTPS + client cert |
| Alloy → Storage | HTTP (plaintext) | HTTPS + client cert |

### Certificate Management

- **Generate CA and server certs**: `make generate-certs`
- **Generate client cert for a host**: `make generate-client-cert HOST=hostname`
- **Generate certs for all fleet hosts**: `make generate-fleet-certs`
- **Verify certificates**: `make verify-certs`
- **Rotate all certificates**: `make rotate-certs`

### Certificate Locations

| Location | Purpose |
|----------|---------|
| `certs/ca/ca.crt` | Certificate Authority (public) |
| `certs/ca/ca.key` | CA private key (SECRET!) |
| `certs/server/server.crt` | Server certificate |
| `certs/clients/*.crt` | Client certificates |

### Ansible Configuration

Enable mTLS in `ansible/inventory/group_vars/all.yml`:

```yaml
mtls_enabled: true
```

Or pass it as an extra variable:

```bash
make deploy-fleet ARGS="-e mtls_enabled=true"
```

---

## 6) Reduce Data Retention

Adjust retention to avoid disk exhaustion. Configure in `.env`:

```bash
# VictoriaMetrics stack (default)
VICTORIALOGS_RETENTION_PERIOD=168h    # 7 days
VICTORIAMETRICS_RETENTION_PERIOD=15d  # 15 days

# Grafana stack (STACK=grafana)
LOKI_RETENTION_PERIOD=168h
PROMETHEUS_RETENTION_TIME=15d
```

---

## 7) Backups

Back up Grafana and storage data volumes regularly. Ensure your backup target is secure and encrypted.

```bash
# Docker volumes to back up:
# - grafana_grafana-data
# - storage_victorialogs-data (or storage_loki-data)
# - storage_victoriametrics-data (or storage_prometheus-data)
```

---

## 8) Run Health Checks

```bash
make health
make doctor
```

---

## 9) Monitor Resource Usage

Track disk and memory growth. Tune retention and sampling as needed.

---

[← Back to Home](index.md)
