# Storage Stack

This directory contains the storage backends for SIB. Multiple configurations are available:

| Configuration | Logs | Metrics | Use Case |
|--------------|------|---------|----------|
| Default | Loki | Prometheus | Standard setup, Grafana-native |
| VictoriaLogs | VictoriaLogs | Prometheus | Better full-text search |
| Full VictoriaMetrics | VictoriaLogs | VictoriaMetrics | Lowest resource usage |

## Components

| Service | Port | Description |
|---------|------|-------------|
| **Loki** | 3100 | Log aggregation for security events |
| **VictoriaLogs** | 9428 | Alternative log storage (fast full‑text search) |
| **Prometheus** | 9090 | Metrics storage |
| **VictoriaMetrics** | 8428 | Alternative metrics storage (10x less RAM) |

## Quick Start

Configure your preferred backends in `.env`:

```bash
# Default: Loki + Prometheus
LOGS_ENDPOINT=loki
METRICS_ENDPOINT=prometheus

# Full VictoriaMetrics (lowest resources)
LOGS_ENDPOINT=victorialogs
METRICS_ENDPOINT=victoriametrics
```

Then run `make install` - it will automatically use the right compose file.

## Loki

Loki stores security events from Falcosidekick in a scalable, cost-efficient way.

### Features
- Label-based indexing (like Prometheus for logs)
- LogQL query language
- Integration with Grafana

### Configuration
Edit `config/loki-config.yml`:
- `retention_period`: How long to keep events (default: 7 days)
- `ingestion_rate_mb`: Max ingestion rate

### LogQL Examples

```logql
# All Falco events
{job="falco"}

# Critical priority events
{job="falco"} | json | priority = "Critical"

# Events from specific container
{job="falco"} | json | container_name = "nginx"

# Count by priority
sum by (priority) (count_over_time({job="falco"} [1h]))
```

## Prometheus

Prometheus collects metrics from Falcosidekick for monitoring.

### Metrics Available

- `falcosidekick_alerts_total`: Total alerts by priority
- `falcosidekick_outputs_total`: Output attempts by destination
- `falcosidekick_outputs_ok`: Successful outputs
- `falcosidekick_outputs_error`: Failed outputs

### PromQL Examples

```promql
# Alert rate by priority
sum(rate(falcosidekick_alerts_total[5m])) by (priority)

# Output success rate
sum(rate(falcosidekick_outputs_ok[5m])) / sum(rate(falcosidekick_outputs_total[5m]))
```

## Data Retention

| Component | Default | Config Location |
|-----------|---------|-----------------|
| Loki | 7 days | `config/loki-config.yml` |
| VictoriaLogs | 7 days | `compose-victorialogs.yaml` (retentionPeriod) |
| Prometheus | 15 days | `compose.yaml` |
| VictoriaMetrics | 15 days | `compose-victoriametrics.yaml` (retentionPeriod) |

## Manual Installation

```bash
# Loki + Prometheus (default)
make install-storage

# VictoriaLogs + Prometheus
make install-storage-victorialogs

# VictoriaLogs + VictoriaMetrics (full VM stack)
make install-storage-victoriametrics
```

Then update Falcosidekick to point at VictoriaLogs:

```yaml
loki:
	hostport: "http://sib-victorialogs:9428"
```

## Troubleshooting

### Loki Not Accepting Events
```bash
# Check Loki health
curl http://localhost:3100/ready

# Check Loki logs
docker logs sib-loki
```

### High Memory Usage
Reduce retention periods or increase container limits.
