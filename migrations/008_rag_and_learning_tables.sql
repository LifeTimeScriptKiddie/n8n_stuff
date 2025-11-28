-- ============================================================================
-- Migration 008: RAG and Self-Learning Tables
-- ============================================================================
-- Purpose: Add vector embeddings, learning metrics, and agent decision tracking
-- for autonomous pentesting with self-improvement capabilities
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. KNOWLEDGE VECTORS TABLE
-- ============================================================================
-- Stores vector embeddings for RAG (Retrieval-Augmented Generation)
-- Links to source records in other tables for provenance tracking

CREATE TABLE IF NOT EXISTS knowledge_vectors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,

    -- Source tracking
    source_table VARCHAR(50) NOT NULL, -- 'findings', 'scan_jobs', 'credential_usage', etc.
    source_id UUID NOT NULL, -- Foreign key to source table (not enforced due to polymorphic nature)
    source_type VARCHAR(50), -- 'vulnerability', 'scan_result', 'attack_pattern', 'tool_output'

    -- Content
    content_text TEXT NOT NULL, -- Original text that was embedded
    content_summary TEXT, -- Optional AI-generated summary

    -- Chroma vector DB reference
    chroma_id VARCHAR(255) UNIQUE NOT NULL, -- ID in Chroma database
    chroma_collection VARCHAR(100) DEFAULT 'pentest_knowledge',
    embedding_model VARCHAR(50) DEFAULT 'nomic-embed-text', -- Model used for embedding
    embedding_dimension INTEGER DEFAULT 768,

    -- Metadata for filtering and search
    metadata JSONB DEFAULT '{}', -- Flexible metadata (tags, severity, tool_name, etc.)
    tags TEXT[] DEFAULT '{}', -- Quick filter tags

    -- Quality scoring
    relevance_score DECIMAL(5,4) DEFAULT 1.0, -- 0.0 to 1.0, adjusted by feedback
    citation_count INTEGER DEFAULT 0, -- How many times this was retrieved and used

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP, -- Track usage for cache eviction

    -- Indexes for performance
    CONSTRAINT unique_source_embedding UNIQUE(source_table, source_id, embedding_model)
);

CREATE INDEX idx_knowledge_vectors_project ON knowledge_vectors(project_id);
CREATE INDEX idx_knowledge_vectors_source ON knowledge_vectors(source_table, source_id);
CREATE INDEX idx_knowledge_vectors_source_type ON knowledge_vectors(source_type);
CREATE INDEX idx_knowledge_vectors_chroma_id ON knowledge_vectors(chroma_id);
CREATE INDEX idx_knowledge_vectors_tags ON knowledge_vectors USING GIN(tags);
CREATE INDEX idx_knowledge_vectors_metadata ON knowledge_vectors USING GIN(metadata);
CREATE INDEX idx_knowledge_vectors_relevance ON knowledge_vectors(relevance_score DESC);
CREATE INDEX idx_knowledge_vectors_created_at ON knowledge_vectors(created_at DESC);

COMMENT ON TABLE knowledge_vectors IS 'Stores embeddings and metadata for RAG system with Chroma vector DB';
COMMENT ON COLUMN knowledge_vectors.chroma_id IS 'Unique ID in Chroma database for vector lookup';
COMMENT ON COLUMN knowledge_vectors.relevance_score IS 'Quality score adjusted by user feedback (0.0-1.0)';
COMMENT ON COLUMN knowledge_vectors.citation_count IS 'Number of times this knowledge was retrieved and used';


-- ============================================================================
-- 2. TOOL SUCCESS METRICS TABLE
-- ============================================================================
-- Tracks effectiveness of each tool across different scenarios
-- Used for AI to learn which tools work best in different situations

