-- ============================================================================
-- Phase A: Core Data Infrastructure Migration
-- ============================================================================
-- This migration adds the enterprise pentest data model with:
-- - Projects (multi-tenant root)
-- - Hosts, Ports, Services
-- - Evidence storage tracking
-- - Scan history
-- - System configuration
-- ============================================================================

-- Enable UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- PROJECTS TABLE (Multi-tenant root)
-- ============================================================================
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    scope JSONB DEFAULT '[]'::jsonb,  -- Array of in-scope targets
    roe JSONB DEFAULT '{}'::jsonb,    -- Rules of Engagement
    settings JSONB DEFAULT '{
        "retention_days_raw": 365,
        "retention_days_parsed": 1095,
        "retention_days_credentials": 90,
        "testing_windows": "24/7",
        "timezone": "UTC",
        "max_concurrent_scans": 3,
        "target_cooldown_minutes": 5,
        "credential_tests_per_hour": 100
    }'::jsonb,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_projects_name ON projects(name);
CREATE INDEX idx_projects_status ON projects(status);

-- ============================================================================
-- HOSTS TABLE (Discovered hosts per project)
-- ============================================================================
CREATE TABLE IF NOT EXISTS hosts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    ip_address INET,
    hostname VARCHAR(255),
    os_fingerprint VARCHAR(255),
    metadata JSONB DEFAULT '{}'::jsonb,
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, ip_address),
    CONSTRAINT hosts_has_ip_or_hostname CHECK (ip_address IS NOT NULL OR hostname IS NOT NULL)
);

CREATE INDEX idx_hosts_project ON hosts(project_id);
CREATE INDEX idx_hosts_ip ON hosts(ip_address);
CREATE INDEX idx_hosts_hostname ON hosts(hostname);

-- ============================================================================
-- PORTS TABLE (Open ports per host)
-- ============================================================================
CREATE TABLE IF NOT EXISTS ports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID NOT NULL REFERENCES hosts(id) ON DELETE CASCADE,
    port INTEGER NOT NULL,
    protocol VARCHAR(10) DEFAULT 'tcp',
    state VARCHAR(20) DEFAULT 'open',
    service_name VARCHAR(100),
    service_version VARCHAR(255),
    service_product VARCHAR(255),
    banner TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(host_id, port, protocol)
);

CREATE INDEX idx_ports_host ON ports(host_id);
CREATE INDEX idx_ports_port ON ports(port);
CREATE INDEX idx_ports_service ON ports(service_name);

-- ============================================================================
-- EVIDENCE TABLE (Raw evidence files stored in MinIO)
-- ============================================================================
CREATE TABLE IF NOT EXISTS evidence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    minio_bucket VARCHAR(100) NOT NULL,
    minio_path VARCHAR(500) NOT NULL,
    file_name VARCHAR(255),
    file_hash_sha256 VARCHAR(64) NOT NULL,
    file_size_bytes BIGINT,
    file_type VARCHAR(50),
    mime_type VARCHAR(100),
    parser_status VARCHAR(20) DEFAULT 'pending',  -- pending, processing, completed, failed
    parser_error TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    parsed_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_evidence_project ON evidence(project_id);
CREATE INDEX idx_evidence_hash ON evidence(file_hash_sha256);
CREATE INDEX idx_evidence_parser_status ON evidence(parser_status);
CREATE INDEX idx_evidence_expires ON evidence(expires_at);

