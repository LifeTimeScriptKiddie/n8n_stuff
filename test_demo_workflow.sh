#!/bin/bash

# Test Demo Workflow Script
# Usage: ./test_demo_workflow.sh [target]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
N8N_URL="${N8N_URL:-http://localhost:5678}"
WEBHOOK_PATH="webhook/demo-recon"
TARGET="${1:-scanme.nmap.org}"

echo -e "${YELLOW}=== n8n Demo Recon Workflow Test ===${NC}\n"

# Check if n8n is running
echo -e "${YELLOW}[1/4] Checking n8n availability...${NC}"
if ! curl -s "${N8N_URL}/healthz" > /dev/null 2>&1; then
    echo -e "${RED}✗ n8n is not running at ${N8N_URL}${NC}"
    echo "Please start n8n first: docker-compose up -d"
    exit 1
fi
echo -e "${GREEN}✓ n8n is running${NC}\n"

# Test webhook endpoint
echo -e "${YELLOW}[2/4] Testing webhook endpoint...${NC}"
WEBHOOK_URL="${N8N_URL}/${WEBHOOK_PATH}"
echo "URL: ${WEBHOOK_URL}"
echo "Target: ${TARGET}"
echo ""

# Make request
echo -e "${YELLOW}[3/4] Starting scan...${NC}"
RESPONSE=$(curl -s -X POST "${WEBHOOK_URL}" \
  -H "Content-Type: application/json" \
  -d "{\"target\": \"${TARGET}\"}" \
  -w "\nHTTP_CODE:%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

if [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}✗ Request failed with HTTP $HTTP_CODE${NC}"
    echo "$BODY"
    exit 1
fi

echo -e "${GREEN}✓ Scan completed successfully${NC}\n"

# Parse and display results
echo -e "${YELLOW}[4/4] Results:${NC}"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"

# Extract output directory
OUTPUT_DIR=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['output_directory'])" 2>/dev/null)

if [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ]; then
    echo -e "\n${YELLOW}Output Files:${NC}"
    ls -lh "$OUTPUT_DIR/"

    echo -e "\n${YELLOW}Quick Stats:${NC}"
    if [ -f "$OUTPUT_DIR/all_subdomains.txt" ]; then
        SUBDOMAIN_COUNT=$(wc -l < "$OUTPUT_DIR/all_subdomains.txt")
        echo "  Subdomains: $SUBDOMAIN_COUNT"
    fi

    if [ -f "$OUTPUT_DIR/live_urls.txt" ]; then
        URL_COUNT=$(wc -l < "$OUTPUT_DIR/live_urls.txt")
        echo "  Live URLs: $URL_COUNT"
    fi

    if [ -f "$OUTPUT_DIR/nuclei.json" ]; then
        VULN_COUNT=$(wc -l < "$OUTPUT_DIR/nuclei.json")
        echo "  Vulnerabilities: $VULN_COUNT"
    fi

    if [ -f "$OUTPUT_DIR/report.md" ]; then
        echo -e "\n${YELLOW}Report Preview:${NC}"
        head -30 "$OUTPUT_DIR/report.md"
        echo -e "\n${GREEN}Full report: $OUTPUT_DIR/report.md${NC}"
    fi
else
    echo -e "${YELLOW}Output directory not found or not accessible${NC}"
fi

echo -e "\n${GREEN}=== Test Complete ===${NC}"
