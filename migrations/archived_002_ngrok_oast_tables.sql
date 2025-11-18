-- ============================================================================
-- n8n Reconnaissance Hub - Ngrok OAST Database Migration
-- ============================================================================
-- Migration: 002_ngrok_oast_tables
-- Purpose: Add tables for Out-of-Band Application Security Testing (OAST)
-- Date: 2025-11-02
-- Dependencies: 001_red_team_enhancements.sql
-- ============================================================================

-- ============================================================================
-- OAST Interactions Table
-- ============================================================================
-- Stores HTTP callbacks received via ngrok tunnel for blind vulnerability detection
-- Use cases: Blind SSRF, Blind XSS, Blind XXE, DNS exfiltration, Log4Shell callbacks

CREATE TABLE IF NOT EXISTS oast_interactions (
    id SERIAL PRIMARY KEY,

    -- Link to reconnaissance session
    session_id INTEGER REFERENCES recon_sessions(id) ON DELETE CASCADE,

    -- Callback details
    callback_url TEXT NOT NULL,
    source_ip INET NOT NULL,
    user_agent TEXT,

    -- Request data
    method VARCHAR(10) DEFAULT 'GET',
    path TEXT,
    query_params JSONB,
    headers JSONB NOT NULL,
    body TEXT,

    -- Response data (what we sent back)
    response_status INTEGER DEFAULT 200,
    response_body TEXT,

    -- Classification
    interaction_type VARCHAR(50) NOT NULL,  -- ssrf, xss, xxe, dns, log4j, etc.
    vulnerability_confirmed BOOLEAN DEFAULT false,
    severity VARCHAR(20),  -- info, low, medium, high, critical

    -- Metadata
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    tags TEXT[],

    -- Foreign key to associated finding (if confirmed as vulnerability)
    finding_id INTEGER REFERENCES vulnerability_findings(id) ON DELETE SET NULL
);

-- Indexes for performance
CREATE INDEX idx_oast_session ON oast_interactions(session_id);
CREATE INDEX idx_oast_source_ip ON oast_interactions(source_ip);
CREATE INDEX idx_oast_type ON oast_interactions(interaction_type);
CREATE INDEX idx_oast_detected ON oast_interactions(detected_at);
CREATE INDEX idx_oast_confirmed ON oast_interactions(vulnerability_confirmed);

-- ============================================================================
-- OAST Payloads Table
-- ============================================================================
-- Tracks OAST payloads injected during scanning for correlation with callbacks

CREATE TABLE IF NOT EXISTS oast_payloads (
    id SERIAL PRIMARY KEY,

    -- Link to session and interaction
    session_id INTEGER REFERENCES recon_sessions(id) ON DELETE CASCADE,
    interaction_id INTEGER REFERENCES oast_interactions(id) ON DELETE SET NULL,

    -- Payload details
    payload_type VARCHAR(50) NOT NULL,  -- ssrf, xss, xxe, etc.
    payload_content TEXT NOT NULL,
    callback_identifier UUID NOT NULL UNIQUE,  -- Unique ID embedded in payload

    -- Target information
    target_url TEXT NOT NULL,
    target_parameter VARCHAR(255),  -- Which param/header was tested
    injection_point VARCHAR(100),   -- url, header, body, cookie, etc.

    -- Tool that injected the payload
    tool_name VARCHAR(50),  -- nuclei, ffuf, custom, etc.

    -- Status
    callback_received BOOLEAN DEFAULT false,
    callbacks_count INTEGER DEFAULT 0,

    -- Timestamps
    injected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    first_callback_at TIMESTAMP,
    last_callback_at TIMESTAMP,

    -- Time to callback (for blind vuln timing analysis)
    callback_latency_seconds INTEGER
);

-- Indexes
CREATE INDEX idx_oast_payload_session ON oast_payloads(session_id);
CREATE INDEX idx_oast_payload_identifier ON oast_payloads(callback_identifier);
CREATE INDEX idx_oast_payload_target ON oast_payloads(target_url);
CREATE INDEX idx_oast_payload_received ON oast_payloads(callback_received);

