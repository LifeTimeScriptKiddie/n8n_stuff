-- ============================================================================
-- Migration 009: Agent Architecture & Approval System
-- ============================================================================

BEGIN;

-- Add agent session tracking
ALTER TABLE scan_jobs ADD COLUMN IF NOT EXISTS agent_session_id VARCHAR(64);
ALTER TABLE scan_jobs ADD COLUMN IF NOT EXISTS orchestrated_by VARCHAR(50);
CREATE INDEX IF NOT EXISTS idx_scan_jobs_agent_session ON scan_jobs(agent_session_id);

-- Enhance approval_queue for agent decisions
ALTER TABLE approval_queue ADD COLUMN IF NOT EXISTS agent_decision_id UUID REFERENCES agent_decisions(id);
ALTER TABLE approval_queue ADD COLUMN IF NOT EXISTS risk_score DECIMAL(5,2);
ALTER TABLE approval_queue ADD COLUMN IF NOT EXISTS auto_approved BOOLEAN DEFAULT FALSE;
CREATE INDEX IF NOT EXISTS idx_approval_queue_agent_decision ON approval_queue(agent_decision_id);

-- Add exploit tracking table
CREATE TABLE IF NOT EXISTS exploit_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    finding_id UUID REFERENCES findings(id) ON DELETE SET NULL,
    approval_id UUID REFERENCES approval_queue(id),

    exploit_type VARCHAR(50) NOT NULL, -- 'sqlmap', 'metasploit', 'manual'
    exploit_module VARCHAR(255),
    target_host VARCHAR(255) NOT NULL,
    target_port INTEGER,

    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'running', 'success', 'failed'
    command TEXT,
    results JSONB,

    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_exploit_executions_project ON exploit_executions(project_id);
CREATE INDEX idx_exploit_executions_finding ON exploit_executions(finding_id);
CREATE INDEX idx_exploit_executions_status ON exploit_executions(status);

COMMENT ON TABLE exploit_executions IS 'Tracks exploitation attempts with approval workflow';

GRANT SELECT, INSERT, UPDATE, DELETE ON exploit_executions TO recon_user;

COMMIT;

SELECT 'Migration 009 completed: Agent architecture enhanced!' as status;
