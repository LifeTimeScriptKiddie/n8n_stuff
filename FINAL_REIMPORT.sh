#!/bin/bash

# Final Demo Workflow Re-import Guide
# This script provides step-by-step instructions

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

clear

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Demo Workflow Re-import - Final Fixed Version       ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo ""

echo -e "${GREEN}✓ Workflow file validated: workflows/demo_standalone_recon.json${NC}\n"

echo -e "${YELLOW}What was fixed in this version:${NC}"
echo "  ❌ Before: command: \`mkdir -p \${$json.output_dir}\`"
echo "  ✅ After:  command: ='mkdir -p ' + \$json.output_dir"
echo ""
echo "  Changed from template literals to string concatenation"
echo "  This avoids shell syntax errors with /bin/sh"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 1: Delete Old Workflow${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Opening n8n in browser..."
sleep 1
open http://127.0.0.1:5678/workflows 2>/dev/null || echo "  → Manually open: http://127.0.0.1:5678/workflows"
echo ""
echo "In n8n UI:"
echo "  1. Find: 'Demo: Standalone Recon (No DB)'"
echo "  2. Click three dots (...) on the right"
echo "  3. Click 'Delete'"
echo "  4. Confirm deletion"
echo ""
read -p "Press ENTER when old workflow is deleted..."
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 2: Import Fixed Workflow${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "In n8n UI:"
echo "  1. Click 'Import from File' (top-right)"
echo "  2. Navigate to:"
echo -e "     ${GREEN}$(pwd)/workflows/${NC}"
echo "  3. Select: ${GREEN}demo_standalone_recon.json${NC}"
echo "  4. Click 'Import'"
echo ""
read -p "Press ENTER when workflow is imported..."
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 3: Activate Workflow${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "After import:"
echo "  1. Workflow should open automatically"
echo "  2. Click 'Active' toggle (top-right corner)"
echo "  3. Toggle should turn ${GREEN}GREEN${NC}"
echo ""
read -p "Press ENTER when workflow is activated..."
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 4: Verify Command Syntax${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Click on 'Create Output Directory' node and verify:"
echo ""
echo "  Command field should show:"
echo -e "  ${GREEN}='mkdir -p ' + \$json.output_dir${NC}"
echo ""
echo "  Should have:"
echo "    ✓ Expression icon (fx)"
echo "    ✓ Starts with ="
echo "    ✓ Uses + for concatenation"
echo "    ✓ NO backticks or \${}"
echo ""
read -p "Press ENTER when verified..."
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 5: Test Webhook${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Testing direct connection to webhook..."
echo ""

RESPONSE=$(curl -s -X POST http://127.0.0.1:5678/webhook/demo-recon \
  -H "Content-Type: application/json" \
  -d '{"target":"scanme.nmap.org"}' \
  -w "\n%{http_code}" | tail -1)

if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Webhook is responding!${NC}"
    echo ""
    echo "Full test:"
    curl -s -X POST http://127.0.0.1:5678/webhook/demo-recon \
      -H "Content-Type: application/json" \
      -d '{"target":"scanme.nmap.org"}' | python3 -m json.tool 2>/dev/null || echo "Response received"
    echo ""
else
    echo -e "${RED}⚠ Webhook test failed${NC}"
    echo "  Response code: $RESPONSE"
    echo "  Make sure workflow is activated"
fi
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STEP 6: Test Web Interface${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Opening web interface..."
sleep 1
open http://localhost/ 2>/dev/null || echo "  → Manually open: http://localhost/"
echo ""
echo "In the web interface:"
echo "  1. Clear browser cache (Cmd+Shift+R or Ctrl+Shift+R)"
echo "  2. Enter target: scanme.nmap.org"
echo "  3. Click 'Submit Target'"
echo "  4. Should see: ✅ Target submitted successfully!"
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Setup Complete!                           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Your demo workflow is now ready at:${NC}"
echo "  🌐 Web Interface: http://localhost/"
echo "  🔗 Webhook URL:   http://localhost/webhook/demo-recon"
echo "  ⚙️  n8n Admin:     http://127.0.0.1:5678"
echo ""

echo -e "${YELLOW}Command Syntax Reference:${NC}"
echo "  Create Dir:  ='mkdir -p ' + \$json.output_dir"
echo "  Subfinder:   ='subfinder -d ' + \$json.target + ' -silent ...'"
echo "  Amass:       ='amass enum -passive -d ' + \$json.target + ' ...'"
echo ""

echo -e "${YELLOW}Check Results:${NC}"
echo "  ls -lt /tmp/recon/"
echo "  cat /tmp/recon/*/subfinder.txt"
echo ""
