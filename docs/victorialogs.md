---
layout: default
title: VictoriaLogs Backend - SIEM in a Box
---

# VictoriaLogs Backend

Use VictoriaLogs as an alternative log storage backend to Loki.

[← Back to Home](index.md)

---

## Why VictoriaLogs

- Fast full‑text search over large volumes
- Better handling of high‑cardinality fields
- LogsQL support for analytics‑style queries

---

## Quick Start (Recommended)

Set `LOGS_ENDPOINT=victorialogs` in your `.env` file, then run `make install`:

```bash
# Edit .env (default is loki, change to victorialogs)
sed -i 's/LOGS_ENDPOINT=loki/LOGS_ENDPOINT=victorialogs/' .env

# Install everything - storage, Grafana, alerting, detection
make install
```

This automatically:
- Installs VictoriaLogs + Prometheus (instead of Loki)
- Configures Falcosidekick to send alerts to VictoriaLogs
- Sets up Grafana with VictoriaLogs datasource
- Provisions VictoriaLogs-compatible dashboards

---

## Manual Setup

### 1) Enable the VictoriaLogs Storage Stack

```bash
make install-storage-victorialogs
```

This starts:
- **VictoriaLogs** (port 9428 by default)
- **Prometheus** (port 9090)

---

### 2) Point Falcosidekick to VictoriaLogs

Use the helper target:

```bash
make use-victorialogs-output
```

This configures Falcosidekick to use the Loki‑compatible insert endpoint:
`http://sib-victorialogs:9428/insert`.

To switch back:

```bash
make use-loki-output
```

---

### 3) Switch Grafana Datasource

Use the prebuilt datasource file:

```bash
make use-victorialogs-datasource
```

This uses the VictoriaLogs Grafana plugin (installed automatically by the Grafana container).

### VictoriaLogs Dashboards

VictoriaLogs-specific dashboards are available under **SIEM in a Box / VictoriaLogs**:
- **Events Explorer (VictoriaLogs)** — with AI analysis links
- **Security Overview (VictoriaLogs)**
- **MITRE ATT&CK Coverage (VictoriaLogs)**
- **Fleet Overview (VictoriaLogs)**
- **Risk Scores (VictoriaLogs)**

The Loki dashboards use LogQL and won't show data when VictoriaLogs is the backend.

### AI Analysis with VictoriaLogs

When installing the AI Analysis API, it automatically detects `LOGS_ENDPOINT` and provisions the correct dashboard:

```bash
make install-analysis
```

If Grafana shows “Plugin not registered” (offline or restricted networks), install manually:

```bash
docker exec sib-grafana grafana cli plugins install victoriametrics-logs-datasource
docker restart sib-grafana
```

To switch back to Loki:

```bash
make use-loki-datasource
```

---

### 4) Remote Collectors (Optional)

Expose VictoriaLogs and Prometheus for collectors:

```bash
make enable-remote-victorialogs
```

---

## Switching Between Backends

To switch from VictoriaLogs back to Loki:

```bash
# Edit .env
LOGS_ENDPOINT=loki

# Reinstall or manually switch
make use-loki-output
make use-loki-datasource
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LOGS_ENDPOINT` | `loki` | Storage backend: `loki` or `victorialogs` |
| `VICTORIALOGS_PORT` | `9428` | VictoriaLogs HTTP port |
| `VICTORIALOGS_RETENTION_PERIOD` | `168h` | Log retention (7 days) |

---

[← Back to Home](index.md)
