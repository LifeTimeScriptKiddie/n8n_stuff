#!/bin/bash
# n8n User Deletion Script
# Deletes a user from the n8n database

set -e

echo "================================"
echo "n8n User Deletion"
echo "================================"
echo ""

read -p "Email of user to delete: " EMAIL

if [ -z "$EMAIL" ]; then
  echo "Error: Email cannot be empty"
  exit 1
fi

echo ""
echo "⚠️  WARNING: This will permanently delete the user!"
echo "Email: $EMAIL"
echo ""
read -p "Are you sure? (type 'DELETE' to confirm): " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
  echo "Cancelled."
  exit 0
fi

# Delete the user
docker compose exec postgres psql -U recon_user -d recon_hub -c "
DELETE FROM \"user\" WHERE email = '$EMAIL';
" 2>&1 | grep -v "^time=" | grep -v "level=warning"

echo ""
echo "✅ User deleted (if it existed)"
echo ""
