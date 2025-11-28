-- ============================================================================
-- Phase D: SSH Tunneling & Pivot Capability
-- ============================================================================
-- Adds:
-- - SSH tunnel management
-- - Pivot tracking and orchestration
-- - Multi-hop support (max 4 hops)
-- ============================================================================

-- ============================================================================
-- SSH TUNNELS TABLE (Active tunnel management)
-- ============================================================================
CREATE TABLE IF NOT EXISTS ssh_tunnels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

    -- Source (where tunnel originates)
    source_host_id UUID REFERENCES hosts(id) ON DELETE SET NULL,
    source_tunnel_id UUID REFERENCES ssh_tunnels(id) ON DELETE CASCADE, -- For multi-hop

    -- Target (where tunnel connects to)
    target_host_id UUID NOT NULL REFERENCES hosts(id) ON DELETE CASCADE,
    credential_id UUID NOT NULL REFERENCES secure_credentials(id) ON DELETE CASCADE,

    -- Tunnel configuration
    tunnel_type VARCHAR(20) DEFAULT 'socks',  -- socks, local, dynamic
    local_port INTEGER NOT NULL,              -- Local SOCKS/forward port
    remote_bind VARCHAR(255),                 -- For local forwards: host:port

    -- Hop tracking
    hop_level INTEGER DEFAULT 1,              -- 1 = direct, 2+ = through other tunnels
    hop_path UUID[] DEFAULT '{}',             -- Array of tunnel IDs in chain

    -- Status
    status VARCHAR(20) DEFAULT 'pending',     -- pending, establishing, active, failed, closed
    pid INTEGER,                              -- SSH process ID
    error_message TEXT,

    -- Health
    last_health_check TIMESTAMP,
    health_status VARCHAR(20) DEFAULT 'unknown', -- healthy, degraded, failed
    bytes_transferred BIGINT DEFAULT 0,

    -- Lifecycle
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    established_at TIMESTAMP,
    expires_at TIMESTAMP,                     -- NULL = until project ends
    closed_at TIMESTAMP,
    closed_reason VARCHAR(100)
);

CREATE INDEX idx_tunnels_project ON ssh_tunnels(project_id);
CREATE INDEX idx_tunnels_status ON ssh_tunnels(status);
CREATE INDEX idx_tunnels_target ON ssh_tunnels(target_host_id);
CREATE INDEX idx_tunnels_hop ON ssh_tunnels(hop_level);
CREATE INDEX idx_tunnels_port ON ssh_tunnels(local_port);

-- ============================================================================
-- PIVOT QUEUE TABLE (Pending pivot operations)
-- ============================================================================
CREATE TABLE IF NOT EXISTS pivot_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

    -- Pivot details
    source_host_id UUID REFERENCES hosts(id),
    target_host_id UUID NOT NULL REFERENCES hosts(id),
    credential_id UUID NOT NULL REFERENCES secure_credentials(id),

    -- Configuration
    pivot_type VARCHAR(50) DEFAULT 'full_recon',  -- full_recon, port_scan, service_enum
    hop_level INTEGER DEFAULT 1,
    parent_tunnel_id UUID REFERENCES ssh_tunnels(id),

    -- Status
    status VARCHAR(20) DEFAULT 'queued',  -- queued, processing, completed, failed
    priority INTEGER DEFAULT 5,

    -- Results
    tunnel_id UUID REFERENCES ssh_tunnels(id),
    scan_job_id UUID REFERENCES scan_jobs(id),
    discovered_hosts INTEGER DEFAULT 0,
    discovered_ports INTEGER DEFAULT 0,
    error_message TEXT,

    -- Timestamps
    queued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE INDEX idx_pivot_queue_project ON pivot_queue(project_id);
CREATE INDEX idx_pivot_queue_status ON pivot_queue(status);
CREATE INDEX idx_pivot_queue_hop ON pivot_queue(hop_level);

