#!/bin/bash
# Generate Falco configuration with optional mTLS settings
#
# Usage: ./scripts/generate-falco-config.sh [--mtls]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE="${PROJECT_ROOT}/detection/config/falco.yaml.template"
OUTPUT="${PROJECT_ROOT}/detection/config/falco.yaml"

# Check for mTLS flag or environment variable
MTLS_ENABLED="${MTLS_ENABLED:-false}"
if [ "$1" = "--mtls" ]; then
    MTLS_ENABLED="true"
fi

# Verify template exists
if [ ! -f "$TEMPLATE" ]; then
    echo "Error: Template not found at $TEMPLATE" >&2
    exit 1
fi

# Generate config using awk for proper YAML manipulation
if [ "$MTLS_ENABLED" = "true" ]; then
    awk '
    {
        # Replace URL placeholder with HTTPS
        gsub(/__SIDEKICK_URL__/, "https://sib-sidekick:2801/")
        print
        # After user_agent line, add mTLS settings
        if (/user_agent:.*falcosidekick/) {
            print "  insecure: false"
            print "  ca_cert: /etc/falco/certs/ca/ca.crt"
            print "  client_cert: /etc/falco/certs/clients/local.crt"
            print "  client_key: /etc/falco/certs/clients/local.key"
            print "  mtls: true"
        }
    }
    ' "$TEMPLATE" > "$OUTPUT"
    echo "Generated Falco config with mTLS enabled"
else
    # Generate standard HTTP config
    sed "s|__SIDEKICK_URL__|http://sib-sidekick:2801/|g" "$TEMPLATE" > "$OUTPUT"
    echo "Generated Falco config (HTTP mode)"
fi
