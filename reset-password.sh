#!/bin/bash
# n8n Password Reset Script
# Resets a user's password in the n8n database

set -e

echo "================================"
echo "n8n Password Reset"
echo "================================"
echo ""

read -p "Email of user: " EMAIL
read -sp "New Password: " PASSWORD
echo ""

if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
  echo "Error: Email and password cannot be empty"
  exit 1
fi

echo ""
read -p "Reset password for $EMAIL? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Cancelled."
  exit 0
fi

# Execute the Node.js script inside the container to hash password and update
docker compose exec \
  -e USER_EMAIL="$EMAIL" \
  -e USER_PASSWORD="$PASSWORD" \
  n8n-recon bash -c 'node -e "
const bcrypt = require(\"/usr/local/lib/node_modules/n8n/node_modules/.pnpm/bcryptjs@2.4.3/node_modules/bcryptjs\");
const { Client } = require(\"/usr/local/lib/node_modules/n8n/node_modules/.pnpm/pg@8.12.0/node_modules/pg\");

async function resetPassword() {
  const email = process.env.USER_EMAIL;
  const password = process.env.USER_PASSWORD;

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
    const result = await client.query(
      \"UPDATE \\\"user\\\" SET password = \$1, \\\"updatedAt\\\" = CURRENT_TIMESTAMP WHERE email = \$2 RETURNING email\",
      [hashedPassword, email]
    );

    if (result.rowCount === 0) {
      console.log(\"\");
      console.log(\"❌ Error: User not found\");
    } else {
      console.log(\"\");
      console.log(\"✅ Password reset successfully for:\", result.rows[0].email);
    }

  } catch (error) {
    console.error(\"ERROR:\", error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

resetPassword();
"'

echo ""
echo "================================"
echo "Done!"
echo "================================"