-- ============================================================================
-- Ngrok Tunnel Status Table
-- ============================================================================
-- Tracks ngrok tunnel health and usage metrics

CREATE TABLE IF NOT EXISTS ngrok_tunnel_status (
    id SERIAL PRIMARY KEY,

    -- Tunnel information
    tunnel_id VARCHAR(255),  -- Ngrok tunnel ID
    public_url TEXT NOT NULL,
    tunnel_protocol VARCHAR(10) DEFAULT 'https',

    -- Status
    status VARCHAR(20) NOT NULL,  -- active, inactive, error
    is_static_subdomain BOOLEAN DEFAULT false,

    -- Metrics
    connections_count INTEGER DEFAULT 0,
    bytes_sent BIGINT DEFAULT 0,
    bytes_received BIGINT DEFAULT 0,

    -- Session association
    active_session_ids INTEGER[],  -- Array of session IDs using this tunnel

    -- Timestamps
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    stopped_at TIMESTAMP,
    last_health_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Errors/Warnings
    error_message TEXT,
    warning_count INTEGER DEFAULT 0
);

-- Indexes
CREATE INDEX idx_ngrok_status ON ngrok_tunnel_status(status);
CREATE INDEX idx_ngrok_started ON ngrok_tunnel_status(started_at);

-- ============================================================================
-- Webhook Security Events Table
-- ============================================================================
-- Logs security events from webhook callbacks (failed auth, suspicious activity)

CREATE TABLE IF NOT EXISTS webhook_security_events (
    id SERIAL PRIMARY KEY,

    -- Event details
    event_type VARCHAR(50) NOT NULL,  -- auth_failure, rate_limit, suspicious_payload, etc.
    severity VARCHAR(20) NOT NULL,    -- info, warning, critical

    -- Request details
    source_ip INET NOT NULL,
    user_agent TEXT,
    request_path TEXT,
    request_method VARCHAR(10),

    -- Security context
    token_provided BOOLEAN,
    token_valid BOOLEAN,
    rate_limit_exceeded BOOLEAN DEFAULT false,
    suspicious_patterns TEXT[],

    -- Request data (for forensics)
    headers JSONB,
    payload_sample TEXT,  -- First 500 chars

    -- Response
    blocked BOOLEAN DEFAULT false,
    response_code INTEGER,

    -- Timestamps
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Actions taken
    action_taken VARCHAR(100),  -- blocked, rate_limited, logged_only, alerted
    notes TEXT
);

-- Indexes
CREATE INDEX idx_webhook_security_ip ON webhook_security_events(source_ip);
CREATE INDEX idx_webhook_security_type ON webhook_security_events(event_type);
CREATE INDEX idx_webhook_security_severity ON webhook_security_events(severity);
CREATE INDEX idx_webhook_security_detected ON webhook_security_events(detected_at);
CREATE INDEX idx_webhook_security_blocked ON webhook_security_events(blocked);

-- ============================================================================
-- Enhanced Vulnerability Findings Table
-- ============================================================================
-- Add OAST-specific columns to existing vulnerability_findings table

-- Check if vulnerability_findings table exists before altering
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'vulnerability_findings'
    ) THEN
        -- Add OAST-related columns if they don't exist
        ALTER TABLE vulnerability_findings
            ADD COLUMN IF NOT EXISTS is_oast_detected BOOLEAN DEFAULT false,
            ADD COLUMN IF NOT EXISTS oast_interaction_id INTEGER REFERENCES oast_interactions(id),
            ADD COLUMN IF NOT EXISTS blind_vulnerability BOOLEAN DEFAULT false,
            ADD COLUMN IF NOT EXISTS callback_latency_seconds INTEGER;

        -- Add index for OAST findings
        CREATE INDEX IF NOT EXISTS idx_vuln_oast ON vulnerability_findings(is_oast_detected);
    END IF;
END $$;

-- ============================================================================
-- Views for OAST Analysis
-- ============================================================================

