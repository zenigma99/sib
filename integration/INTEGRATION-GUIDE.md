# Falco + Grafana/Loki Integration Guide

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  HOST 1, 2, 3 (each running Falco)                           │
│                                                              │
│  Falco ──HTTP──> Falcosidekick ──Loki API──> Central Loki   │
│                       │                                      │
│                       └──Prometheus──> Central VictoriaMetrics│
└──────────────────────────────────────────────────────────────┘
                           │ (via Tailscale)
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  CENTRAL HOST (Grafana Stack)                                │
│                                                              │
│  Loki:3100 ◄── receives Falco events as structured logs     │
│  VictoriaMetrics:8428 ◄── receives Falcosidekick metrics    │
│  Grafana:3000 ──queries──> Loki + VictoriaMetrics            │
│       └── 5 pre-built Falco dashboards                       │
└──────────────────────────────────────────────────────────────┘
```

## What Was Wrong

Your Falcosidekick was sending to `VictoriaMetrics /api/v1/write` which only
ships **Prometheus metrics** (counters like `falcosidekick_alerts_total`), NOT
the actual event data. To get the full Falco events (rule name, priority,
output details, hostname, etc.) into Grafana, you need the **Loki output**.

## Step-by-Step Integration

### Step 1: Update Falcosidekick on each Falco host

Add the Loki environment variables to your `falcosidekick` service.
Replace `100.91.135.128` with your central Grafana host's Tailscale IP:

```yaml
falcosidekick:
  environment:
    # ... keep your existing env vars ...
    #
    # ADD THESE - sends full event data to Loki:
    - LOKI_HOSTPORT=http://loki-central:3100
    - LOKI_MINIMUMPRIORITY=debug
  extra_hosts:
    - "loki-central:100.91.135.128"   # your Grafana host Tailscale IP
```

That's the critical missing piece. Falcosidekick will now POST structured
log entries to your central Loki instance via its Loki-compatible API.

### Step 2: Update Loki config on central host

Replace your `config/loki/local-config.yaml` with the improved version from:
`integration/grafana-additions/config/loki/local-config.yaml`

Key improvements:
- TSDB schema v13 (better performance)
- Compactor with retention cleanup enabled
- Tuned ingestion limits for multi-host setup
- Embedded query cache

### Step 3: Add Grafana dashboards

Copy the provisioning files into your Grafana stack:

```bash
# On your central Grafana host, inside your grafana stack directory:

# 1. Copy the Loki datasource provisioning
cp integration/grafana-additions/provisioning/datasources/falco-loki.yml \
   /path/to/grafana-stack/provisioning/datasources/

# 2. Copy the dashboard provisioning config
cp integration/grafana-additions/provisioning/dashboards/falco-dashboards.yml \
   /path/to/grafana-stack/provisioning/dashboards/

# 3. Copy the dashboard JSON files
cp -r integration/grafana-additions/provisioning/dashboards/loki \
   /path/to/grafana-stack/provisioning/dashboards/
```

Then add these volumes to your Grafana service in docker-compose:

```yaml
grafana:
  volumes:
    - /home/ubuntu/docker-data/stacks/victoria/grafana_data:/var/lib/grafana
    # ADD these 3 lines:
    - ./provisioning/datasources/falco-loki.yml:/etc/grafana/provisioning/datasources/falco-loki.yml:ro
    - ./provisioning/dashboards/falco-dashboards.yml:/etc/grafana/provisioning/dashboards/falco-dashboards.yml:ro
    - ./provisioning/dashboards/loki:/etc/grafana/provisioning/dashboards/loki:ro
```

**Important**: If you already have Loki as a datasource in Grafana, make sure
its UID is set to `loki`. The dashboards reference `uid: "loki"`. You can
check/change this in Grafana UI under Configuration > Data Sources > Loki.

### Step 4: Add custom Falco rules (optional but recommended)

Copy `integration/falco-stack/custom_rules.yaml` to each Falco host and mount it:

```yaml
falco:
  volumes:
    # ... existing volumes ...
    - ./custom_rules.yaml:/etc/falco/rules.d/custom_rules.yaml:ro