CREATE TABLE IF NOT EXISTS tool_success_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,

    -- Tool identification
    tool_name VARCHAR(100) NOT NULL, -- nmap, nuclei, sqlmap, etc.
    tool_version VARCHAR(50), -- Track version for compatibility
    tool_category VARCHAR(50), -- 'scanner', 'fuzzer', 'exploit', 'recon'

    -- Target context
    target_type VARCHAR(50), -- 'web', 'network', 'cloud', 'api', 'mobile'
    service_name VARCHAR(100), -- apache, nginx, ssh, rdp, etc.
    service_version VARCHAR(100), -- Version string if known
    port INTEGER, -- Port number if applicable
    protocol VARCHAR(20), -- tcp, udp, http, https

    -- Performance metrics
    total_executions INTEGER DEFAULT 0,
    successful_executions INTEGER DEFAULT 0,
    failed_executions INTEGER DEFAULT 0,
    findings_generated INTEGER DEFAULT 0, -- How many findings this tool discovered
    false_positives INTEGER DEFAULT 0, -- Tracked from user feedback

    -- Success rate (auto-calculated trigger will maintain this)
    success_rate DECIMAL(5,2) DEFAULT 0.00, -- Percentage 0.00 to 100.00
    avg_execution_time_ms INTEGER, -- Average execution time

    -- Resource usage
    avg_cpu_percent DECIMAL(5,2),
    avg_memory_mb INTEGER,

    -- Timestamps
    first_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Metadata
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_tool_metrics_project ON tool_success_metrics(project_id);
CREATE INDEX idx_tool_metrics_tool ON tool_success_metrics(tool_name);
CREATE INDEX idx_tool_metrics_target_type ON tool_success_metrics(target_type);
CREATE INDEX idx_tool_metrics_service ON tool_success_metrics(service_name);
CREATE INDEX idx_tool_metrics_success_rate ON tool_success_metrics(success_rate DESC);
CREATE INDEX idx_tool_metrics_last_used ON tool_success_metrics(last_used DESC);
CREATE INDEX idx_tool_metrics_category ON tool_success_metrics(tool_category);

-- Create a unique index to prevent duplicate metrics (handles NULLs properly)
CREATE UNIQUE INDEX idx_unique_tool_metric ON tool_success_metrics(
    project_id,
    tool_name,
    target_type,
    COALESCE(service_name, ''),
    COALESCE(service_version, ''),
    COALESCE(port, 0)
);

COMMENT ON TABLE tool_success_metrics IS 'Tracks tool effectiveness for AI learning and optimization';
COMMENT ON COLUMN tool_success_metrics.success_rate IS 'Percentage of successful executions (0.00-100.00)';
COMMENT ON COLUMN tool_success_metrics.findings_generated IS 'Total findings discovered by this tool';


-- ============================================================================
-- 3. ATTACK PATTERNS TABLE
-- ============================================================================
-- Stores learned attack patterns (tool chains) that have been successful
-- AI uses these to plan attacks based on historical success

CREATE TABLE IF NOT EXISTS attack_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Pattern identification
    pattern_name VARCHAR(255) NOT NULL,
    pattern_hash VARCHAR(64) UNIQUE, -- Hash of tool_chain for deduplication
    pattern_type VARCHAR(50) NOT NULL, -- 'reconnaissance', 'exploitation', 'post_exploitation', 'privilege_escalation'

    -- Applicability conditions
    conditions JSONB NOT NULL, -- {"open_ports": [22, 80], "service": "nginx", "version_regex": "1\\.18\\..*"}
    target_type VARCHAR(50), -- 'web', 'network', 'cloud', 'api'

    -- Tool chain (ordered list of tools to execute)
    tool_chain TEXT[] NOT NULL, -- ['nmap -sV', 'httpx -title', 'nuclei -t cves/', 'sqlmap --batch']
    estimated_duration_minutes INTEGER, -- Expected execution time

    -- Success metrics
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    total_attempts INTEGER DEFAULT 0,
    avg_success_rate DECIMAL(5,2) DEFAULT 0.00, -- Percentage

    -- Risk and severity
    risk_level VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    requires_approval BOOLEAN DEFAULT TRUE, -- Does this pattern require human approval?

    -- Findings expected
    expected_finding_types TEXT[], -- ['SQLi', 'XSS', 'RCE']
    avg_findings_per_success DECIMAL(5,2),

    -- Metadata and tags
    description TEXT,
    tags TEXT[] DEFAULT '{}',
    mitre_techniques TEXT[] DEFAULT '{}', -- MITRE ATT&CK technique IDs
    metadata JSONB DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_successful_use TIMESTAMP,
    last_failed_use TIMESTAMP,

    -- Source tracking
    learned_from_scan_id UUID, -- Which scan taught us this pattern?
    created_by VARCHAR(50) DEFAULT 'system', -- 'system', 'ai', 'human', 'import'
    confidence_score DECIMAL(5,4) DEFAULT 0.5000 -- 0.0 to 1.0
);

