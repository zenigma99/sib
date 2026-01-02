# 🛡️ SIB - SIEM in a Box

**One-command security monitoring** for containers and Linux systems, powered by Falco and the Grafana stack.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

SIB provides a complete, self-hosted security monitoring stack for detecting threats in real-time. Built on Falco's runtime security engine with Loki for log storage and Grafana for visualization.

## 🌟 Features

- **Runtime Security**: Detect suspicious behavior in real-time using Falco's eBPF-based syscall monitoring
- **Alert Forwarding**: Falcosidekick routes alerts to 50+ destinations (Slack, PagerDuty, Loki, etc.)
- **Log Aggregation**: Loki stores security events with efficient label-based querying
- **Pre-built Dashboards**: Grafana dashboards for security overview and event exploration
- **Critical Event Tracking**: Dedicated panel for Critical priority events requiring review
- **One Command Setup**: Get started with `make install`

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SIEM in a Box                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐     ┌─────────────────┐     ┌───────────────────────────┐ │
│  │    Falco     │     │  Falcosidekick  │     │          Loki             │ │
│  │  (Detection) │────▶│   (Fan-out)     │────▶│    (Log Storage)          │ │
│  │  modern_ebpf │     │                 │     │                           │ │
│  └──────────────┘     └─────────────────┘     └───────────────────────────┘ │
│                               │                            │                 │
│                               ▼                            ▼                 │
│                       ┌─────────────────┐     ┌───────────────────────────┐ │
│                       │  Falcosidekick  │     │        Grafana            │ │
│                       │       UI        │     │   • Security Overview     │ │
│                       │  (Event View)   │     │   • Events Explorer       │ │
│                       └─────────────────┘     │   • Critical Events       │ │
│                               │               └───────────────────────────┘ │
│                               ▼                                              │
│                       ┌─────────────────┐     ┌───────────────────────────┐ │
│                       │  Redis Stack    │     │      Prometheus           │ │
│                       │  (RediSearch)   │     │      (Metrics)            │ │
│                       └─────────────────┘     └───────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

- **Docker** 20.10+ with Docker Compose v2+
- **Linux kernel** 5.8+ (for modern_ebpf driver)
- **4GB+ RAM** recommended

```bash
docker --version          # Should be 20.10+
docker compose version    # Should be v2+
uname -r                  # Should be 5.8+ for eBPF
```

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/matijazezelj/sib.git
cd sib

# Configure environment
cp .env.example .env
# Edit .env if needed (defaults work for local testing)

# Install everything
make install

# Verify it's working
./scripts/test-pipeline.sh
```

## 🌐 Access Points

| Service | URL | Binding |
|---------|-----|---------|
| **Grafana** | http://localhost:3000 | External (0.0.0.0) |
| **Sidekick UI** | http://localhost:2802 | External (0.0.0.0) |
| Loki | http://localhost:3100 | Localhost only |
| Prometheus | http://localhost:9090 | Localhost only |
| Sidekick API | http://localhost:2801 | Localhost only |

Default Grafana credentials: `admin` / `admin`

## 🎯 What Gets Detected?

| Category | Examples |
|----------|----------|
| **Credential Access** | Reading /etc/shadow, SSH key access |
| **Container Security** | Shells in containers, privileged operations |
| **File Integrity** | Writes to /etc, sensitive config changes |
| **Process Anomalies** | Unexpected binaries, shell spawning |
| **Persistence** | Cron modifications, systemd changes |
| **Cryptomining** | Mining processes, pool connections |

## 📊 Dashboards

### Security Overview
- Total events, Critical/Error/Warning/Notice counts
- Events over time by priority
- Events by rule (pie chart)
- **🚨 Critical Events panel** - Dedicated view for high-priority events
- Recent security events log

### Events Explorer
- Query help with LogQL examples
- Event volume by rule
- Filterable log view with priority and rule filters

### Fleet Overview
- Active hosts with collectors
- CPU, memory, disk usage per host
- Network traffic graphs
- Log volume by host

## 🛠️ Commands

```bash
# Installation
make install              # Install all stacks
make uninstall            # Remove everything

