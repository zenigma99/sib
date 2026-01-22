---
layout: default
title: VictoriaMetrics Stack - SIEM in a Box
---

# VictoriaMetrics Stack

Use VictoriaLogs and/or VictoriaMetrics as alternative storage backends.

[← Back to Home](index.md)

---

## Why VictoriaMetrics?

**VictoriaLogs** (alternative to Loki):
- Fast full‑text search over large volumes
- Better handling of high‑cardinality fields
- LogsQL support for analytics‑style queries

**VictoriaMetrics** (alternative to Prometheus):
- 10x lower memory usage
- Better compression (stores more in less disk space)
- Faster queries on large datasets
- PromQL-compatible (existing dashboards work)

---

## Quick Start (Recommended)

### Option 1: VictoriaLogs only (with Prometheus)

```bash
# Edit .env
LOGS_ENDPOINT=victorialogs
METRICS_ENDPOINT=prometheus  # default

make install
```

### Option 2: Full VictoriaMetrics Stack (recommended for low-resource systems)

```bash
# Edit .env
LOGS_ENDPOINT=victorialogs
METRICS_ENDPOINT=victoriametrics

make install
```

This automatically:
- Installs VictoriaLogs + VictoriaMetrics
- Configures Falcosidekick to send alerts to VictoriaLogs
- Sets up Grafana with both VictoriaLogs and VictoriaMetrics datasources
- Provisions VictoriaLogs-compatible dashboards

---

## Manual Setup

### 1) Enable the VictoriaMetrics Storage Stack

```bash
# VictoriaLogs + Prometheus
make install-storage-victorialogs

# OR: Full VictoriaMetrics stack (VictoriaLogs + VictoriaMetrics)
make install-storage-victoriametrics
```

This starts:
- **VictoriaLogs** (port 9428 by default)
- **VictoriaMetrics** or **Prometheus** (port 8428 or 9090)

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
METRICS_ENDPOINT=prometheus

# Reinstall or manually switch
make use-loki-output
make use-loki-datasource
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LOGS_ENDPOINT` | `loki` | Log storage: `loki` or `victorialogs` |
| `METRICS_ENDPOINT` | `prometheus` | Metrics storage: `prometheus` or `victoriametrics` |
| `VICTORIALOGS_PORT` | `9428` | VictoriaLogs HTTP port |
| `VICTORIALOGS_RETENTION_PERIOD` | `168h` | Log retention (7 days) |
| `VICTORIAMETRICS_PORT` | `8428` | VictoriaMetrics HTTP port |
| `VICTORIAMETRICS_RETENTION_PERIOD` | `15d` | Metrics retention |

---

[← Back to Home](index.md)