CREATE INDEX idx_attack_patterns_type ON attack_patterns(pattern_type);
CREATE INDEX idx_attack_patterns_target_type ON attack_patterns(target_type);
CREATE INDEX idx_attack_patterns_success_rate ON attack_patterns(avg_success_rate DESC);
CREATE INDEX idx_attack_patterns_tags ON attack_patterns USING GIN(tags);
CREATE INDEX idx_attack_patterns_conditions ON attack_patterns USING GIN(conditions);
CREATE INDEX idx_attack_patterns_mitre ON attack_patterns USING GIN(mitre_techniques);
CREATE INDEX idx_attack_patterns_risk ON attack_patterns(risk_level);
CREATE INDEX idx_attack_patterns_confidence ON attack_patterns(confidence_score DESC);
CREATE INDEX idx_attack_patterns_updated ON attack_patterns(updated_at DESC);

COMMENT ON TABLE attack_patterns IS 'Learned attack patterns (tool chains) for AI-driven pentesting';
COMMENT ON COLUMN attack_patterns.tool_chain IS 'Ordered array of tools/commands to execute';
COMMENT ON COLUMN attack_patterns.conditions IS 'JSON conditions that must match for pattern to apply';
COMMENT ON COLUMN attack_patterns.confidence_score IS 'AI confidence in this pattern (0.0-1.0)';


-- ============================================================================
-- 4. AGENT DECISIONS TABLE
-- ============================================================================
-- Audit trail of all decisions made by autonomous agents
-- Critical for debugging, compliance, and improving AI reasoning

CREATE TABLE IF NOT EXISTS agent_decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    scan_job_id UUID REFERENCES scan_jobs(id) ON DELETE SET NULL,

    -- Agent identification
    agent_type VARCHAR(50) NOT NULL, -- 'orchestrator', 'recon', 'web', 'network', 'cloud', 'api', 'exploit'
    agent_version VARCHAR(20),

    -- Decision details
    decision_type VARCHAR(50) NOT NULL, -- 'tool_selection', 'target_prioritization', 'exploit_approval', 'pivot_decision'
    decision_input JSONB NOT NULL, -- Input data the agent considered
    decision_output JSONB NOT NULL, -- What the agent decided

    -- Reasoning (for explainability)
    reasoning TEXT, -- Natural language explanation from LLM
    llm_model VARCHAR(50), -- Which LLM made this decision
    llm_prompt_hash VARCHAR(64), -- Hash of prompt for reproducibility

    -- Context
    rag_context_used JSONB, -- Which knowledge vectors were retrieved
    attack_patterns_used UUID[], -- Which attack patterns were considered
    confidence_score DECIMAL(5,4), -- Agent's confidence (0.0-1.0)

    -- Outcome tracking
    was_executed BOOLEAN DEFAULT FALSE,
    execution_status VARCHAR(20), -- 'pending', 'approved', 'rejected', 'completed', 'failed'
    outcome_success BOOLEAN, -- Did it work?
    findings_generated INTEGER DEFAULT 0,

    -- User interaction
    required_approval BOOLEAN DEFAULT FALSE,
    approved_by VARCHAR(100), -- User who approved (if applicable)
    approved_at TIMESTAMP,
    rejection_reason TEXT,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    executed_at TIMESTAMP,
    completed_at TIMESTAMP,

    -- Metadata
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_agent_decisions_project ON agent_decisions(project_id);
CREATE INDEX idx_agent_decisions_scan_job ON agent_decisions(scan_job_id);
CREATE INDEX idx_agent_decisions_agent_type ON agent_decisions(agent_type);
CREATE INDEX idx_agent_decisions_decision_type ON agent_decisions(decision_type);
CREATE INDEX idx_agent_decisions_execution_status ON agent_decisions(execution_status);
CREATE INDEX idx_agent_decisions_required_approval ON agent_decisions(required_approval) WHERE required_approval = TRUE;
CREATE INDEX idx_agent_decisions_created_at ON agent_decisions(created_at DESC);
CREATE INDEX idx_agent_decisions_confidence ON agent_decisions(confidence_score DESC);
CREATE INDEX idx_agent_decisions_llm_model ON agent_decisions(llm_model);

