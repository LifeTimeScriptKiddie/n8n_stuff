-- ============================================================================
-- Migration: 004_add_missing_workflow_tables
-- Purpose: Add missing tables required by Phase 2, 3, and 4 workflows
-- Date: 2025-11-18
-- Dependencies: 001_red_team_enhancements.sql
-- ============================================================================

-- ============================================================================
-- 1. HTTP SERVICES TABLE
-- ============================================================================
-- Stores discovered HTTP/HTTPS services from httpx scans
CREATE TABLE IF NOT EXISTS http_services (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) REFERENCES recon_sessions(session_id) ON DELETE CASCADE,
    host VARCHAR(255) NOT NULL,
    url TEXT NOT NULL,
    status_code INTEGER,
    title TEXT,
    server TEXT,
    content_length INTEGER,
    technologies JSONB DEFAULT '[]'::jsonb,
    ip INET,
    cname TEXT,
    cdn BOOLEAN DEFAULT false,
    scheme VARCHAR(10),
    port INTEGER,
    response_time NUMERIC(10,3),
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(session_id, url)
);

CREATE INDEX IF NOT EXISTS idx_http_services_session ON http_services(session_id);
CREATE INDEX IF NOT EXISTS idx_http_services_host ON http_services(host);
CREATE INDEX IF NOT EXISTS idx_http_services_status ON http_services(status_code);
CREATE INDEX IF NOT EXISTS idx_http_services_discovered ON http_services(discovered_at);

COMMENT ON TABLE http_services IS 'HTTP/HTTPS services discovered during active reconnaissance';

-- ============================================================================
-- 2. PORT SCAN RESULTS TABLE
-- ============================================================================
-- Stores open ports discovered via nmap/naabu scans
CREATE TABLE IF NOT EXISTS port_scan_results (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) REFERENCES recon_sessions(session_id) ON DELETE CASCADE,
    host VARCHAR(255) NOT NULL,
    ip INET NOT NULL,
    port INTEGER NOT NULL,
    protocol VARCHAR(10) DEFAULT 'tcp',
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(session_id, host, port)
);

CREATE INDEX IF NOT EXISTS idx_port_scan_session ON port_scan_results(session_id);
CREATE INDEX IF NOT EXISTS idx_port_scan_host ON port_scan_results(host);
CREATE INDEX IF NOT EXISTS idx_port_scan_ip ON port_scan_results(ip);
CREATE INDEX IF NOT EXISTS idx_port_scan_port ON port_scan_results(port);

COMMENT ON TABLE port_scan_results IS 'Open ports discovered during network scanning';

-- ============================================================================
-- 3. VULNERABILITY FINDINGS TABLE
-- ============================================================================
-- Comprehensive vulnerability findings from all assessment tools
CREATE TABLE IF NOT EXISTS vulnerability_findings (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) REFERENCES recon_sessions(session_id) ON DELETE CASCADE,
    vuln_type VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    host VARCHAR(255),
    url TEXT,
    description TEXT,
    details JSONB DEFAULT '{}'::jsonb,
    finding_hash VARCHAR(64) UNIQUE,
    risk_score NUMERIC(5,2),
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_vuln_findings_session ON vulnerability_findings(session_id);
CREATE INDEX IF NOT EXISTS idx_vuln_findings_severity ON vulnerability_findings(severity);
CREATE INDEX IF NOT EXISTS idx_vuln_findings_type ON vulnerability_findings(vuln_type);
CREATE INDEX IF NOT EXISTS idx_vuln_findings_hash ON vulnerability_findings(finding_hash);
CREATE INDEX IF NOT EXISTS idx_vuln_findings_host ON vulnerability_findings(host);

COMMENT ON TABLE vulnerability_findings IS 'All vulnerability findings from security assessments';

-- ============================================================================
-- 4. SCREENSHOTS TABLE
-- ============================================================================
-- Metadata about screenshots captured of live web services
CREATE TABLE IF NOT EXISTS screenshots (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) REFERENCES recon_sessions(session_id) ON DELETE CASCADE,
    screenshot_path TEXT NOT NULL,
    screenshot_count INTEGER DEFAULT 0,
    captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_screenshots_session ON screenshots(session_id);
CREATE INDEX IF NOT EXISTS idx_screenshots_captured ON screenshots(captured_at);

COMMENT ON TABLE screenshots IS 'Screenshot metadata for web service captures';

-- ============================================================================
-- 5. SCAN REPORTS TABLE
-- ============================================================================
-- Final generated reports for completed scans
CREATE TABLE IF NOT EXISTS scan_reports (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) REFERENCES recon_sessions(session_id) ON DELETE CASCADE,
    report_format VARCHAR(50) DEFAULT 'markdown',
    report_content TEXT,
    report_summary JSONB DEFAULT '{}'::jsonb,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_scan_reports_session ON scan_reports(session_id);
CREATE INDEX IF NOT EXISTS idx_scan_reports_generated ON scan_reports(generated_at);

COMMENT ON TABLE scan_reports IS 'Final scan reports generated in Phase 4';

-- ============================================================================
-- TRIGGERS FOR AUTO-UPDATING
-- ============================================================================

-- Trigger to update updated_at for http_services
CREATE OR REPLACE FUNCTION update_http_services_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_http_services_updated_at ON http_services;

CREATE TRIGGER trigger_update_http_services_updated_at
    BEFORE UPDATE ON http_services
    FOR EACH ROW
    EXECUTE FUNCTION update_http_services_updated_at();

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT ALL PRIVILEGES ON TABLE http_services TO recon_user;
GRANT ALL PRIVILEGES ON TABLE port_scan_results TO recon_user;
GRANT ALL PRIVILEGES ON TABLE vulnerability_findings TO recon_user;
GRANT ALL PRIVILEGES ON TABLE screenshots TO recon_user;
GRANT ALL PRIVILEGES ON TABLE scan_reports TO recon_user;

GRANT ALL PRIVILEGES ON SEQUENCE http_services_id_seq TO recon_user;
GRANT ALL PRIVILEGES ON SEQUENCE port_scan_results_id_seq TO recon_user;
GRANT ALL PRIVILEGES ON SEQUENCE vulnerability_findings_id_seq TO recon_user;
GRANT ALL PRIVILEGES ON SEQUENCE screenshots_id_seq TO recon_user;
GRANT ALL PRIVILEGES ON SEQUENCE scan_reports_id_seq TO recon_user;

-- ============================================================================
-- MIGRATION TRACKING
-- ============================================================================

INSERT INTO schema_migrations (version, description)
VALUES (4, 'Add missing workflow tables: http_services, port_scan_results, vulnerability_findings, screenshots, scan_reports')
ON CONFLICT (version) DO NOTHING;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Migration 004 - Add Missing Workflow Tables: COMPLETED';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'New tables added: 5';
    RAISE NOTICE '  - http_services (HTTP/HTTPS service discovery)';
    RAISE NOTICE '  - port_scan_results (open port tracking)';
    RAISE NOTICE '  - vulnerability_findings (comprehensive vulns)';
    RAISE NOTICE '  - screenshots (screenshot metadata)';
    RAISE NOTICE '  - scan_reports (final reports)';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'All workflow database requirements met!';
    RAISE NOTICE '============================================================';
END $$;
