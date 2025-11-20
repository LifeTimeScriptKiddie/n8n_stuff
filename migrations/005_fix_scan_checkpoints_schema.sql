-- Migration 005: Fix scan_checkpoints table schema for workflow compatibility
-- Adds columns that workflows expect while preserving existing structure

-- Add checkpoint_name column (workflows use this instead of step_name)
ALTER TABLE scan_checkpoints
    ADD COLUMN IF NOT EXISTS checkpoint_name VARCHAR(255);

-- Add checkpoint_data column (workflows use this instead of data)
ALTER TABLE scan_checkpoints
    ADD COLUMN IF NOT EXISTS checkpoint_data JSONB;

-- Add created_at column (workflows use this instead of checkpoint_time)
ALTER TABLE scan_checkpoints
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Make step_number nullable (workflows don't use step numbers)
ALTER TABLE scan_checkpoints
    ALTER COLUMN step_number DROP NOT NULL;

-- Modify session_id to accept VARCHAR (workflows use session_id string, not integer ID)
-- First, drop the foreign key constraint
ALTER TABLE scan_checkpoints
    DROP CONSTRAINT IF EXISTS scan_checkpoints_session_id_fkey;

-- Change session_id from INTEGER to VARCHAR to match workflow usage
ALTER TABLE scan_checkpoints
    ALTER COLUMN session_id TYPE VARCHAR(255) USING session_id::VARCHAR;

-- Drop the unique constraint that uses session_id as integer
ALTER TABLE scan_checkpoints
    DROP CONSTRAINT IF EXISTS scan_checkpoints_session_id_phase_step_number_key;

-- Create new unique constraint for the VARCHAR session_id
-- Note: step_number may not be used by workflows, so making it optional
CREATE UNIQUE INDEX IF NOT EXISTS idx_checkpoints_session_phase_name
    ON scan_checkpoints(session_id, phase, checkpoint_name)
    WHERE checkpoint_name IS NOT NULL;

-- Update existing data: copy step_name to checkpoint_name, data to checkpoint_data
UPDATE scan_checkpoints
SET
    checkpoint_name = step_name,
    checkpoint_data = data,
    created_at = COALESCE(checkpoint_time, CURRENT_TIMESTAMP)
WHERE checkpoint_name IS NULL;

-- Create index on checkpoint_name for faster lookups
CREATE INDEX IF NOT EXISTS idx_checkpoint_name ON scan_checkpoints(checkpoint_name);

-- Create index on created_at for time-based queries
CREATE INDEX IF NOT EXISTS idx_checkpoint_created_at ON scan_checkpoints(created_at);