-- View: Active OAST Sessions
CREATE OR REPLACE VIEW active_oast_sessions AS
SELECT
    rs.id AS session_id,
    rs.target,
    rs.status,
    rs.created_at,
    COUNT(DISTINCT op.id) AS payloads_injected,
    COUNT(DISTINCT oi.id) AS callbacks_received,
    COUNT(DISTINCT CASE WHEN oi.vulnerability_confirmed THEN oi.id END) AS confirmed_vulns,
    MAX(oi.detected_at) AS last_callback
FROM recon_sessions rs
LEFT JOIN oast_payloads op ON op.session_id = rs.id
LEFT JOIN oast_interactions oi ON oi.session_id = rs.id
WHERE rs.status IN ('running', 'active')
GROUP BY rs.id, rs.target, rs.status, rs.created_at
ORDER BY rs.created_at DESC;

-- View: OAST Detection Summary
CREATE OR REPLACE VIEW oast_detection_summary AS
SELECT
    oi.interaction_type,
    oi.severity,
    COUNT(*) AS total_callbacks,
    COUNT(DISTINCT oi.session_id) AS affected_sessions,
    COUNT(DISTINCT oi.source_ip) AS unique_sources,
    COUNT(CASE WHEN oi.vulnerability_confirmed THEN 1 END) AS confirmed_count,
    MIN(oi.detected_at) AS first_detected,
    MAX(oi.detected_at) AS last_detected
FROM oast_interactions oi
GROUP BY oi.interaction_type, oi.severity
ORDER BY confirmed_count DESC, total_callbacks DESC;

-- View: Security Events Dashboard
CREATE OR REPLACE VIEW security_events_dashboard AS
SELECT
    DATE(detected_at) AS event_date,
    event_type,
    severity,
    COUNT(*) AS event_count,
    COUNT(DISTINCT source_ip) AS unique_ips,
    COUNT(CASE WHEN blocked THEN 1 END) AS blocked_count,
    AVG(CASE WHEN rate_limit_exceeded THEN 1 ELSE 0 END)::numeric(3,2) AS rate_limit_ratio
FROM webhook_security_events
WHERE detected_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(detected_at), event_type, severity
ORDER BY event_date DESC, event_count DESC;

-- ============================================================================
-- Utility Functions
-- ============================================================================

