#!/bin/bash
# n8n Offline User Addition Script
# This script adds users directly to the n8n database

set -e

echo "================================"
echo "n8n Offline User Addition"
echo "================================"
echo ""

# Prompt for user details
read -p "Email: " EMAIL
read -p "First Name: " FIRSTNAME
read -p "Last Name: " LASTNAME
read -sp "Password: " PASSWORD
echo ""

# Prompt for role
echo ""
echo "Available roles:"
echo "  1) global:owner   - Owner (full system access)"
echo "  2) global:admin   - Admin (can manage workflows and users)"
echo "  3) global:member  - Member (can create/edit own workflows)"
echo ""
read -p "Select role (1-3) [default: 3]: " ROLE_CHOICE

case $ROLE_CHOICE in
  1) ROLE="global:owner" ;;
  2) ROLE="global:admin" ;;
  3|"") ROLE="global:member" ;;
  *) echo "Invalid choice. Using 'global:member'"; ROLE="global:member" ;;
esac

echo ""
echo "Creating user with:"
echo "  Email: $EMAIL"
echo "  Name: $FIRSTNAME $LASTNAME"
echo "  Role: $ROLE"
echo ""
read -p "Confirm? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Cancelled."
  exit 0
fi

# Execute the Node.js script inside the container
docker compose exec \
  -e USER_EMAIL="$EMAIL" \
  -e USER_FIRSTNAME="$FIRSTNAME" \
  -e USER_LASTNAME="$LASTNAME" \
  -e USER_PASSWORD="$PASSWORD" \
  -e USER_ROLE="$ROLE" \
  n8n-recon bash -c 'node -e "
const bcrypt = require(\"/usr/local/lib/node_modules/n8n/node_modules/.pnpm/bcryptjs@2.4.3/node_modules/bcryptjs\");
const { Client } = require(\"/usr/local/lib/node_modules/n8n/node_modules/.pnpm/pg@8.12.0/node_modules/pg\");

async function addUser() {
  const email = process.env.USER_EMAIL;
  const firstName = process.env.USER_FIRSTNAME;
  const lastName = process.env.USER_LASTNAME;
  const password = process.env.USER_PASSWORD;
  const role = process.env.USER_ROLE;

  const saltRounds = 10;
  const hashedPassword = await bcrypt.hash(password, saltRounds);

  const client = new Client({
    host: \"postgres\",
    port: 5432,
    user: process.env.DB_POSTGRESDB_USER,
    password: process.env.DB_POSTGRESDB_PASSWORD,
    database: process.env.DB_POSTGRESDB_DATABASE
  });

  await client.connect();

  try {
    const checkResult = await client.query(
      \"SELECT id FROM \\\"user\\\" WHERE email = \$1\",
      [email]
    );

    if (checkResult.rows.length > 0) {
      console.log(\"ERROR: User with this email already exists!\");
      await client.end();
      process.exit(1);
    }

    const result = await client.query(
      \"INSERT INTO \\\"user\\\" (email, \\\"firstName\\\", \\\"lastName\\\", password, \\\"roleSlug\\\", disabled, \\\"mfaEnabled\\\") VALUES (\$1, \$2, \$3, \$4, \$5, false, false) RETURNING id, email, \\\"firstName\\\", \\\"lastName\\\", \\\"roleSlug\\\"\",
      [email, firstName, lastName, hashedPassword, role]
    );

    console.log(\"\");
    console.log(\"✅ User created successfully!\");
    console.log(\"----------------------------\");
    console.log(\"ID:\", result.rows[0].id);
    console.log(\"Email:\", result.rows[0].email);
    console.log(\"Name:\", result.rows[0].firstName, result.rows[0].lastName);
    console.log(\"Role:\", result.rows[0].roleSlug);
    console.log(\"\");
    console.log(\"The user can now log in at http://localhost:5678\");

  } catch (error) {
    console.error(\"ERROR:\", error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

addUser();
"'

echo ""
echo "================================"
echo "Done!"
echo "================================"