COMMENT ON TABLE agent_decisions IS 'Audit trail of all autonomous agent decisions for compliance and learning';
COMMENT ON COLUMN agent_decisions.reasoning IS 'Natural language explanation of why agent made this decision';
COMMENT ON COLUMN agent_decisions.rag_context_used IS 'Knowledge vectors that informed this decision';
COMMENT ON COLUMN agent_decisions.confidence_score IS 'Agent confidence in decision (0.0-1.0)';


-- ============================================================================
-- 5. LEARNING FEEDBACK TABLE
-- ============================================================================
-- Stores user feedback on findings, tool effectiveness, and agent decisions
-- Used to improve future recommendations

CREATE TABLE IF NOT EXISTS learning_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,

    -- Feedback target (polymorphic)
    feedback_type VARCHAR(50) NOT NULL, -- 'finding', 'agent_decision', 'tool_recommendation', 'attack_pattern'
    target_table VARCHAR(50) NOT NULL,
    target_id UUID NOT NULL,

    -- Feedback details
    rating INTEGER CHECK (rating BETWEEN 1 AND 5), -- 1=poor, 5=excellent
    is_correct BOOLEAN, -- For true/false feedback
    is_useful BOOLEAN, -- Was this helpful?

    -- Detailed feedback
    feedback_text TEXT,
    correction_data JSONB, -- If user corrected something, store the correction

    -- User info
    submitted_by VARCHAR(100),
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Processing status
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMP,
    applied_changes JSONB, -- What changes were made based on this feedback

    -- Metadata
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_learning_feedback_project ON learning_feedback(project_id);
CREATE INDEX idx_learning_feedback_type ON learning_feedback(feedback_type);
CREATE INDEX idx_learning_feedback_target ON learning_feedback(target_table, target_id);
CREATE INDEX idx_learning_feedback_processed ON learning_feedback(processed) WHERE processed = FALSE;
CREATE INDEX idx_learning_feedback_submitted_at ON learning_feedback(submitted_at DESC);
CREATE INDEX idx_learning_feedback_rating ON learning_feedback(rating);

COMMENT ON TABLE learning_feedback IS 'User feedback for continuous improvement of AI agent';
COMMENT ON COLUMN learning_feedback.correction_data IS 'User corrections to improve future decisions';
COMMENT ON COLUMN learning_feedback.applied_changes IS 'Changes made to system based on this feedback';


-- ============================================================================
-- 6. TRIGGERS FOR AUTO-CALCULATIONS
-- ============================================================================

-- Auto-update success_rate in tool_success_metrics
CREATE OR REPLACE FUNCTION update_tool_success_rate()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.total_executions > 0) THEN
        NEW.success_rate := ROUND((NEW.successful_executions::DECIMAL / NEW.total_executions::DECIMAL) * 100, 2);
    ELSE
        NEW.success_rate := 0.00;
    END IF;
    NEW.last_updated := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tool_success_rate
    BEFORE INSERT OR UPDATE OF successful_executions, failed_executions, total_executions
    ON tool_success_metrics
    FOR EACH ROW
    EXECUTE FUNCTION update_tool_success_rate();


-- Auto-update attack_patterns success metrics
CREATE OR REPLACE FUNCTION update_attack_pattern_metrics()
RETURNS TRIGGER AS $$
BEGIN
    NEW.total_attempts := NEW.success_count + NEW.failure_count;

    IF (NEW.total_attempts > 0) THEN
        NEW.avg_success_rate := ROUND((NEW.success_count::DECIMAL / NEW.total_attempts::DECIMAL) * 100, 2);
    ELSE
        NEW.avg_success_rate := 0.00;
    END IF;

    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_attack_pattern_metrics
    BEFORE INSERT OR UPDATE OF success_count, failure_count
    ON attack_patterns
    FOR EACH ROW
    EXECUTE FUNCTION update_attack_pattern_metrics();


-- Auto-update knowledge_vectors updated_at timestamp
CREATE OR REPLACE FUNCTION update_knowledge_vector_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_knowledge_vector_timestamp
    BEFORE UPDATE ON knowledge_vectors
    FOR EACH ROW
    EXECUTE FUNCTION update_knowledge_vector_timestamp();


-- ============================================================================
-- 7. HELPER VIEWS FOR ANALYTICS
-- ============================================================================

-- View: Top performing tools by success rate
CREATE OR REPLACE VIEW v_top_performing_tools AS
SELECT
    tool_name,
    tool_category,
    target_type,
    service_name,
    success_rate,
    total_executions,
    findings_generated,
    avg_execution_time_ms,
    last_used
