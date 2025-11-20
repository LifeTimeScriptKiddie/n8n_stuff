#!/bin/bash

# Enable Demo Webhook at http://localhost/webhook/demo-recon
# This script sets up the web interface to use the demo workflow

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Setting up Demo Webhook ===${NC}\n"

# Step 1: Verify demo workflow exists
echo -e "${YELLOW}[1/5] Checking demo workflow file...${NC}"
WORKFLOW_FILE="workflows/demo_standalone_recon.json"
if [ -f "$WORKFLOW_FILE" ]; then
    echo -e "${GREEN}✓ Demo workflow file found${NC}\n"
else
    echo -e "${RED}✗ Demo workflow not found at $WORKFLOW_FILE${NC}"
    exit 1
fi

# Step 2: Verify web interface is configured
echo -e "${YELLOW}[2/5] Verifying web interface configuration...${NC}"
if grep -q "const N8N_WEBHOOK_URL = '/webhook/demo-recon'" web-interface/index.html; then
    echo -e "${GREEN}✓ Web interface configured for demo webhook${NC}\n"
else
    echo -e "${RED}✗ Web interface not configured. Run the update commands from the guide.${NC}"
    exit 1
fi

# Step 3: Restart nginx to load updated web interface
echo -e "${YELLOW}[3/5] Restarting nginx...${NC}"
docker-compose restart nginx
echo -e "${GREEN}✓ Nginx restarted${NC}\n"

# Step 4: Wait for services to be healthy
echo -e "${YELLOW}[4/5] Waiting for services to be ready...${NC}"
sleep 3

# Check nginx
if docker ps | grep -q "n8n_nginx_proxy"; then
    echo -e "${GREEN}✓ Nginx is running${NC}"
else
    echo -e "${RED}✗ Nginx is not running${NC}"
    exit 1
fi

# Check n8n
if docker ps | grep -q "n8n_recon_hub"; then
    echo -e "${GREEN}✓ n8n is running${NC}\n"
else
    echo -e "${RED}✗ n8n is not running${NC}"
    exit 1
fi

# Step 5: Test webhook (if workflow is active)
echo -e "${YELLOW}[5/5] Testing webhook connection...${NC}"

# Test direct connection to n8n
echo "Testing direct connection to n8n..."
DIRECT_TEST=$(curl -s -X POST http://127.0.0.1:5678/webhook/demo-recon \
  -H "Content-Type: application/json" \
  -d '{"target":"test.com"}' \
  -o /dev/null -w "%{http_code}" 2>/dev/null || echo "000")

if [ "$DIRECT_TEST" = "200" ]; then
    echo -e "${GREEN}✓ Direct webhook working (n8n workflow is active)${NC}"
elif [ "$DIRECT_TEST" = "404" ]; then
    echo -e "${YELLOW}⚠ Webhook returns 404 - Import and activate the demo workflow in n8n${NC}"
    echo -e "  1. Go to http://127.0.0.1:5678"
    echo -e "  2. Import: $WORKFLOW_FILE"
    echo -e "  3. Activate the workflow"
else
    echo -e "${YELLOW}⚠ Could not test webhook (n8n might not be ready)${NC}"
fi

# Test through nginx
echo "Testing nginx proxy..."
PROXY_TEST=$(curl -s -X POST http://localhost/webhook/demo-recon \
  -H "Content-Type: application/json" \
  -d '{"target":"test.com"}' \
  -o /dev/null -w "%{http_code}" 2>/dev/null || echo "000")

if [ "$PROXY_TEST" = "200" ]; then
    echo -e "${GREEN}✓ Nginx proxy working${NC}\n"
elif [ "$PROXY_TEST" = "404" ]; then
    echo -e "${YELLOW}⚠ Proxied webhook returns 404 - Import and activate the demo workflow${NC}\n"
else
    echo -e "${YELLOW}⚠ Could not test nginx proxy${NC}\n"
fi

# Summary
echo -e "${GREEN}=== Setup Complete ===${NC}\n"

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Import demo workflow into n8n:"
echo -e "   ${GREEN}open http://127.0.0.1:5678${NC}"
echo "   Then: Workflows → Import from File → Select workflows/demo_standalone_recon.json"
echo ""
echo "2. Activate the workflow (toggle in top-right)"
echo ""
echo "3. Test the web interface:"
echo -e "   ${GREEN}open http://localhost/${NC}"
echo ""
echo -e "${YELLOW}Webhook URL:${NC} http://localhost/webhook/demo-recon"
echo ""

# Show access URLs
echo -e "${YELLOW}Access Points:${NC}"
echo "  Web Interface:  http://localhost/"
echo "  n8n Admin:      http://127.0.0.1:5678"
echo "  Demo Webhook:   http://localhost/webhook/demo-recon"
echo ""

# Check if workflow needs to be imported
if [ "$DIRECT_TEST" = "404" ]; then
    echo -e "${RED}⚠ IMPORTANT: You must import and activate the demo workflow!${NC}"
    echo ""
fi

echo -e "${GREEN}Done!${NC}"
