#!/bin/bash
# n8n User Listing Script
# Lists all users in the n8n database

set -e

echo "================================"
echo "n8n Users"
echo "================================"
echo ""

# Query users from database
docker compose exec postgres psql -U recon_user -d recon_hub -c "
SELECT
  email,
  \"firstName\" || ' ' || \"lastName\" as name,
  \"roleSlug\" as role,
  CASE WHEN disabled THEN 'Yes' ELSE 'No' END as disabled,
  CASE WHEN \"mfaEnabled\" THEN 'Yes' ELSE 'No' END as mfa,
  \"createdAt\"::date as created
FROM \"user\"
ORDER BY \"createdAt\" DESC;
" 2>&1 | grep -v "^time=" | grep -v "level=warning"

echo ""
