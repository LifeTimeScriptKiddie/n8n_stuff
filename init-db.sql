-- ============================================================================
-- n8n Reconnaissance Hub - Database Initialization Script
-- ============================================================================
-- This script creates the PostgreSQL database schema for storing
-- offensive security reconnaissance data
-- ============================================================================

-- Subdomain Intelligence Table
CREATE TABLE IF NOT EXISTS subdomain_intel (
    id SERIAL PRIMARY KEY,
    domain VARCHAR(255) NOT NULL,
    subdomain VARCHAR(255) NOT NULL,
    source VARCHAR(100),
    ip VARCHAR(45),
    http_status INTEGER,
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(domain, subdomain)
);

CREATE INDEX idx_subdomain_domain ON subdomain_intel(domain);
CREATE INDEX idx_subdomain_ip ON subdomain_intel(ip);
CREATE INDEX idx_subdomain_discovered ON subdomain_intel(discovered_at);

-- Network Scans Table
CREATE TABLE IF NOT EXISTS network_scans (
    id SERIAL PRIMARY KEY,
    target VARCHAR(255) NOT NULL,
    scan_type VARCHAR(50),
    port INTEGER,
    service VARCHAR(100),
    version VARCHAR(255),
    vulnerabilities TEXT,
    scan_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_network_target ON network_scans(target);
CREATE INDEX idx_network_port ON network_scans(port);
CREATE INDEX idx_network_scan_date ON network_scans(scan_date);

-- SMB Enumeration Table
CREATE TABLE IF NOT EXISTS smb_enum (
    id SERIAL PRIMARY KEY,
    target VARCHAR(255) NOT NULL,
    hostname VARCHAR(255),
    domain VARCHAR(255),
    smb_version VARCHAR(100),
    shares TEXT,
    users TEXT,
    scan_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_smb_target ON smb_enum(target);
CREATE INDEX idx_smb_domain ON smb_enum(domain);

-- Vulnerabilities Table
CREATE TABLE IF NOT EXISTS vulnerabilities (
    id SERIAL PRIMARY KEY,
    target VARCHAR(255) NOT NULL,
    vulnerability_name VARCHAR(255),
    severity VARCHAR(20),
    cvss_score DECIMAL(3,1),
    description TEXT,
    cve_id VARCHAR(50),
    remediation TEXT,
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vuln_target ON vulnerabilities(target);
CREATE INDEX idx_vuln_severity ON vulnerabilities(severity);
CREATE INDEX idx_vuln_cvss ON vulnerabilities(cvss_score);
CREATE INDEX idx_vuln_cve ON vulnerabilities(cve_id);

-- Fuzzing Results Table
CREATE TABLE IF NOT EXISTS fuzzing_results (
    id SERIAL PRIMARY KEY,
    target_url TEXT NOT NULL,
    path TEXT,
    status_code INTEGER,
    content_length INTEGER,
    content_type VARCHAR(100),
    redirect_location TEXT,
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fuzzing_target ON fuzzing_results(target_url);
CREATE INDEX idx_fuzzing_status ON fuzzing_results(status_code);
CREATE INDEX idx_fuzzing_discovered ON fuzzing_results(discovered_at);

-- Credentials Table
CREATE TABLE IF NOT EXISTS credentials (
    id SERIAL PRIMARY KEY,
    target VARCHAR(255) NOT NULL,
    username VARCHAR(255),
    password TEXT,
    hash TEXT,
    service VARCHAR(100),
    protocol VARCHAR(50),
    status VARCHAR(20),
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_creds_target ON credentials(target);
CREATE INDEX idx_creds_service ON credentials(service);
CREATE INDEX idx_creds_status ON credentials(status);

-- Web Technologies Table
CREATE TABLE IF NOT EXISTS web_technologies (
    id SERIAL PRIMARY KEY,
    url TEXT NOT NULL,
    technology VARCHAR(255),
    version VARCHAR(100),
    category VARCHAR(100),
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_webtech_url ON web_technologies(url);
CREATE INDEX idx_webtech_tech ON web_technologies(technology);

-- Nuclei Scan Results Table
CREATE TABLE IF NOT EXISTS nuclei_results (
    id SERIAL PRIMARY KEY,
    target VARCHAR(255) NOT NULL,
    template_id VARCHAR(255),
    template_name VARCHAR(255),
    severity VARCHAR(20),
    matched_at TEXT,
    extracted_results TEXT,
    curl_command TEXT,
    scan_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_nuclei_target ON nuclei_results(target);
CREATE INDEX idx_nuclei_severity ON nuclei_results(severity);
CREATE INDEX idx_nuclei_template ON nuclei_results(template_id);

-- SQL Injection Results Table
CREATE TABLE IF NOT EXISTS sqli_results (
    id SERIAL PRIMARY KEY,
    target_url TEXT NOT NULL,
    parameter VARCHAR(255),
    injection_type VARCHAR(100),
    dbms VARCHAR(100),
    payload TEXT,
    database_name VARCHAR(255),
    extracted_data TEXT,
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sqli_target ON sqli_results(target_url);
CREATE INDEX idx_sqli_dbms ON sqli_results(dbms);

-- Recon Sessions Table (for tracking recon campaigns)
CREATE TABLE IF NOT EXISTS recon_sessions (
    id SERIAL PRIMARY KEY,
    session_name VARCHAR(255) NOT NULL UNIQUE,
    session_id VARCHAR(255) UNIQUE,
    target_scope TEXT,
    target VARCHAR(255),
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active',
    scope_file VARCHAR(255) DEFAULT 'default',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_session_status ON recon_sessions(status);
CREATE INDEX idx_session_start ON recon_sessions(start_date);
CREATE INDEX idx_session_id ON recon_sessions(session_id);

-- HTTP Services Table (Phase 2: Active Recon)
CREATE TABLE IF NOT EXISTS http_services (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
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

CREATE INDEX idx_http_services_session ON http_services(session_id);
CREATE INDEX idx_http_services_host ON http_services(host);

-- Port Scan Results Table (Phase 2: Active Recon)
CREATE TABLE IF NOT EXISTS port_scan_results (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    host VARCHAR(255) NOT NULL,
    ip INET NOT NULL,
    port INTEGER NOT NULL,
    protocol VARCHAR(10) DEFAULT 'tcp',
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(session_id, host, port)
);

CREATE INDEX idx_port_scan_session ON port_scan_results(session_id);
CREATE INDEX idx_port_scan_host ON port_scan_results(host);

-- Vulnerability Findings Table (Phase 3: Vulnerability Assessment)
CREATE TABLE IF NOT EXISTS vulnerability_findings (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
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

CREATE INDEX idx_vuln_findings_session ON vulnerability_findings(session_id);
CREATE INDEX idx_vuln_findings_severity ON vulnerability_findings(severity);
CREATE INDEX idx_vuln_findings_hash ON vulnerability_findings(finding_hash);

-- Screenshots Table (Phase 2: Active Recon)
CREATE TABLE IF NOT EXISTS screenshots (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    screenshot_path TEXT NOT NULL,
    screenshot_count INTEGER DEFAULT 0,
    captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_screenshots_session ON screenshots(session_id);

-- Scan Reports Table (Phase 4: Analysis & Reporting)
CREATE TABLE IF NOT EXISTS scan_reports (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    report_format VARCHAR(50) DEFAULT 'markdown',
    report_content TEXT,
    report_summary JSONB DEFAULT '{}'::jsonb,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_scan_reports_session ON scan_reports(session_id);

-- Comments for documentation
COMMENT ON TABLE subdomain_intel IS 'Stores discovered subdomains and their metadata';
COMMENT ON TABLE network_scans IS 'Network port scanning results from nmap, naabu';
COMMENT ON TABLE smb_enum IS 'SMB enumeration results from NetExec';
COMMENT ON TABLE vulnerabilities IS 'Vulnerability scan results';
COMMENT ON TABLE fuzzing_results IS 'Web fuzzing results from ffuf, dirb, etc';
COMMENT ON TABLE credentials IS 'Discovered or cracked credentials';
COMMENT ON TABLE web_technologies IS 'Detected web technologies and versions';
COMMENT ON TABLE nuclei_results IS 'Nuclei vulnerability scanner results';
COMMENT ON TABLE sqli_results IS 'SQL injection vulnerability findings';
COMMENT ON TABLE recon_sessions IS 'Tracking different reconnaissance campaigns';
COMMENT ON TABLE http_services IS 'HTTP/HTTPS services discovered during active reconnaissance';
COMMENT ON TABLE port_scan_results IS 'Open ports discovered during network scanning';
COMMENT ON TABLE vulnerability_findings IS 'All vulnerability findings from security assessments';
COMMENT ON TABLE screenshots IS 'Screenshot metadata for web service captures';
COMMENT ON TABLE scan_reports IS 'Final scan reports generated in Phase 4';

-- Create a function to update last_seen timestamp
CREATE OR REPLACE FUNCTION update_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_seen = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update last_seen on subdomain updates
CREATE TRIGGER update_subdomain_last_seen
    BEFORE UPDATE ON subdomain_intel
    FOR EACH ROW
    EXECUTE FUNCTION update_last_seen();

-- Create a function to update updated_at timestamp for recon_sessions
CREATE OR REPLACE FUNCTION update_recon_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at on recon_sessions updates
CREATE TRIGGER trigger_update_recon_sessions_updated_at
    BEFORE UPDATE ON recon_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_recon_sessions_updated_at();

-- Grant permissions to recon_user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO recon_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO recon_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO recon_user;

-- Default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO recon_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO recon_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO recon_user;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'n8n Reconnaissance Hub database schema created successfully!';
    RAISE NOTICE 'Tables created: 15';
    RAISE NOTICE '  Core: subdomain_intel, network_scans, vulnerabilities, credentials';
    RAISE NOTICE '  Web: fuzzing_results, web_technologies, nuclei_results, sqli_results';
    RAISE NOTICE '  Sessions: recon_sessions';
    RAISE NOTICE '  Phase 2+: http_services, port_scan_results, vulnerability_findings';
    RAISE NOTICE '  Phase 4: screenshots, scan_reports';
    RAISE NOTICE 'Indexes created: Multiple performance indexes';
    RAISE NOTICE 'Ready for offensive security automation!';
END $$;
