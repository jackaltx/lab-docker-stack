#!/bin/bash
#
# Automated Startup Scan - Nmap + WhatWeb
# Executes passive reconnaissance on container startup
# Results stream to /results/ folder in real-time
#

set -e  # Exit on error

# Configuration
TARGET="${SCAN_TARGET:-scanme.nmap.org}"
RESULTS_DIR="/results/${TARGET}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Automated Reconnaissance Scan${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Target: ${YELLOW}${TARGET}${NC}"
echo -e "Timestamp: ${YELLOW}${TIMESTAMP}${NC}"
echo -e "Results: ${YELLOW}${RESULTS_DIR}${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Create results directory
mkdir -p "${RESULTS_DIR}"

# Wait for VPN to be ready
echo -e "${YELLOW}[1/4] Waiting for VPN connection...${NC}"
MAX_WAIT=60
COUNTER=0
while ! curl -s --max-time 5 ifconfig.me > /dev/null 2>&1; do
    sleep 2
    COUNTER=$((COUNTER + 2))
    if [ $COUNTER -ge $MAX_WAIT ]; then
        echo -e "${RED}ERROR: VPN not ready after ${MAX_WAIT}s${NC}"
        exit 1
    fi
    echo -n "."
done
echo ""

# Get VPN IP and location
VPN_IP=$(curl -s --max-time 10 ifconfig.me)
echo -e "${GREEN}✓ VPN Connected${NC}"
echo -e "  VPN IP: ${YELLOW}${VPN_IP}${NC}\n"

# Run Nmap scan
echo -e "${YELLOW}[2/4] Running Nmap scan...${NC}"
echo -e "  Command: nmap -sT -sV -T2 -p 22,25,80,443,3306,53,8080 ${TARGET}\n"

NMAP_OUTPUT="${RESULTS_DIR}/nmap-${TIMESTAMP}.txt"
nmap -sT -sV -T2 -p 22,25,80,443,3306,53,8080 "${TARGET}" 2>&1 | tee "${NMAP_OUTPUT}"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "\n${GREEN}✓ Nmap scan complete${NC}"
    echo -e "  Saved to: ${YELLOW}${NMAP_OUTPUT}${NC}\n"
else
    echo -e "\n${RED}✗ Nmap scan failed${NC}\n"
fi

# Run WhatWeb scan
echo -e "${YELLOW}[3/4] Running WhatWeb scan...${NC}"
echo -e "  Command: whatweb -a 1 ${TARGET}\n"

WHATWEB_OUTPUT="${RESULTS_DIR}/whatweb-${TIMESTAMP}.txt"
whatweb -a 1 --log-brief="${WHATWEB_OUTPUT}" "${TARGET}" 2>&1 | tee -a "${WHATWEB_OUTPUT}.verbose"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "\n${GREEN}✓ WhatWeb scan complete${NC}"
    echo -e "  Brief log: ${YELLOW}${WHATWEB_OUTPUT}${NC}"
    echo -e "  Verbose log: ${YELLOW}${WHATWEB_OUTPUT}.verbose${NC}\n"
else
    echo -e "\n${RED}✗ WhatWeb scan failed${NC}\n"
fi

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Scan Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Target: ${YELLOW}${TARGET}${NC}"
echo -e "VPN IP: ${YELLOW}${VPN_IP}${NC}"
echo -e "Results location: ${YELLOW}${RESULTS_DIR}${NC}"
echo -e "${GREEN}========================================${NC}\n"

# List result files
echo -e "${YELLOW}[4/4] Generated files:${NC}"
ls -lh "${RESULTS_DIR}/"*-${TIMESTAMP}* 2>/dev/null || echo "No files generated"

# Keep container running (optional - comment out if you want container to exit after scan)
echo -e "\n${YELLOW}Container will remain running. Use 'docker compose down' to stop.${NC}"
tail -f /dev/null
