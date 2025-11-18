# Database Migrations Guide

## Overview

The n8n Reconnaissance Hub uses a two-tier database initialization system:

1. **`init-db.sql`** - Base schema (automatically applied on first database creation)
2. **`migrations/`** - Schema updates and enhancements (automatically applied by `setup.sh`)

## How It Works

### Initial Setup

When you run `./setup.sh` for the first time:

1. Docker creates the PostgreSQL container
2. `init-db.sql` is automatically executed (mounted in docker-compose.yml)
3. Migration files from `migrations/` are applied in alphabetical order
4. Your database is ready to use!

### Schema Updates

The `recon_sessions` table was updated to support n8n workflow compatibility:

**Original columns:**
- `id`, `session_name`, `target_scope`, `start_date`, `end_date`, `status`, `notes`

**Added columns (included in init-db.sql):**
- `session_id` - Unique identifier for session tracking
- `target` - Target host/domain
- `scope_file` - Reference to scope configuration file
- `created_at` - Record creation timestamp
- `updated_at` - Auto-updated on record changes (via trigger)

## Migration Files

### Current Migrations

Located in `/migrations/`:

1. **`001_red_team_enhancements.sql`**
   - Adds 11 new tables for advanced red team operations
   - Scope management, deduplication, checkpoints, API rate limiting
   - Stealth profiles, attack chains, passive intel, security headers

2. **`002_ngrok_oast_tables.sql`** *(archived)*
   - OAST (Out-of-Band Application Security Testing) support
   - Ngrok tunnel integration for blind vulnerability detection

3. **`003_fix_recon_sessions_schema.sql`**
   - Adds session_id, target, scope_file, updated_at columns
   - Creates auto-update trigger for updated_at
   - **Note:** These changes are now included in `init-db.sql`

## Applying Migrations Manually

If you need to apply migrations manually:

```bash
# Apply a specific migration
docker exec -i recon_postgres psql -U recon_user -d recon_hub < migrations/001_red_team_enhancements.sql

# Apply all migrations
for migration in migrations/*.sql; do
    echo "Applying $migration..."
    docker exec -i recon_postgres psql -U recon_user -d recon_hub < "$migration"
done
```

## Creating New Migrations

### Best Practices

1. **Use sequential numbering:** `004_description.sql`, `005_description.sql`
2. **Use idempotent SQL:** Always use `IF NOT EXISTS`, `IF EXISTS`, `ON CONFLICT`
3. **Document changes:** Add comments explaining what and why
4. **Test locally first:** Apply to a test database before production

### Migration Template

```sql
-- ============================================================================
-- Migration: 004_your_feature_name
-- Purpose: Brief description of what this migration does
-- Date: YYYY-MM-DD
-- ============================================================================

-- Add new table
CREATE TABLE IF NOT EXISTS your_table (
    id SERIAL PRIMARY KEY,
    your_column VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add columns to existing table
ALTER TABLE existing_table
    ADD COLUMN IF NOT EXISTS new_column VARCHAR(255);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_your_index ON your_table(your_column);

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Migration 004 completed successfully';
END $$;
```

## Database Reset

If you need to completely reset the database:

```bash
# WARNING: This deletes ALL data!

# Stop services
docker compose down

# Delete database volume
docker volume rm recon_postgres_data

# Restart (will recreate database with init-db.sql + migrations)
./setup.sh
```

## Workflow Compatibility

### n8n Workflow Requirements

The updated `recon_sessions` table now supports the following n8n workflow pattern:

```sql
INSERT INTO recon_sessions (session_name, session_id, target_scope, target, status, scope_file, notes)
VALUES ('session-name', 'unique-id', 'example.com', 'example.com', 'initiated', 'default', 'notes')
ON CONFLICT (session_id) DO UPDATE SET
  status = 'initiated',
  updated_at = NOW()
RETURNING *;
```

### Key Features

- **Unique session tracking** via `session_id` column
- **Automatic timestamps** via `created_at` and `updated_at`
- **Conflict handling** using `ON CONFLICT (session_id)`
- **Auto-update trigger** keeps `updated_at` current

## Troubleshooting

### Migration Fails with "Already Exists" Error

This is normal if migrations were previously applied. The migration system uses idempotent SQL (`IF NOT EXISTS`) to safely reapply migrations.

### Column Missing Error in n8n Workflow

1. Check current schema:
   ```bash
   docker exec recon_postgres psql -U recon_user -d recon_hub -c "\d recon_sessions"
   ```

2. If columns are missing, apply migrations:
   ```bash
   docker exec -i recon_postgres psql -U recon_user -d recon_hub < migrations/003_fix_recon_sessions_schema.sql
   ```

3. For fresh install, just run:
   ```bash
   ./setup.sh
   ```

## Version History

### v1.0.0 (Initial Release)
- Base schema with 10 core tables
- Subdomain intel, network scans, vulnerabilities, etc.

### v1.1.0 (Red Team Enhancements)
- Migration 001: Advanced red team features
- 11 new tables, utility functions

### v1.2.0 (OAST Support)
- Migration 002: Out-of-band testing capabilities
- Ngrok integration, callback tracking

### v1.3.0 (Workflow Compatibility)
- Migration 003: Updated recon_sessions schema
- Added session_id, target, scope_file columns
- Auto-update trigger for updated_at
- **Changes integrated into init-db.sql**

## Support

For issues or questions:
- Check workflow node configuration in n8n
- Review database logs: `docker compose logs postgres`
- Verify schema: Use `\d table_name` in psql
- Create issue at your project repository

---

**Last Updated:** 2025-11-18
**Maintained By:** Your Project Team
