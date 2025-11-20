#!/bin/bash

# Re-import Fixed Demo Workflow
# This script helps you update the workflow in n8n

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Demo Workflow Update Guide ===${NC}\n"

echo -e "${GREEN}✓ Fixed workflow file: workflows/demo_standalone_recon.json${NC}\n"

echo -e "${YELLOW}What was fixed:${NC}"
echo "  - Execute Command nodes now use proper n8n expression syntax"
echo "  - Changed: command: \"mkdir -p {{ \$json.output_dir }}\""
echo "  - To:      command: \"=\`mkdir -p \${$json.output_dir}\`\""
echo ""

echo -e "${YELLOW}To update the workflow in n8n:${NC}\n"

echo "Option 1: Delete and Re-import (Recommended)"
echo "  1. Go to http://127.0.0.1:5678/workflows"
echo "  2. Find 'Demo: Standalone Recon (No DB)'"
echo "  3. Click the three dots (...) → Delete"
echo "  4. Click 'Import from File'"
echo "  5. Select: workflows/demo_standalone_recon.json"
echo "  6. Click 'Activate' (toggle in top-right)"
echo ""

echo "Option 2: Manual Edit (Quick Fix)"
echo "  1. Open the workflow in n8n"
echo "  2. Click on 'Create Output Directory' node"
echo "  3. In the Command field, click the expressions icon"
echo "  4. Change to: \`mkdir -p \${$json.output_dir}\`"
echo "  5. Repeat for 'Subfinder' and 'Amass' nodes"
echo "  6. Save the workflow"
echo ""

echo -e "${YELLOW}Test the updated workflow:${NC}"
echo "  curl -X POST http://localhost/webhook/demo-recon \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"target\": \"scanme.nmap.org\"}'"
echo ""

echo -e "${GREEN}The issue was:${NC}"
echo "  n8n Execute Command nodes need the '=' prefix to evaluate expressions"
echo "  Without it, the {{ }} syntax is passed literally to the shell"
echo ""

echo -e "${YELLOW}Quick verification after import:${NC}"
echo "  1. Open workflow in n8n"
echo "  2. Click on any Execute Command node"
echo "  3. The command field should show an expression (fx icon)"
echo "  4. It should start with = and use backticks with \${} syntax"
echo ""
