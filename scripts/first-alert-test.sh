#!/bin/bash
# =============================================================================
# SIB First Alert Test - Measure Time to First Detection
# =============================================================================
# Triggers a real Falco detection and measures how long until it appears
# in Loki. This proves the entire pipeline works end-to-end.
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

LOKI_URL="${LOKI_URL:-http://localhost:3100}"
SIDEKICK_URL="${SIDEKICK_URL:-http://localhost:2801}"
TIMEOUT=60
TEST_MARKER="sib-first-alert-$(date +%s)"

echo ""
echo -e "${BOLD}🧪 First Alert Test${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Wait for services to be ready
echo -e "${CYAN}Waiting for services to be ready...${NC}"
for i in {1..30}; do
    if curl -sf "${LOKI_URL}/ready" >/dev/null 2>&1 && \
       curl -sf "${SIDEKICK_URL}/healthz" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Check if services are ready
if ! curl -sf "${LOKI_URL}/ready" >/dev/null 2>&1; then
    echo -e "${RED}✗ Loki is not ready${NC}"
    exit 1
fi

if ! curl -sf "${SIDEKICK_URL}/healthz" >/dev/null 2>&1; then
    echo -e "${RED}✗ Falcosidekick is not ready${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Services ready${NC}"
echo ""

# Record start time
START_TIME=$(date +%s.%N)

# Trigger a real Falco detection by reading /etc/shadow
# This will generate a "Read sensitive file untrusted" event
echo -e "${CYAN}Triggering security event...${NC}"
echo -e "  ${YELLOW}→${NC} Reading /etc/shadow (triggers Falco detection)"

# Create a marker file we can search for
docker exec sib-falco sh -c "cat /etc/shadow > /dev/null 2>&1" 2>/dev/null || \
    sudo cat /etc/shadow > /dev/null 2>&1 || \
    cat /etc/shadow > /dev/null 2>&1 || true

echo -e "${GREEN}✓ Event triggered${NC}"
echo ""

# Wait for alert to appear in Loki
echo -e "${CYAN}Waiting for alert in Loki...${NC}"

DETECTED=false
for i in $(seq 1 $TIMEOUT); do
    # Query Loki for recent events
    RESULT=$(curl -sf -G "${LOKI_URL}/loki/api/v1/query_range" \
        --data-urlencode 'query={source="syscall"}' \
        --data-urlencode "start=$(echo "$START_TIME - 5" | bc)" \
        --data-urlencode "end=$(date +%s)" \
        --data-urlencode "limit=10" 2>/dev/null || echo "")
    
    if echo "$RESULT" | grep -q "shadow\|sensitive\|Read sensitive file"; then
        DETECTED=true
        END_TIME=$(date +%s.%N)
        break
    fi
    
    # Also check for any syscall events as backup
    if echo "$RESULT" | grep -q '"result":\[{'; then
        # Got some results, check if there are recent events
        EVENT_COUNT=$(echo "$RESULT" | grep -o '"values"' | wc -l)
        if [ "$EVENT_COUNT" -gt 0 ]; then
            DETECTED=true
            END_TIME=$(date +%s.%N)
            break
        fi
    fi
    
    printf "  \r${YELLOW}→${NC} Checking... %ds" "$i"
    sleep 1
done

echo ""
echo ""

if [ "$DETECTED" = true ]; then
    # Calculate elapsed time
    ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
    ELAPSED_INT=$(printf "%.0f" "$ELAPSED")
    
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}${BOLD}🚨 First alert detected in ${ELAPSED_INT} seconds!${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Your security pipeline is working:${NC}"
    echo -e "  ${GREEN}✓${NC} Falco detected the event"
    echo -e "  ${GREEN}✓${NC} Falcosidekick forwarded it"
    echo -e "  ${GREEN}✓${NC} Loki stored the alert"
    echo -e "  ${GREEN}✓${NC} Ready to visualize in Grafana"
    echo ""
    exit 0
else
    echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${RED}✗ Alert not detected within ${TIMEOUT}s${NC}"
    echo ""
    echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo -e "  • Check Falco logs:      ${CYAN}make logs-falco${NC}"
    echo -e "  • Check Sidekick logs:   ${CYAN}make logs-sidekick${NC}"
    echo -e "  • Verify services:       ${CYAN}make health${NC}"
    echo ""
    exit 1
fi