```

This adds 900+ lines of detection rules covering:
- Cryptocurrency mining
- Container escape attempts
- Credential access (AWS, SSH, K8s)
- Persistence (cron, systemd)
- MITRE ATT&CK mapped techniques
- Reverse shells, webshells, backdoors
- Defense evasion (log tampering, rootkits)
- And more

### Step 5: Restart everything

```bash
# On each Falco host:
docker compose down && docker compose up -d

# On central Grafana host:
docker compose down && docker compose up -d
```

### Step 6: Verify

1. **Check Falcosidekick logs** on a Falco host:
   ```bash
   docker logs falcosidekick 2>&1 | grep -i loki
   ```
   You should see: `Loki - Pair Initializing client` and successful POSTs.

2. **Trigger a test event** on a Falco host:
   ```bash
   cat /etc/shadow
   ```
   This should trigger the "Critical Test - Shadow File Read" rule.

3. **Check Loki** received it:
   ```bash
   curl -s "http://100.91.135.128:3100/loki/api/v1/query?query={source=%22syscall%22}" | python3 -m json.tool
   ```

4. **Open Grafana** and navigate to the "Falco Security" folder.
   You should see 5 dashboards:
   - Security Overview
   - Events Explorer
   - Fleet Overview (needs Alloy collectors for system logs)
   - MITRE ATT&CK Coverage
   - Host Risk Scores

## Dashboards Included

| Dashboard | Description |
|-----------|-------------|
| **Security Overview** | Total events, events by priority/rule, timeline, critical event log |
| **Events Explorer** | Filterable event browser with hostname/priority/rule dropdowns |
| **Fleet Overview** | Multi-host view with CPU/memory/disk/network (needs Alloy/node_exporter) |
| **MITRE ATT&CK Coverage** | Maps events to 12 MITRE ATT&CK tactics with coverage matrix |
| **Host Risk Scores** | Weighted risk scoring per host: Critical=25, Error=10, Warning=3, Notice=1 |

## Files Reference

```
integration/
├── falco-stack/
│   ├── docker-compose.yml          # Updated Falco compose with Loki output
│   └── custom_rules.yaml           # 900+ detection rules with MITRE mapping
├── grafana-additions/
│   ├── docker-compose.override.yml # Instructions for Grafana compose changes
│   ├── config/
│   │   └── loki/
│   │       └── local-config.yaml   # Improved Loki config
│   └── provisioning/
│       ├── datasources/
│       │   └── falco-loki.yml      # Loki datasource (uid=loki)
│       └── dashboards/
│           ├── falco-dashboards.yml # Dashboard auto-provisioning
│           └── loki/
│               ├── security-overview.json
│               ├── events-explorer.json
│               ├── fleet-overview.json
│               ├── mitre-attack.json
│               └── risk-scores.json
└── INTEGRATION-GUIDE.md            # This file
```

## Optional: Prometheus metrics from Falcosidekick

To also scrape Falcosidekick metrics into VictoriaMetrics/Prometheus, add this
to your `prometheus.yml`:

```yaml
scrape_configs:
  # ... existing jobs ...
  - job_name: 'falcosidekick'
    static_configs:
      - targets: ['TAILSCALE_IP_HOST1:2801', 'TAILSCALE_IP_HOST2:2801']
    metrics_path: '/metrics'
```

For this to work, expose port 2801 on the Tailscale interface instead of localhost:
```yaml
ports:
  - "YOUR_TAILSCALE_IP:2801:2801"   # instead of 127.0.0.1:2801:2801
```

## Optional: System log collection with Alloy

The Fleet Overview dashboard also shows system logs (syslog, auth, docker).
To collect those from each host, deploy Grafana Alloy. The sib repo has a
ready-made config at `collectors/compose-grafana.yaml` and `collectors/config/config.alloy`.
Update `SIB_SERVER_IP` in config.alloy to your central Loki IP.
