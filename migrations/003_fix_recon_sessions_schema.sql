-- ============================================================================
-- n8n Reconnaissance Hub - Migration 003
-- ============================================================================
-- Migration: 003_fix_recon_sessions_schema
-- Purpose: Add missing columns to recon_sessions table for n8n workflow compatibility
-- Date: 2025-11-18
-- ============================================================================

-- Add missing columns to recon_sessions table
ALTER TABLE recon_sessions
    ADD COLUMN IF NOT EXISTS session_id VARCHAR(255) UNIQUE,
    ADD COLUMN IF NOT EXISTS target VARCHAR(255),
    ADD COLUMN IF NOT EXISTS scope_file VARCHAR(255) DEFAULT 'default',
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Create index for session_id
CREATE INDEX IF NOT EXISTS idx_session_id ON recon_sessions(session_id);

-- Create trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_recon_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_recon_sessions_updated_at ON recon_sessions;

CREATE TRIGGER trigger_update_recon_sessions_updated_at
    BEFORE UPDATE ON recon_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_recon_sessions_updated_at();

-- Populate session_id with session_name for existing records
UPDATE recon_sessions
SET session_id = session_name
WHERE session_id IS NULL;

-- Populate target with target_scope for existing records
UPDATE recon_sessions
SET target = target_scope
WHERE target IS NULL;

-- Add migration tracking
INSERT INTO schema_migrations (version, description)
VALUES (3, 'Add session_id, target, scope_file, updated_at, created_at columns to recon_sessions')
ON CONFLICT (version) DO NOTHING;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Migration 003 - Fix recon_sessions Schema: COMPLETED';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Added columns to recon_sessions:';
    RAISE NOTICE '  - session_id VARCHAR(255) UNIQUE';
    RAISE NOTICE '  - target VARCHAR(255)';
    RAISE NOTICE '  - scope_file VARCHAR(255) DEFAULT ''default''';
    RAISE NOTICE '  - updated_at TIMESTAMP with auto-update trigger';
    RAISE NOTICE '  - created_at TIMESTAMP';
    RAISE NOTICE 'Existing records populated with session_name -> session_id';
    RAISE NOTICE 'Existing records populated with target_scope -> target';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'n8n workflows should now work correctly!';
    RAISE NOTICE '============================================================';
END $$;