-- ============================================================================
-- INTERNAL NETWORKS TABLE (Discovered internal network ranges)
-- ============================================================================
CREATE TABLE IF NOT EXISTS internal_networks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

    -- Network details
    cidr CIDR NOT NULL,
    name VARCHAR(255),
    description TEXT,

    -- Discovery
    discovered_via_host_id UUID REFERENCES hosts(id),
    discovered_via_tunnel_id UUID REFERENCES ssh_tunnels(id),
    discovery_method VARCHAR(50),  -- arp_scan, route_table, config_file

    -- Scanning status
    scan_status VARCHAR(20) DEFAULT 'pending',  -- pending, scanning, completed
    last_scanned TIMESTAMP,
    host_count INTEGER DEFAULT 0,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_internal_nets_project ON internal_networks(project_id);
CREATE INDEX idx_internal_nets_cidr ON internal_networks(cidr);

-- ============================================================================
-- PROXY CHAINS CONFIG (Dynamic proxy configuration)
-- ============================================================================
CREATE TABLE IF NOT EXISTS proxy_chains (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

    -- Chain details
    name VARCHAR(255),
    tunnel_chain UUID[] NOT NULL,  -- Ordered array of tunnel IDs
    final_target_network CIDR,

    -- Status
    status VARCHAR(20) DEFAULT 'active',

    -- Generated config
    proxychains_config TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_proxy_chains_project ON proxy_chains(project_id);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: Active tunnels with hop info
CREATE OR REPLACE VIEW active_tunnels AS
SELECT
    t.id,
    t.project_id,
    t.hop_level,
    t.local_port,
    t.status,
    t.health_status,
    sh.ip_address as source_ip,
    th.ip_address as target_ip,
    th.hostname as target_hostname,
    sc.username,
    t.established_at,
    t.bytes_transferred,
    array_length(t.hop_path, 1) as hops_in_chain
FROM ssh_tunnels t
LEFT JOIN hosts sh ON sh.id = t.source_host_id
JOIN hosts th ON th.id = t.target_host_id
JOIN secure_credentials sc ON sc.id = t.credential_id
WHERE t.status = 'active'
ORDER BY t.hop_level, t.established_at;

-- View: Pivot paths visualization
CREATE OR REPLACE VIEW pivot_graph AS
WITH RECURSIVE pivot_chain AS (
    -- Base: direct tunnels (hop 1)
    SELECT
        t.id,
        t.project_id,
        t.target_host_id,
        t.hop_level,
        ARRAY[t.target_host_id] as path,
        1 as depth
    FROM ssh_tunnels t
    WHERE t.hop_level = 1 AND t.status = 'active'

    UNION ALL

    -- Recursive: tunnels through other tunnels
    SELECT
        t.id,
        t.project_id,
        t.target_host_id,
        t.hop_level,
        pc.path || t.target_host_id,
        pc.depth + 1
    FROM ssh_tunnels t
    JOIN pivot_chain pc ON t.source_tunnel_id = (
        SELECT id FROM ssh_tunnels WHERE target_host_id = pc.target_host_id LIMIT 1
    )
    WHERE t.status = 'active' AND pc.depth < 4
)
SELECT * FROM pivot_chain;

-- View: Tunnel health summary
CREATE OR REPLACE VIEW tunnel_health_summary AS
SELECT
    project_id,
    COUNT(*) FILTER (WHERE status = 'active') as active_tunnels,
    COUNT(*) FILTER (WHERE health_status = 'healthy') as healthy,
    COUNT(*) FILTER (WHERE health_status = 'degraded') as degraded,
    COUNT(*) FILTER (WHERE health_status = 'failed') as failed,
    MAX(hop_level) as max_hop_depth,
    SUM(bytes_transferred) as total_bytes
FROM ssh_tunnels
WHERE status = 'active'
GROUP BY project_id;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to get next available local port for tunnel
CREATE OR REPLACE FUNCTION get_next_tunnel_port(p_project_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_port INTEGER;
BEGIN
    -- Start from 10000, find first unused port
    SELECT COALESCE(MAX(local_port), 9999) + 1 INTO v_port
    FROM ssh_tunnels
    WHERE project_id = p_project_id
    AND status IN ('pending', 'establishing', 'active');

    -- Ensure within valid range
    IF v_port > 65000 THEN
        v_port := 10000;
    END IF;

    RETURN v_port;
END;
$$ LANGUAGE plpgsql;

-- Function to check if pivot is allowed (hop limit, ROE)
CREATE OR REPLACE FUNCTION can_pivot(
    p_project_id UUID,
    p_target_host_id UUID,
    p_current_hop INTEGER
) RETURNS JSONB AS $$
DECLARE
    v_settings JSONB;
    v_max_hops INTEGER;
    v_result JSONB;
BEGIN
    -- Get project settings
    SELECT settings INTO v_settings
    FROM projects WHERE id = p_project_id;

    -- Check hop limit (default 4)
    v_max_hops := COALESCE((v_settings->>'max_pivot_hops')::integer, 4);

    IF p_current_hop >= v_max_hops THEN
        RETURN jsonb_build_object(
            'allowed', false,
            'reason', format('Max hop limit reached (%s/%s)', p_current_hop, v_max_hops)
        );
    END IF;

    -- Check if already have active tunnel to this host
    IF EXISTS (
        SELECT 1 FROM ssh_tunnels
        WHERE project_id = p_project_id
        AND target_host_id = p_target_host_id
        AND status = 'active'
    ) THEN
        RETURN jsonb_build_object(
            'allowed', false,
            'reason', 'Active tunnel already exists to this host'
        );
    END IF;

    RETURN jsonb_build_object(
        'allowed', true,
        'max_hops', v_max_hops,
        'current_hop', p_current_hop
    );
END;
$$ LANGUAGE plpgsql;

-- Function to generate proxychains config for a tunnel chain
CREATE OR REPLACE FUNCTION generate_proxychains_config(p_tunnel_ids UUID[])
RETURNS TEXT AS $$
DECLARE
    v_config TEXT;
    v_tunnel RECORD;
BEGIN
    v_config := E'# ProxyChains configuration\n';
    v_config := v_config || E'strict_chain\n';
    v_config := v_config || E'proxy_dns\n';
    v_config := v_config || E'tcp_read_time_out 15000\n';
    v_config := v_config || E'tcp_connect_time_out 8000\n\n';
    v_config := v_config || E'[ProxyList]\n';

    FOR v_tunnel IN
        SELECT t.local_port, t.tunnel_type
        FROM ssh_tunnels t
        WHERE t.id = ANY(p_tunnel_ids)
        ORDER BY array_position(p_tunnel_ids, t.id)
    LOOP
        IF v_tunnel.tunnel_type = 'socks' THEN
            v_config := v_config || format('socks5 127.0.0.1 %s', v_tunnel.local_port) || E'\n';
        END IF;
    END LOOP;

    RETURN v_config;
END;
$$ LANGUAGE plpgsql;

-- Function to close all tunnels for a project
CREATE OR REPLACE FUNCTION close_project_tunnels(p_project_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE ssh_tunnels
    SET status = 'closed',
        closed_at = NOW(),
        closed_reason = 'project_cleanup'
    WHERE project_id = p_project_id
    AND status = 'active';

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to update proxy chains when tunnels change
CREATE OR REPLACE FUNCTION update_proxy_chains_on_tunnel_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Mark affected proxy chains for regeneration
    UPDATE proxy_chains
    SET updated_at = NOW()
    WHERE NEW.id = ANY(tunnel_chain);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_tunnel_change
    AFTER UPDATE OF status ON ssh_tunnels
    FOR EACH ROW
    EXECUTE FUNCTION update_proxy_chains_on_tunnel_change();

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
    RAISE NOTICE 'Phase D Pivoting Migration completed!';
    RAISE NOTICE 'New tables: ssh_tunnels, pivot_queue, internal_networks, proxy_chains';
    RAISE NOTICE 'New views: active_tunnels, pivot_graph, tunnel_health_summary';
    RAISE NOTICE 'New functions: get_next_tunnel_port, can_pivot, generate_proxychains_config, close_project_tunnels';
END $$;