FROM tool_success_metrics
WHERE total_executions >= 5 -- Only tools with meaningful sample size
ORDER BY success_rate DESC, findings_generated DESC
LIMIT 50;

COMMENT ON VIEW v_top_performing_tools IS 'Top 50 most effective tools based on success rate';


-- View: Most successful attack patterns
CREATE OR REPLACE VIEW v_successful_attack_patterns AS
SELECT
    pattern_name,
    pattern_type,
    target_type,
    tool_chain,
    avg_success_rate,
    total_attempts,
    success_count,
    expected_finding_types,
    risk_level,
    confidence_score,
    last_successful_use
FROM attack_patterns
WHERE total_attempts >= 3 -- Patterns with at least 3 attempts
ORDER BY avg_success_rate DESC, confidence_score DESC;

COMMENT ON VIEW v_successful_attack_patterns IS 'Attack patterns ranked by success rate';


-- View: Learning statistics summary
CREATE OR REPLACE VIEW v_learning_statistics AS
SELECT
    (SELECT COUNT(*) FROM knowledge_vectors) as total_knowledge_vectors,
    (SELECT COUNT(*) FROM tool_success_metrics) as total_tool_metrics,
    (SELECT COUNT(*) FROM attack_patterns) as total_attack_patterns,
    (SELECT COUNT(*) FROM agent_decisions) as total_agent_decisions,
    (SELECT COUNT(*) FROM learning_feedback WHERE processed = FALSE) as pending_feedback,
    (SELECT AVG(relevance_score) FROM knowledge_vectors) as avg_knowledge_relevance,
    (SELECT AVG(success_rate) FROM tool_success_metrics WHERE total_executions >= 5) as avg_tool_success_rate,
    (SELECT AVG(avg_success_rate) FROM attack_patterns WHERE total_attempts >= 3) as avg_pattern_success_rate,
    (SELECT COUNT(*) FROM agent_decisions WHERE outcome_success = TRUE) as successful_agent_decisions,
    (SELECT COUNT(*) FROM agent_decisions WHERE required_approval = TRUE AND execution_status = 'pending') as pending_approvals;

COMMENT ON VIEW v_learning_statistics IS 'Overall learning system statistics dashboard';


-- View: Recent agent decisions requiring approval
CREATE OR REPLACE VIEW v_pending_approvals AS
SELECT
    ad.id,
    ad.project_id,
    p.name as project_name,
    ad.agent_type,
    ad.decision_type,
    ad.reasoning,
    ad.confidence_score,
    ad.created_at,
    ad.decision_output,
    ad.rag_context_used
FROM agent_decisions ad
LEFT JOIN projects p ON ad.project_id = p.id
WHERE ad.required_approval = TRUE
  AND ad.execution_status = 'pending'
ORDER BY ad.created_at DESC;

COMMENT ON VIEW v_pending_approvals IS 'Agent decisions awaiting human approval';


-- ============================================================================
-- 8. HELPER FUNCTIONS
-- ============================================================================

-- Function: Record agent decision
CREATE OR REPLACE FUNCTION record_agent_decision(
    p_project_id UUID,
    p_agent_type VARCHAR,
    p_decision_type VARCHAR,
    p_decision_input JSONB,
    p_decision_output JSONB,
    p_reasoning TEXT DEFAULT NULL,
    p_llm_model VARCHAR DEFAULT 'llama3.2',
    p_requires_approval BOOLEAN DEFAULT FALSE,
    p_confidence_score DECIMAL DEFAULT 0.8
)
RETURNS UUID AS $$
DECLARE
    v_decision_id UUID;
BEGIN
    INSERT INTO agent_decisions (
        project_id,
        agent_type,
        decision_type,
        decision_input,
        decision_output,
        reasoning,
        llm_model,
        required_approval,
        confidence_score,
        execution_status
    ) VALUES (
        p_project_id,
        p_agent_type,
        p_decision_type,
        p_decision_input,
        p_decision_output,
        p_reasoning,
        p_llm_model,
        p_requires_approval,
        p_confidence_score,
        CASE WHEN p_requires_approval THEN 'pending' ELSE 'approved' END
    )
    RETURNING id INTO v_decision_id;

    RETURN v_decision_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION record_agent_decision IS 'Helper to record agent decisions with proper defaults';


