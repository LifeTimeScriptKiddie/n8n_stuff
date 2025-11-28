-- ============================================================================
-- Phase C & D: Findings, Loot, and Enrichment Migration
-- ============================================================================
-- Adds:
-- - Vulnerability findings
-- - Loot/artifact storage
-- - Enrichment data
-- - Notifications
-- ============================================================================

-- ============================================================================
-- FINDINGS TABLE (Vulnerability and security findings)
-- ============================================================================
CREATE TABLE IF NOT EXISTS findings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    host_id UUID REFERENCES hosts(id) ON DELETE SET NULL,
    port_id UUID REFERENCES ports(id) ON DELETE SET NULL,

    -- Finding details
    finding_type VARCHAR(100) NOT NULL,     -- vulnerability, misconfiguration, info_disclosure
    severity VARCHAR(20) NOT NULL,          -- critical, high, medium, low, info
    title VARCHAR(500) NOT NULL,
    description TEXT,

    -- Technical details
    cve_ids TEXT[],
    cwe_ids TEXT[],
    cvss_score DECIMAL(3,1),
    cvss_vector VARCHAR(100),

    -- Evidence
    evidence_id UUID REFERENCES evidence(id),
    proof TEXT,                             -- PoC or evidence of finding
    affected_component VARCHAR(255),
    affected_url TEXT,

    -- Remediation
    remediation TEXT,
    references TEXT[],

    -- Status tracking
    status VARCHAR(20) DEFAULT 'open',      -- open, confirmed, false_positive, remediated
    verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP,
    verified_by VARCHAR(255),

    -- Deduplication
    finding_hash VARCHAR(64),

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    tags TEXT[],

    -- Timestamps
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_findings_project ON findings(project_id);
CREATE INDEX idx_findings_host ON findings(host_id);
CREATE INDEX idx_findings_severity ON findings(severity);
CREATE INDEX idx_findings_type ON findings(finding_type);
CREATE INDEX idx_findings_status ON findings(status);
CREATE INDEX idx_findings_hash ON findings(finding_hash);
CREATE INDEX idx_findings_cve ON findings USING GIN(cve_ids);
CREATE INDEX idx_findings_discovered ON findings(discovered_at);

-- ============================================================================
-- LOOT TABLE (Extracted artifacts and sensitive data)
-- ============================================================================
CREATE TABLE IF NOT EXISTS loot (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    host_id UUID REFERENCES hosts(id) ON DELETE SET NULL,

    -- Loot details
    loot_type VARCHAR(50) NOT NULL,         -- sam_dump, config_file, database, ssh_key, certificate
    name VARCHAR(255),
    description TEXT,

    -- Storage
    minio_bucket VARCHAR(100),
    minio_path VARCHAR(500),
    file_hash_sha256 VARCHAR(64),
    file_size_bytes BIGINT,

    -- Content analysis
    contains_credentials BOOLEAN DEFAULT FALSE,
    contains_pii BOOLEAN DEFAULT FALSE,
    sensitivity_level VARCHAR(20) DEFAULT 'medium', -- critical, high, medium, low

    -- Extracted data references
    extracted_credentials UUID[],           -- References to secure_credentials

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_loot_project ON loot(project_id);
CREATE INDEX idx_loot_host ON loot(host_id);
CREATE INDEX idx_loot_type ON loot(loot_type);
CREATE INDEX idx_loot_sensitivity ON loot(sensitivity_level);
CREATE INDEX idx_loot_has_creds ON loot(contains_credentials);

-- ============================================================================
-- ENRICHMENT TABLE (External data enrichment)
-- ============================================================================
CREATE TABLE IF NOT EXISTS enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    host_id UUID REFERENCES hosts(id) ON DELETE CASCADE,
    port_id UUID REFERENCES ports(id) ON DELETE SET NULL,

    -- Enrichment type
    enrichment_type VARCHAR(50) NOT NULL,   -- cpe, cve, whois, asn, ssl_cert, wappalyzer
    source VARCHAR(100),                    -- nvd, shodan, censys, etc

    -- Data
    data JSONB NOT NULL,

    -- Timestamps
    enriched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_enrichment_project ON enrichment(project_id);
CREATE INDEX idx_enrichment_host ON enrichment(host_id);
CREATE INDEX idx_enrichment_type ON enrichment(enrichment_type);
CREATE INDEX idx_enrichment_source ON enrichment(source);

-- ============================================================================
-- NOTIFICATIONS TABLE (Alert and notification tracking)
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

    -- Notification details
    notification_type VARCHAR(50) NOT NULL, -- critical_finding, pivot_success, scan_complete
    severity VARCHAR(20) DEFAULT 'info',
    title VARCHAR(255) NOT NULL,
    message TEXT,

    -- Related entities
    entity_type VARCHAR(50),
    entity_id UUID,

    -- Delivery
    channels TEXT[] DEFAULT ARRAY['database'], -- database, slack, email
    delivered_to JSONB DEFAULT '{}'::jsonb,

    -- Status
    status VARCHAR(20) DEFAULT 'pending',   -- pending, sent, failed, acknowledged
    acknowledged_at TIMESTAMP,
    acknowledged_by VARCHAR(255),

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP
);