# Management
make start                # Start all services
make stop                 # Stop all services
make restart              # Restart all services
make status               # Show service status

# Logs
make logs                 # Tail all logs
make logs-falco           # Tail Falco logs
make logs-sidekick        # Tail Falcosidekick logs

# Testing
make test-alert           # Generate a test security alert
./scripts/test-pipeline.sh  # Run full pipeline test

# Utilities
make open                 # Open Grafana in browser
make info                 # Show all endpoints
```

## 📁 Project Structure

```
sib/
├── Makefile                    # Main entry point
├── .env.example                # Environment template
├── scripts/
│   └── test-pipeline.sh        # Pipeline verification script
├── detection/                  # Falco stack
│   ├── compose.yaml
│   └── config/
│       ├── falco.yaml          # Falco config (modern_ebpf)
│       └── rules/
│           └── custom_rules.yaml  # Custom detection rules
├── alerting/                   # Falcosidekick + UI + Redis
│   ├── compose.yaml
│   └── config/
│       └── config.yaml         # Sidekick -> Loki config
├── storage/                    # Loki + Prometheus
│   ├── compose.yaml
│   └── config/
│       ├── loki-config.yml
│       └── prometheus.yml
├── grafana/                    # Dashboards
│   ├── compose.yaml
│   └── provisioning/
│       ├── datasources/
│       │   └── datasources.yml
│       └── dashboards/
│           └── json/
│               ├── security-overview.json
│               ├── events-explorer.json
│               └── fleet-overview.json
├── collectors/                 # Remote host collectors
│   ├── compose.yaml            # Docker deployment
│   ├── config/
│   │   └── config.alloy        # Alloy configuration
│   └── scripts/
│       └── deploy.sh           # Remote deployment script
└── examples/
    └── rules/                  # Example custom rules
```

## 🔧 Configuration

### Custom Rules

Add detection rules in `detection/config/rules/custom_rules.yaml`:

```yaml
- rule: Detect Cryptocurrency Mining
  desc: Detect cryptocurrency mining processes
  condition: >
    spawned_process and 
    proc.name in (xmrig, minerd, cpuminer)
  output: "Crypto miner detected (user=%user.name cmd=%proc.cmdline)"
  priority: CRITICAL
  tags: [cryptomining, mitre_impact]
```

### Alert Outputs

Configure additional outputs in `alerting/config/config.yaml`:

```yaml
slack:
  webhookurl: "https://hooks.slack.com/services/XXX/YYY/ZZZ"
  minimumpriority: "warning"

pagerduty:
  routingkey: "your-routing-key"
  minimumpriority: "critical"
```

### Environment Variables

Key variables in `.env`:

```bash
GRAFANA_ADMIN_PASSWORD=admin
GRAFANA_PORT=3000
LOKI_PORT=3100
PROMETHEUS_PORT=9090
SIDEKICK_PORT=2801
SIDEKICK_UI_PORT=2802
```

## 🔒 Security Notes

- Internal services (Loki, Prometheus, Sidekick API) bind to localhost only
- Only Grafana and Sidekick UI are externally accessible
- Falco requires privileged access for syscall monitoring
- Change default Grafana password in production

## 📡 Remote Collectors (Alloy)

SIB uses **Grafana Alloy** as a unified telemetry collector for remote hosts. Deploy lightweight collectors to ship logs and metrics to your central SIB server.

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Hub and Spoke Model                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                   │
│  │   Host A     │    │   Host B     │    │   Host C     │                   │
│  │   (Alloy)    │    │   (Alloy)    │    │   (Alloy)    │                   │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘                   │
│         │                   │                   │                            │
│         │     Logs (Loki Push)  +  Metrics (Remote Write)                   │
│         │                   │                   │                            │
│         └───────────────────┼───────────────────┘                            │
│                             ▼                                                │
│                   ┌──────────────────┐                                       │
│                   │    SIB Server    │                                       │
│                   │  ┌────────────┐  │                                       │
│                   │  │    Loki    │  │  ◀── Logs with host labels           │
│                   │  └────────────┘  │                                       │
│                   │  ┌────────────┐  │                                       │
│                   │  │ Prometheus │  │  ◀── Node metrics                    │
│                   │  └────────────┘  │                                       │
│                   │  ┌────────────┐  │                                       │
│                   │  │  Grafana   │  │  ◀── Fleet Overview dashboard        │
│                   │  └────────────┘  │                                       │
│                   └──────────────────┘                                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Enable Remote Mode

On the SIB server, enable external access for collectors:

```bash
make enable-remote
```

This exposes Loki (3100) and Prometheus (9090) externally. Ensure your firewall is configured appropriately.

### Deploy Collector to Remote Host

```bash
# Using the Makefile (recommended)
make deploy-collector HOST=user@remote-host