-- Function: Update tool metrics
CREATE OR REPLACE FUNCTION update_tool_metrics(
    p_project_id UUID,
    p_tool_name VARCHAR,
    p_target_type VARCHAR,
    p_service_name VARCHAR DEFAULT NULL,
    p_service_version VARCHAR DEFAULT NULL,
    p_port INTEGER DEFAULT NULL,
    p_success BOOLEAN DEFAULT TRUE,
    p_execution_time_ms INTEGER DEFAULT NULL,
    p_findings_count INTEGER DEFAULT 0,
    p_tool_category VARCHAR DEFAULT 'scanner'
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tool_success_metrics (
        project_id,
        tool_name,
        tool_category,
        target_type,
        service_name,
        service_version,
        port,
        total_executions,
        successful_executions,
        failed_executions,
        findings_generated,
        avg_execution_time_ms,
        last_used
    ) VALUES (
        p_project_id,
        p_tool_name,
        p_tool_category,
        p_target_type,
        p_service_name,
        p_service_version,
        p_port,
        1,
        CASE WHEN p_success THEN 1 ELSE 0 END,
        CASE WHEN p_success THEN 0 ELSE 1 END,
        p_findings_count,
        p_execution_time_ms,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (project_id, tool_name, target_type, COALESCE(service_name, ''), COALESCE(service_version, ''), COALESCE(port, 0))
    DO UPDATE SET
        total_executions = tool_success_metrics.total_executions + 1,
        successful_executions = tool_success_metrics.successful_executions + CASE WHEN p_success THEN 1 ELSE 0 END,
        failed_executions = tool_success_metrics.failed_executions + CASE WHEN p_success THEN 0 ELSE 1 END,
        findings_generated = tool_success_metrics.findings_generated + p_findings_count,
        avg_execution_time_ms = CASE
            WHEN p_execution_time_ms IS NOT NULL THEN
                ROUND((COALESCE(tool_success_metrics.avg_execution_time_ms, 0) * tool_success_metrics.total_executions + p_execution_time_ms) / (tool_success_metrics.total_executions + 1))
            ELSE tool_success_metrics.avg_execution_time_ms
        END,
        last_used = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_tool_metrics IS 'Upsert tool success metrics after each execution';


-- Function: Get relevant attack patterns
CREATE OR REPLACE FUNCTION get_relevant_attack_patterns(
    p_target_type VARCHAR,
    p_conditions JSONB DEFAULT '{}',
    p_min_success_rate DECIMAL DEFAULT 50.0,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    pattern_id UUID,
    pattern_name VARCHAR,
    tool_chain TEXT[],
    success_rate DECIMAL,
    confidence_score DECIMAL,
    requires_approval BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ap.id,
        ap.pattern_name,
        ap.tool_chain,
        ap.avg_success_rate,
        ap.confidence_score,
        ap.requires_approval
    FROM attack_patterns ap
    WHERE ap.target_type = p_target_type
      AND ap.avg_success_rate >= p_min_success_rate
      AND ap.total_attempts >= 3
    ORDER BY
        ap.avg_success_rate DESC,
        ap.confidence_score DESC,
        ap.last_successful_use DESC NULLS LAST
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_relevant_attack_patterns IS 'Retrieve best attack patterns for given target type';


-- ============================================================================
-- 9. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON knowledge_vectors TO recon_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON tool_success_metrics TO recon_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON attack_patterns TO recon_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON agent_decisions TO recon_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON learning_feedback TO recon_user;

GRANT SELECT ON v_top_performing_tools TO recon_user;
GRANT SELECT ON v_successful_attack_patterns TO recon_user;
GRANT SELECT ON v_learning_statistics TO recon_user;
GRANT SELECT ON v_pending_approvals TO recon_user;

GRANT EXECUTE ON FUNCTION record_agent_decision TO recon_user;
GRANT EXECUTE ON FUNCTION update_tool_metrics TO recon_user;
GRANT EXECUTE ON FUNCTION get_relevant_attack_patterns TO recon_user;


-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

COMMIT;

-- Summary
SELECT 'Migration 008 completed successfully!' as status,
       'Added 5 tables for RAG and learning' as tables_added,
       '4 views for analytics' as views_added,
       '3 helper functions' as functions_added;
