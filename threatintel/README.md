# Threat Intelligence Integration

SIB includes threat intelligence feed integration to enrich security events with known malicious IP data.

## Features

- **IP Blocklists**: Download and aggregate IP blocklists from multiple sources
- **Falco Rules**: Auto-generated rules to detect connections to malicious IPs
- **IP Lookup**: Quick command-line tool to check IPs against all feeds

## Supported Threat Intel Sources

| Source | Description | Update Frequency |
|--------|-------------|------------------|
| [Feodo Tracker](https://feodotracker.abuse.ch/) | Banking trojans, C2 servers | 5 min |
| [SSL Blacklist](https://sslbl.abuse.ch/) | Malware C2 SSL certificates | 5 min |
| [Emerging Threats](https://rules.emergingthreats.net/) | Compromised IPs | Daily |
| [Spamhaus DROP](https://www.spamhaus.org/drop/) | Don't Route Or Peer list | Daily |
| [Blocklist.de](https://www.blocklist.de/) | SSH bruteforce, attacks | Hourly |
| [CINSscore](https://cinsscore.com/) | CI Army threat intel | Daily |

## Usage

### Update Threat Intel Feeds

```bash
# Download/update all feeds
./threatintel/update-feeds.sh

# Or via Makefile
make update-threatintel
```

This will:
1. Download IP blocklists from all sources
2. Combine them into a single deduplicated list
3. Generate Falco rules for threat intel detection

### Lookup an IP

```bash
# Check if an IP is in any blocklist
./threatintel/lookup-ip.sh 185.220.101.1

# Output:
# Checking 185.220.101.1 against threat intel feeds...
#   ⚠️  FOUND in feodotracker
#   ⚠️  FOUND in sslbl
#   🚨 IP is in combined blocklist!
```

### Enable Threat Intel Rules in Falco

```bash
# Copy generated rules to Falco
cp threatintel/falco_threatintel_rules.yaml detection/config/rules/

# Restart Falco to load new rules
make restart-detection
```

## Automated Updates

Schedule regular feed updates via cron:

```bash
# Update every 6 hours
0 */6 * * * /path/to/sib/threatintel/update-feeds.sh
```

## Feed Files

After running `update-feeds.sh`:

```
threatintel/
├── feeds/
│   ├── feodotracker.txt       # Feodo Tracker IPs
│   ├── sslbl.txt              # SSL Blacklist IPs
│   ├── et_compromised.txt     # Emerging Threats IPs
│   ├── spamhaus_drop.txt      # Spamhaus DROP
│   ├── blocklist_ssh.txt      # Blocklist.de SSH
│   ├── blocklist_all.txt      # Blocklist.de All
│   ├── ci_army.txt            # CINSscore CI Army
│   └── combined_blocklist.txt # All feeds combined
├── falco_threatintel_rules.yaml  # Generated Falco rules
├── lookup-ip.sh               # IP lookup script
└── update-feeds.sh            # Feed updater
```

## Falco Rules Generated

The feed updater generates Falco rules for:

| Rule | Priority | Description |
|------|----------|-------------|
| Connection to Threat Intel IP (Outbound) | WARNING | Outbound connections to blocklisted IPs |
| Connection from Threat Intel IP (Inbound) | WARNING | Inbound connections from blocklisted IPs |
| Connection to Known C2 Server | ERROR | Connections on common C2 ports |
| Connection to Crypto Mining Pool | CRITICAL | Connections to mining pool ports |
| DNS Query to Suspicious Domain | NOTICE | DNS activity monitoring |

## CrowdSec Integration (Optional)

For advanced threat intel with IP reputation scoring:

```bash
# Install CrowdSec
curl -s https://install.crowdsec.net | sudo sh

# Configure CrowdSec bouncer
sudo cscli bouncers add sib-bouncer

# CrowdSec will automatically:
# - Block known malicious IPs
# - Share threat intel with the community
# - Provide real-time IP reputation
```

## Grafana Dashboard

The MITRE ATT&CK dashboard includes a panel for threat intel events. Filter by:

```
{source="syscall"} |= "threatintel"
```

## Adding Custom Feeds

Edit `update-feeds.sh` to add your own feeds:

```bash
# Add a custom feed
download_feed "my_custom_feed" "https://example.com/blocklist.txt"
```

The feed should be a text file with one IP per line.