# Or using the deploy script directly
./collectors/scripts/deploy.sh user@192.168.1.50 192.168.1.163
```

The deploy script will:
1. Copy Alloy configuration to the remote host
2. Configure the SIB server address
3. Start Alloy via Docker Compose
4. Verify the deployment

### What Gets Collected

| Type | Sources | Labels |
|------|---------|--------|
| **System Logs** | `/var/log/syslog`, `/var/log/messages` | `job="syslog"` |
| **Auth Logs** | `/var/log/auth.log`, `/var/log/secure` | `job="auth"` |
| **Kernel Logs** | `/var/log/kern.log` | `job="kernel"` |
| **Journal** | systemd journal | `job="journal"` |
| **Docker Logs** | All containers | `job="docker"`, `container=...` |
| **Node Metrics** | CPU, memory, disk, network | `job="node"`, `collector="alloy"` |

All data is tagged with:
- `host` - hostname of the remote machine
- `collector="alloy"` - identifies data from Alloy collectors

### Manual Deployment

If you prefer manual deployment:

```bash
# On the remote host
mkdir -p ~/sib-collector/config

# Copy and edit the config
scp collectors/config/config.alloy user@remote:~/sib-collector/config/
# Edit config.alloy - replace SIB_SERVER_IP with your SIB server IP

scp collectors/compose.yaml user@remote:~/sib-collector/

# Start the collector
ssh user@remote "cd ~/sib-collector && HOSTNAME=\$(hostname) docker compose up -d"
```

### Verify Collector is Working

```bash
# Check Alloy logs on remote host
ssh user@remote "docker logs sib-alloy --tail 20"

# Query Loki for collector data
curl -s "http://localhost:3100/loki/api/v1/label/host/values"

# Check metrics in Prometheus
curl -s 'http://localhost:9090/api/v1/query?query=node_uname_info{collector="alloy"}'
```

### Fleet Overview Dashboard

The **Fleet Overview** dashboard in Grafana shows:
- Number of active hosts with collectors
- CPU, memory, disk utilization per host
- Network traffic graphs
- Log volume by host

## 🐛 Troubleshooting

### Falco won't start

```bash
# Check kernel version (need 5.8+ for modern_ebpf)
uname -r

# Check Falco logs
docker logs sib-falco

# Verify privileged mode is working
docker run --rm --privileged alpine echo "OK"
```

### No events in Grafana

```bash
# Run the pipeline test
./scripts/test-pipeline.sh

# Check Falcosidekick is receiving events
docker logs sib-sidekick --tail 20

# Query Loki directly
curl -s "http://localhost:3100/loki/api/v1/query?query={source=\"syscall\"}" | jq .
```

### Sidekick UI not working

The UI requires Redis Stack with RediSearch. If you see `FT.CREATE` errors:
```bash
# Verify Redis Stack is running (not plain Redis)
docker logs sib-redis
```

## 📜 License

Apache 2.0 License - See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- [Falco](https://falco.org/) - Cloud native runtime security
- [Falcosidekick](https://github.com/falcosecurity/falcosidekick) - Alert routing
- [Grafana](https://grafana.com/) - Observability platform
- [Loki](https://grafana.com/oss/loki/) - Log aggregation