CREATE INDEX idx_notifications_project ON notifications(project_id);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_severity ON notifications(severity);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- ============================================================================
-- APPROVAL QUEUE TABLE (For high-risk actions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS approval_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

    -- Action details
    action_type VARCHAR(50) NOT NULL,       -- credential_test, intrusive_scan, data_exfil
    description TEXT NOT NULL,
    risk_level VARCHAR(20) NOT NULL,        -- critical, high, medium

    -- Target
    target_entity_type VARCHAR(50),
    target_entity_id UUID,
    target_description TEXT,

    -- Request details
    requested_by VARCHAR(255),
    request_reason TEXT,

    -- Approval details
    status VARCHAR(20) DEFAULT 'pending',   -- pending, approved, rejected, expired
    approved_by VARCHAR(255),
    approval_reason TEXT,
    approved_at TIMESTAMP,

    -- Expiration
    expires_at TIMESTAMP,

    -- Execution tracking
    executed BOOLEAN DEFAULT FALSE,
    executed_at TIMESTAMP,
    execution_result JSONB,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_approval_queue_project ON approval_queue(project_id);
CREATE INDEX idx_approval_queue_status ON approval_queue(status);
CREATE INDEX idx_approval_queue_action ON approval_queue(action_type);
CREATE INDEX idx_approval_queue_expires ON approval_queue(expires_at);

-- ============================================================================
-- VIEWS FOR ANALYSIS
-- ============================================================================

-- View: Finding summary by severity
CREATE OR REPLACE VIEW finding_summary AS
SELECT
    f.project_id,
    p.name as project_name,
    f.severity,
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE f.status = 'open') as open_count,
    COUNT(*) FILTER (WHERE f.verified) as verified_count
FROM findings f
JOIN projects p ON p.id = f.project_id
GROUP BY f.project_id, p.name, f.severity
ORDER BY
    CASE f.severity
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
        ELSE 5
    END;

-- View: Recent critical findings
CREATE OR REPLACE VIEW recent_critical_findings AS
SELECT
    f.*,
    h.ip_address,
    h.hostname,
    p.name as project_name
FROM findings f
JOIN projects p ON p.id = f.project_id
LEFT JOIN hosts h ON h.id = f.host_id
WHERE f.severity IN ('critical', 'high')
AND f.status = 'open'
ORDER BY f.discovered_at DESC
LIMIT 50;

-- View: Loot with credentials
CREATE OR REPLACE VIEW loot_with_credentials AS
SELECT
    l.*,
    h.ip_address,
    h.hostname,
    array_length(l.extracted_credentials, 1) as credential_count
FROM loot l
LEFT JOIN hosts h ON h.id = l.host_id
WHERE l.contains_credentials = TRUE
ORDER BY l.discovered_at DESC;

-- View: Pending approvals
CREATE OR REPLACE VIEW pending_approvals AS
SELECT
    aq.*,
    p.name as project_name
FROM approval_queue aq
JOIN projects p ON p.id = aq.project_id
WHERE aq.status = 'pending'
AND (aq.expires_at IS NULL OR aq.expires_at > NOW())
ORDER BY
    CASE aq.risk_level
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        ELSE 3
    END,
    aq.created_at ASC;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to create notification
CREATE OR REPLACE FUNCTION create_notification(
    p_project_id UUID,
    p_type VARCHAR,
    p_severity VARCHAR,
    p_title VARCHAR,
    p_message TEXT,
    p_entity_type VARCHAR DEFAULT NULL,
    p_entity_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO notifications (
        project_id,
        notification_type,
        severity,
        title,
        message,
        entity_type,
        entity_id
    ) VALUES (
        p_project_id,
        p_type,
        p_severity,
        p_title,
        p_message,
        p_entity_type,
        p_entity_id
    )
    RETURNING id INTO v_notification_id;

    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate finding hash for deduplication
CREATE OR REPLACE FUNCTION calculate_finding_hash(
    p_host_id UUID,
    p_port_id UUID,
    p_finding_type VARCHAR,
    p_title VARCHAR,
    p_affected_component VARCHAR
) RETURNS VARCHAR AS $$
BEGIN
    RETURN encode(
        sha256(
            (COALESCE(p_host_id::text, '') ||
             COALESCE(p_port_id::text, '') ||
             COALESCE(p_finding_type, '') ||
             COALESCE(p_title, '') ||
             COALESCE(p_affected_component, ''))::bytea
        ),
        'hex'
    );
END;
$$ LANGUAGE plpgsql;

-- Trigger to update findings updated_at
CREATE TRIGGER update_findings_updated_at
    BEFORE UPDATE ON findings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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
    RAISE NOTICE 'Phase C & D Migration completed!';
    RAISE NOTICE 'New tables: findings, loot, enrichment, notifications, approval_queue';
    RAISE NOTICE 'New views: finding_summary, recent_critical_findings, loot_with_credentials, pending_approvals';
    RAISE NOTICE 'New functions: create_notification, calculate_finding_hash';
END $$;