-- ============================================================================
-- SCAN_JOBS TABLE (Track all scan executions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS scan_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    job_type VARCHAR(50) NOT NULL,  -- pentest, credential_test, enrichment
    status VARCHAR(20) DEFAULT 'queued',  -- queued, running, completed, failed, cancelled
    priority INTEGER DEFAULT 5,
    target TEXT,
    target_type VARCHAR(50),
    scan_mode VARCHAR(50),
    commands JSONB DEFAULT '[]'::jsonb,
    results JSONB DEFAULT '[]'::jsonb,
    evidence_id UUID REFERENCES evidence(id),
    report TEXT,
    error_message TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    queued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_scan_jobs_project ON scan_jobs(project_id);
CREATE INDEX idx_scan_jobs_status ON scan_jobs(status);
CREATE INDEX idx_scan_jobs_type ON scan_jobs(job_type);
CREATE INDEX idx_scan_jobs_queued ON scan_jobs(queued_at);

-- ============================================================================
-- RATE_LIMITS TABLE (Track rate limiting per target)
-- ============================================================================
CREATE TABLE IF NOT EXISTS rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    target VARCHAR(255) NOT NULL,
    limit_type VARCHAR(50) NOT NULL,  -- scan, credential_test
    last_action TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action_count INTEGER DEFAULT 1,
    cooldown_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, target, limit_type)
);

CREATE INDEX idx_rate_limits_project ON rate_limits(project_id);
CREATE INDEX idx_rate_limits_target ON rate_limits(target);
CREATE INDEX idx_rate_limits_cooldown ON rate_limits(cooldown_until);

-- ============================================================================
-- SYSTEM_CONFIG TABLE (Global system configuration)
-- ============================================================================
CREATE TABLE IF NOT EXISTS system_config (
    id SERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default system configuration
INSERT INTO system_config (key, value, description) VALUES
    ('encryption_algorithm', '"AES-256-GCM"', 'Algorithm for credential encryption'),
    ('ephemeral_ttl_seconds', '300', 'TTL for ephemeral credentials in Redis'),
    ('max_concurrent_scans', '3', 'Maximum concurrent scans system-wide'),
    ('default_retention_days', '365', 'Default data retention period'),
    ('rbac_roles', '["admin", "operator", "viewer"]', 'Available RBAC roles')
ON CONFLICT (key) DO NOTHING;

-- ============================================================================
-- AUDIT_LOG TABLE (Immutable audit trail)
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID REFERENCES projects(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    actor VARCHAR(255),
    details JSONB DEFAULT '{}'::jsonb,
    ip_address INET,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_log_project ON audit_log(project_id);
CREATE INDEX idx_audit_log_action ON audit_log(action);
CREATE INDEX idx_audit_log_created ON audit_log(created_at);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update last_seen timestamp
CREATE OR REPLACE FUNCTION update_last_seen_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_seen = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_projects_updated_at
    BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_hosts_last_seen
    BEFORE UPDATE ON hosts
    FOR EACH ROW EXECUTE FUNCTION update_last_seen_column();

CREATE TRIGGER update_ports_last_seen
    BEFORE UPDATE ON ports
    FOR EACH ROW EXECUTE FUNCTION update_last_seen_column();

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View: Project summary with counts
CREATE OR REPLACE VIEW project_summary AS
SELECT
    p.id,
    p.name,
    p.status,
    p.created_at,
    COUNT(DISTINCT h.id) as host_count,
    COUNT(DISTINCT pt.id) as port_count,
    COUNT(DISTINCT e.id) as evidence_count,
    COUNT(DISTINCT sj.id) as scan_count
FROM projects p
LEFT JOIN hosts h ON h.project_id = p.id
LEFT JOIN ports pt ON pt.host_id = h.id
LEFT JOIN evidence e ON e.project_id = p.id
LEFT JOIN scan_jobs sj ON sj.project_id = p.id
GROUP BY p.id, p.name, p.status, p.created_at;

-- View: Recent scan jobs
CREATE OR REPLACE VIEW recent_scan_jobs AS
SELECT
    sj.*,
    p.name as project_name
FROM scan_jobs sj
JOIN projects p ON p.id = sj.project_id
ORDER BY sj.created_at DESC
LIMIT 100;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO recon_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO recon_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO recon_user;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE 'Phase A Core Tables Migration completed successfully!';
    RAISE NOTICE 'New tables: projects, hosts, ports, evidence, scan_jobs, rate_limits, system_config, audit_log';
    RAISE NOTICE 'New views: project_summary, recent_scan_jobs';
END $$;