-- Function: Log OAST Interaction
CREATE OR REPLACE FUNCTION log_oast_interaction(
    p_session_id INTEGER,
    p_callback_url TEXT,
    p_source_ip INET,
    p_headers JSONB,
    p_interaction_type VARCHAR(50),
    p_payload JSONB DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_interaction_id INTEGER;
BEGIN
    INSERT INTO oast_interactions (
        session_id,
        callback_url,
        source_ip,
        headers,
        interaction_type,
        query_params
    ) VALUES (
        p_session_id,
        p_callback_url,
        p_source_ip,
        p_headers,
        p_interaction_type,
        p_payload
    ) RETURNING id INTO v_interaction_id;

    -- Update payload callback status if correlation exists
    UPDATE oast_payloads
    SET callback_received = true,
        callbacks_count = callbacks_count + 1,
        first_callback_at = COALESCE(first_callback_at, NOW()),
        last_callback_at = NOW()
    WHERE session_id = p_session_id
    AND callback_received = false;

    RETURN v_interaction_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Calculate OAST Success Rate
CREATE OR REPLACE FUNCTION calculate_oast_success_rate(p_session_id INTEGER)
RETURNS NUMERIC(5,2) AS $$
DECLARE
    v_total_payloads INTEGER;
    v_successful_callbacks INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_total_payloads
    FROM oast_payloads
    WHERE session_id = p_session_id;

    IF v_total_payloads = 0 THEN
        RETURN 0.00;
    END IF;

    SELECT COUNT(*) INTO v_successful_callbacks
    FROM oast_payloads
    WHERE session_id = p_session_id
    AND callback_received = true;

    RETURN (v_successful_callbacks::NUMERIC / v_total_payloads::NUMERIC * 100.0)::NUMERIC(5,2);
END;
$$ LANGUAGE plpgsql;

-- Function: Get Active Tunnel URL
CREATE OR REPLACE FUNCTION get_active_tunnel_url()
RETURNS TEXT AS $$
DECLARE
    v_url TEXT;
BEGIN
    SELECT public_url INTO v_url
    FROM ngrok_tunnel_status
    WHERE status = 'active'
    ORDER BY started_at DESC
    LIMIT 1;

    RETURN v_url;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Sample Data for Testing (Comment out for production)
-- ============================================================================

-- Uncomment below for development/testing

/*
-- Insert sample OAST interaction
INSERT INTO oast_interactions (
    session_id,
    callback_url,
    source_ip,
    headers,
    interaction_type,
    vulnerability_confirmed,
    severity
) VALUES (
    1,  -- Assumes session 1 exists
    'https://example.ngrok.io/webhook/oast-callback?id=test123',
    '192.168.1.100',
    '{"User-Agent": "Mozilla/5.0", "X-Callback-Token": "secret123"}',
    'ssrf',
    true,
    'high'
);

-- Insert sample payload
INSERT INTO oast_payloads (
    session_id,
    payload_type,
    payload_content,
    callback_identifier,
    target_url,
    target_parameter,
    tool_name,
    callback_received
) VALUES (
    1,
    'ssrf',
    'http://example.ngrok.io/callback?id=uuid-1234',
    'uuid-1234',
    'https://target.com/api/fetch',
    'url',
    'nuclei',
    true
);
*/

-- ============================================================================
-- Migration Completion
-- ============================================================================

-- Add migration tracking
CREATE TABLE IF NOT EXISTS migration_history (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(255) UNIQUE NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

INSERT INTO migration_history (migration_name, description)
VALUES (
    '002_ngrok_oast_tables',
    'Added OAST interaction tracking, payload correlation, ngrok tunnel status, and webhook security event logging for bug bounty hunting operations'
) ON CONFLICT (migration_name) DO NOTHING;

-- ============================================================================
-- Post-Migration Verification
-- ============================================================================

-- Verify all tables were created
DO $$
DECLARE
    missing_tables TEXT[];
BEGIN
    SELECT ARRAY_AGG(table_name)
    INTO missing_tables
    FROM (
        VALUES
            ('oast_interactions'),
            ('oast_payloads'),
            ('ngrok_tunnel_status'),
            ('webhook_security_events'),
            ('migration_history')
    ) AS expected(table_name)
    WHERE NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = expected.table_name
    );

    IF missing_tables IS NOT NULL THEN
        RAISE EXCEPTION 'Migration incomplete! Missing tables: %', missing_tables;
    ELSE
        RAISE NOTICE 'Migration 002_ngrok_oast_tables completed successfully';
        RAISE NOTICE 'Created tables: oast_interactions, oast_payloads, ngrok_tunnel_status, webhook_security_events';
        RAISE NOTICE 'Created views: active_oast_sessions, oast_detection_summary, security_events_dashboard';
        RAISE NOTICE 'Created functions: log_oast_interaction, calculate_oast_success_rate, get_active_tunnel_url';
    END IF;
END $$;

-- ============================================================================
-- Usage Examples
-- ============================================================================

/*
-- Query recent OAST interactions
SELECT
    oi.id,
    oi.interaction_type,
    oi.source_ip,
    oi.callback_url,
    oi.vulnerability_confirmed,
    oi.detected_at
FROM oast_interactions oi
ORDER BY oi.detected_at DESC
LIMIT 10;

-- Get OAST success rate for a session
SELECT calculate_oast_success_rate(1);  -- Replace 1 with actual session_id

-- View active OAST sessions
SELECT * FROM active_oast_sessions;

-- Check security events
SELECT * FROM security_events_dashboard
WHERE event_date > CURRENT_DATE - INTERVAL '7 days';

-- Get current tunnel URL
SELECT get_active_tunnel_url();

-- Find confirmed blind vulnerabilities
SELECT
    vf.id,
    vf.target,
    vf.vulnerability_name,
    vf.severity,
    oi.interaction_type,
    oi.source_ip,
    oi.detected_at
FROM vulnerability_findings vf
JOIN oast_interactions oi ON oi.id = vf.oast_interaction_id
WHERE vf.is_oast_detected = true
AND vf.blind_vulnerability = true
ORDER BY vf.discovered_at DESC;
*/

-- ============================================================================
-- End of Migration
-- ============================================================================
