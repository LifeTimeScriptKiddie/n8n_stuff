-- ============================================================================
-- n8n Red Team Reconnaissance Hub - Migration Script v001
-- ============================================================================
-- This migration adds production-ready features for Red Team operations:
-- - Authorization & scope management
-- - Finding deduplication
-- - Checkpoint/resume capability
-- - API rate limiting
-- - Stealth profiles
-- - Attack chain detection
-- - Enhanced data storage
-- ============================================================================

-- Migration tracking
CREATE TABLE IF NOT EXISTS schema_migrations (
    version INTEGER PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- Insert migration record
INSERT INTO schema_migrations (version, description)
VALUES (1, 'Red Team enhancements - scope management, deduplication, checkpoints, stealth')
ON CONFLICT (version) DO NOTHING;

-- ============================================================================
-- 1. SCOPE DEFINITIONS TABLE
-- ============================================================================
-- Stores authorized target scopes for Red Team engagements
CREATE TABLE IF NOT EXISTS scope_definitions (
    id SERIAL PRIMARY KEY,
    scope_name VARCHAR(255) NOT NULL UNIQUE,
    in_scope TEXT[] NOT NULL,                    -- Array of allowed domains/IPs/CIDR
    out_of_scope TEXT[] DEFAULT '{}',            -- Explicitly blocked targets
    max_ports INTEGER DEFAULT 1000,              -- Port scanning limit
    allowed_tools TEXT[] DEFAULT '{}',           -- Whitelisted tools
    stealth_level VARCHAR(20) DEFAULT 'medium',  -- low/medium/high
    max_concurrent_scans INTEGER DEFAULT 3,
    rate_limit_per_sec INTEGER DEFAULT 10,
    require_approval BOOLEAN DEFAULT false,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    authorized_by VARCHAR(255),
    authorization_date TIMESTAMP,
    expiry_date TIMESTAMP                        -- Engagement end date
);

CREATE INDEX idx_scope_name ON scope_definitions(scope_name);
CREATE INDEX idx_scope_expiry ON scope_definitions(expiry_date);

COMMENT ON TABLE scope_definitions IS 'Authorized target scopes for Red Team operations';

-- ============================================================================
-- 2. FINDING HASHES TABLE (Deduplication)
-- ============================================================================
-- Prevents duplicate vulnerability reports
CREATE TABLE IF NOT EXISTS finding_hashes (
    id SERIAL PRIMARY KEY,
    finding_hash CHAR(64) NOT NULL UNIQUE,       -- SHA256 hash
    vuln_type VARCHAR(100) NOT NULL,
    host VARCHAR(255) NOT NULL,
    parameter VARCHAR(255),
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    occurrence_count INTEGER DEFAULT 1,
    related_finding_ids INTEGER[] DEFAULT '{}'   -- Link to vulnerabilities.id
);

CREATE INDEX idx_finding_hash ON finding_hashes(finding_hash);
CREATE INDEX idx_finding_type ON finding_hashes(vuln_type);
CREATE INDEX idx_finding_host ON finding_hashes(host);

COMMENT ON TABLE finding_hashes IS 'Deduplication tracking for vulnerability findings';

-- ============================================================================
-- 3. SCAN CHECKPOINTS TABLE (Resume Capability)
-- ============================================================================
-- Allows resuming interrupted scans
CREATE TABLE IF NOT EXISTS scan_checkpoints (
    id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES recon_sessions(id) ON DELETE CASCADE,
    phase VARCHAR(50) NOT NULL,                  -- e.g., 'subdomain_enum', 'port_scan'
    step_number INTEGER NOT NULL,
    step_name VARCHAR(255),
    data JSONB,                                  -- Checkpoint state data
    status VARCHAR(20) DEFAULT 'pending',        -- pending/in_progress/completed/failed
    checkpoint_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completion_time TIMESTAMP,
    error_message TEXT,
    UNIQUE(session_id, phase, step_number)
);

CREATE INDEX idx_checkpoint_session ON scan_checkpoints(session_id);
CREATE INDEX idx_checkpoint_status ON scan_checkpoints(status);
CREATE INDEX idx_checkpoint_phase ON scan_checkpoints(phase);

COMMENT ON TABLE scan_checkpoints IS 'Checkpoint data for resuming interrupted scans';

-- ============================================================================
-- 4. API RATE LIMITS TABLE
-- ============================================================================
-- Track API usage to prevent rate limiting
CREATE TABLE IF NOT EXISTS api_rate_limits (
    id SERIAL PRIMARY KEY,
    api_name VARCHAR(100) NOT NULL,              -- shodan, censys, virustotal
    api_key_hash CHAR(64),                       -- Hashed API key for tracking
    requests_made INTEGER DEFAULT 0,
    requests_limit INTEGER NOT NULL,
    window_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    window_duration_minutes INTEGER DEFAULT 60,
    last_request_time TIMESTAMP,
    reset_time TIMESTAMP,
    status VARCHAR(20) DEFAULT 'available'       -- available/rate_limited/quota_exceeded
);

CREATE INDEX idx_api_name ON api_rate_limits(api_name);
CREATE INDEX idx_api_status ON api_rate_limits(status);
CREATE INDEX idx_api_reset ON api_rate_limits(reset_time);

COMMENT ON TABLE api_rate_limits IS 'API usage tracking and rate limit management';

-- ============================================================================
-- 5. STEALTH PROFILES TABLE
-- ============================================================================
-- User-agent rotation and timing profiles for stealth operations
CREATE TABLE IF NOT EXISTS stealth_profiles (
    id SERIAL PRIMARY KEY,
    profile_name VARCHAR(100) NOT NULL UNIQUE,
    user_agents TEXT[] NOT NULL,                 -- Array of realistic user-agents
    request_delay_min_ms INTEGER DEFAULT 1000,
    request_delay_max_ms INTEGER DEFAULT 3000,
    requests_per_second INTEGER DEFAULT 5,
    use_random_ordering BOOLEAN DEFAULT true,
    backoff_on_429 BOOLEAN DEFAULT true,
    backoff_multiplier DECIMAL(3,2) DEFAULT 2.0,
    max_retries INTEGER DEFAULT 3,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_stealth_profile_name ON stealth_profiles(profile_name);

COMMENT ON TABLE stealth_profiles IS 'Stealth configuration profiles for red team operations';

-- Insert default stealth profiles
INSERT INTO stealth_profiles (profile_name, user_agents, request_delay_min_ms, request_delay_max_ms, requests_per_second, description)
VALUES
(
    'slow_careful',
    ARRAY[
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    ],
    3000, 7000, 2,
    'Maximum stealth - slow requests, high randomization (2 req/sec)'
),
(
    'medium_balanced',
    ARRAY[
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0'
    ],
    1000, 3000, 10,
    'Balanced approach - moderate stealth and speed (10 req/sec)'
),
(
    'fast_aggressive',
    ARRAY[
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    ],
    100, 500, 50,
    'Fast scanning - minimal delays, higher detection risk (50 req/sec)'
)
ON CONFLICT (profile_name) DO NOTHING;

-- ============================================================================
-- 6. ATTACK CHAINS TABLE
-- ============================================================================
-- Link related vulnerabilities to identify attack paths
CREATE TABLE IF NOT EXISTS attack_chains (
    id SERIAL PRIMARY KEY,
    chain_name VARCHAR(255) NOT NULL,
    finding_ids INTEGER[] NOT NULL,              -- Array of vulnerability IDs
    severity VARCHAR(20),                        -- Combined severity
    cvss_score DECIMAL(3,1),                    -- Combined CVSS score
    attack_path TEXT,                            -- Description of attack chain
    exploitability VARCHAR(20),                  -- low/medium/high/critical
    impact_description TEXT,
    recommended_priority VARCHAR(20),            -- low/medium/high/critical
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    validated BOOLEAN DEFAULT false,
    notes TEXT
);

CREATE INDEX idx_chain_severity ON attack_chains(severity);
CREATE INDEX idx_chain_cvss ON attack_chains(cvss_score);
CREATE INDEX idx_chain_validated ON attack_chains(validated);

COMMENT ON TABLE attack_chains IS 'Linked vulnerabilities forming attack paths';

-- ============================================================================
-- 7. PASSIVE INTEL TABLE (Shodan/Censys/VirusTotal)
-- ============================================================================
-- Store passive reconnaissance data from third-party APIs
CREATE TABLE IF NOT EXISTS passive_intel (
    id SERIAL PRIMARY KEY,
    target VARCHAR(255) NOT NULL,
    source VARCHAR(50) NOT NULL,                 -- shodan/censys/virustotal/etc
    intel_type VARCHAR(50),                      -- open_ports/certificates/malware/passive_dns
    data JSONB NOT NULL,                         -- Full JSON response
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_passive_target ON passive_intel(target);
CREATE INDEX idx_passive_source ON passive_intel(source);
CREATE INDEX idx_passive_type ON passive_intel(intel_type);
CREATE INDEX idx_passive_data ON passive_intel USING gin(data);

COMMENT ON TABLE passive_intel IS 'Passive reconnaissance from Shodan, Censys, VirusTotal APIs';

-- ============================================================================
-- 8. API ENDPOINTS TABLE
-- ============================================================================
-- Store discovered API endpoints from JavaScript analysis
CREATE TABLE IF NOT EXISTS api_endpoints (
    id SERIAL PRIMARY KEY,
    base_url TEXT NOT NULL,
    endpoint TEXT NOT NULL,
    method VARCHAR(10) DEFAULT 'GET',            -- GET/POST/PUT/DELETE/PATCH
    parameters TEXT[],
    headers JSONB,
    source VARCHAR(100),                         -- js_file/swagger/graphql
    source_url TEXT,
    response_status INTEGER,
    requires_auth BOOLEAN,
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_tested TIMESTAMP,
    UNIQUE(base_url, endpoint, method)
);

CREATE INDEX idx_api_base_url ON api_endpoints(base_url);
CREATE INDEX idx_api_method ON api_endpoints(method);
CREATE INDEX idx_api_requires_auth ON api_endpoints(requires_auth);

COMMENT ON TABLE api_endpoints IS 'Discovered API endpoints from JavaScript and documentation';

-- ============================================================================
-- 9. SECURITY HEADERS TABLE
-- ============================================================================
-- Store HTTP security header analysis
CREATE TABLE IF NOT EXISTS security_headers (
    id SERIAL PRIMARY KEY,
    url TEXT NOT NULL UNIQUE,
    has_csp BOOLEAN DEFAULT false,
    csp_policy TEXT,
    has_hsts BOOLEAN DEFAULT false,
    hsts_max_age INTEGER,
    has_x_frame_options BOOLEAN DEFAULT false,
    x_frame_options VARCHAR(50),
    has_x_content_type_options BOOLEAN DEFAULT false,
    has_x_xss_protection BOOLEAN DEFAULT false,
    cors_policy TEXT,
    referrer_policy VARCHAR(100),
    permissions_policy TEXT,
    missing_headers TEXT[],                      -- Array of missing security headers
    security_score INTEGER,                      -- 0-100 score
    risk_level VARCHAR(20),                      -- low/medium/high/critical
    recommendations TEXT,
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_headers_url ON security_headers(url);
CREATE INDEX idx_headers_score ON security_headers(security_score);
CREATE INDEX idx_headers_risk ON security_headers(risk_level);

COMMENT ON TABLE security_headers IS 'HTTP security header analysis results';

-- ============================================================================
-- 10. SSL/TLS RESULTS TABLE
-- ============================================================================
-- Store SSL/TLS testing results from testssl.sh
CREATE TABLE IF NOT EXISTS ssl_results (
    id SERIAL PRIMARY KEY,
    target VARCHAR(255) NOT NULL,
    port INTEGER DEFAULT 443,
    ssl_version VARCHAR(50),
    tls_version VARCHAR(50),
    cipher_suites TEXT[],
    weak_ciphers TEXT[],
    certificate_valid BOOLEAN,
    certificate_expiry DATE,
    certificate_issuer TEXT,
    certificate_subject TEXT,
    certificate_chain TEXT[],
    supports_forward_secrecy BOOLEAN,
    vulnerable_to_heartbleed BOOLEAN DEFAULT false,
    vulnerable_to_poodle BOOLEAN DEFAULT false,
    vulnerable_to_beast BOOLEAN DEFAULT false,
    grade VARCHAR(2),                            -- A+, A, B, C, D, F
    findings TEXT,
    recommendations TEXT,
    tested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(target, port)
);

CREATE INDEX idx_ssl_target ON ssl_results(target);
CREATE INDEX idx_ssl_grade ON ssl_results(grade);
CREATE INDEX idx_ssl_expiry ON ssl_results(certificate_expiry);

COMMENT ON TABLE ssl_results IS 'SSL/TLS security testing results';

-- ============================================================================
-- 11. SCAN ERRORS TABLE
-- ============================================================================
-- Log errors and failures for debugging
CREATE TABLE IF NOT EXISTS scan_errors (
    id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES recon_sessions(id) ON DELETE CASCADE,
    phase VARCHAR(50),
    tool_name VARCHAR(100),
    error_type VARCHAR(100),
    error_message TEXT,
    command_executed TEXT,
    exit_code INTEGER,
    retry_count INTEGER DEFAULT 0,
    resolved BOOLEAN DEFAULT false,
    occurred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_error_session ON scan_errors(session_id);
CREATE INDEX idx_error_tool ON scan_errors(tool_name);
CREATE INDEX idx_error_resolved ON scan_errors(resolved);
CREATE INDEX idx_error_time ON scan_errors(occurred_at);

COMMENT ON TABLE scan_errors IS 'Error logging for debugging and monitoring';

-- ============================================================================
-- ENHANCED RECON_SESSIONS TABLE
-- ============================================================================
-- Add new columns to existing table
ALTER TABLE recon_sessions
    ADD COLUMN IF NOT EXISTS scope_id INTEGER REFERENCES scope_definitions(id),
    ADD COLUMN IF NOT EXISTS stealth_profile_id INTEGER REFERENCES stealth_profiles(id),
    ADD COLUMN IF NOT EXISTS total_findings INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS critical_findings INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS high_findings INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS medium_findings INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS low_findings INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS scan_progress DECIMAL(5,2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS resumed_from_checkpoint BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS error_count INTEGER DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_session_scope ON recon_sessions(scope_id);
CREATE INDEX IF NOT EXISTS idx_session_stealth ON recon_sessions(stealth_profile_id);

-- ============================================================================
-- UPDATE EXISTING TABLES
-- ============================================================================

-- Add finding_hash to vulnerabilities table
ALTER TABLE vulnerabilities
    ADD COLUMN IF NOT EXISTS finding_hash CHAR(64),
    ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'new',
    ADD COLUMN IF NOT EXISTS validated BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS false_positive BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS proof_of_concept TEXT,
    ADD COLUMN IF NOT EXISTS attack_chain_id INTEGER REFERENCES attack_chains(id);

CREATE INDEX IF NOT EXISTS idx_vuln_hash ON vulnerabilities(finding_hash);
CREATE INDEX IF NOT EXISTS idx_vuln_status ON vulnerabilities(status);

-- Add session tracking to other tables
ALTER TABLE subdomain_intel ADD COLUMN IF NOT EXISTS session_id INTEGER REFERENCES recon_sessions(id);
ALTER TABLE network_scans ADD COLUMN IF NOT EXISTS session_id INTEGER REFERENCES recon_sessions(id);
ALTER TABLE nuclei_results ADD COLUMN IF NOT EXISTS session_id INTEGER REFERENCES recon_sessions(id);

CREATE INDEX IF NOT EXISTS idx_subdomain_session ON subdomain_intel(session_id);
CREATE INDEX IF NOT EXISTS idx_network_session ON network_scans(session_id);
CREATE INDEX IF NOT EXISTS idx_nuclei_session ON nuclei_results(session_id);

-- ============================================================================
-- TRIGGERS FOR AUTO-UPDATING
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for scope_definitions
CREATE TRIGGER update_scope_updated_at
    BEFORE UPDATE ON scope_definitions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to increment occurrence count and update last_seen
CREATE OR REPLACE FUNCTION increment_finding_occurrence()
RETURNS TRIGGER AS $$
BEGIN
    NEW.occurrence_count = OLD.occurrence_count + 1;
    NEW.last_seen = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for finding_hashes
CREATE TRIGGER update_finding_occurrence
    BEFORE UPDATE ON finding_hashes
    FOR EACH ROW
    EXECUTE FUNCTION increment_finding_occurrence();

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Function to calculate finding hash
CREATE OR REPLACE FUNCTION calculate_finding_hash(
    vuln_type TEXT,
    host TEXT,
    parameter TEXT DEFAULT ''
) RETURNS TEXT AS $$
BEGIN
    RETURN encode(
        digest(
            CONCAT(LOWER(vuln_type), '|', LOWER(host), '|', LOWER(COALESCE(parameter, ''))),
            'sha256'
        ),
        'hex'
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to check if target is in scope
CREATE OR REPLACE FUNCTION is_target_in_scope(
    target_host TEXT,
    scope_id_param INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    in_scope_patterns TEXT[];
    out_of_scope_patterns TEXT[];
    pattern TEXT;
BEGIN
    -- Get scope patterns
    SELECT in_scope, out_of_scope INTO in_scope_patterns, out_of_scope_patterns
    FROM scope_definitions
    WHERE id = scope_id_param;

    -- Check if in out_of_scope list first
    FOREACH pattern IN ARRAY out_of_scope_patterns
    LOOP
        IF target_host ~ pattern THEN
            RETURN false;
        END IF;
    END LOOP;

    -- Check if in in_scope list
    FOREACH pattern IN ARRAY in_scope_patterns
    LOOP
        IF target_host ~ pattern THEN
            RETURN true;
        END IF;
    END LOOP;

    -- Not found in scope
    RETURN false;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO recon_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO recon_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO recon_user;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Migration 001 - Red Team Enhancements: COMPLETED';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Total tables in database: %', table_count;
    RAISE NOTICE 'New tables added: 11';
    RAISE NOTICE '  - scope_definitions (authorization management)';
    RAISE NOTICE '  - finding_hashes (deduplication)';
    RAISE NOTICE '  - scan_checkpoints (resume capability)';
    RAISE NOTICE '  - api_rate_limits (API tracking)';
    RAISE NOTICE '  - stealth_profiles (OpSec configurations)';
    RAISE NOTICE '  - attack_chains (vulnerability linking)';
    RAISE NOTICE '  - passive_intel (Shodan/Censys/VT data)';
    RAISE NOTICE '  - api_endpoints (discovered APIs)';
    RAISE NOTICE '  - security_headers (header analysis)';
    RAISE NOTICE '  - ssl_results (TLS testing)';
    RAISE NOTICE '  - scan_errors (error logging)';
    RAISE NOTICE 'Enhanced tables: 4 (recon_sessions, vulnerabilities, subdomain_intel, network_scans)';
    RAISE NOTICE 'Utility functions: 3';
    RAISE NOTICE 'Stealth profiles created: 3 (slow_careful, medium_balanced, fast_aggressive)';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Ready for Production Red Team Operations!';
    RAISE NOTICE '============================================================';
END $$;
