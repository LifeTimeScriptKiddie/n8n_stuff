-- Phase E: Cloud Security Testing Tables
-- Supports Azure (extensible to AWS/GCP)

-- Azure tenants being tested
CREATE TABLE azure_tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  tenant_id VARCHAR(36) NOT NULL,
  tenant_name VARCHAR(255),
  primary_domain VARCHAR(255),
  verified_domains JSONB DEFAULT '[]',
  discovered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(project_id, tenant_id)
);

-- Azure subscriptions
CREATE TABLE azure_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES azure_tenants(id) ON DELETE CASCADE,
  subscription_id VARCHAR(36) NOT NULL,
  subscription_name VARCHAR(255),
  state VARCHAR(50),
  discovered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tenant_id, subscription_id)
);

-- Discovered Azure resources
CREATE TABLE azure_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES azure_subscriptions(id) ON DELETE CASCADE,
  resource_id VARCHAR(500) NOT NULL,
  resource_type VARCHAR(255),
  resource_name VARCHAR(255),
  resource_group VARCHAR(255),
  location VARCHAR(100),
  properties JSONB DEFAULT '{}',
  tags JSONB DEFAULT '{}',
  public_access BOOLEAN DEFAULT false,
  risk_score INTEGER DEFAULT 0,
  discovered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(subscription_id, resource_id)
);

-- Azure AD objects (users, groups, service principals, applications)
CREATE TABLE azure_ad_objects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES azure_tenants(id) ON DELETE CASCADE,
  object_id VARCHAR(36) NOT NULL,
  object_type VARCHAR(50) NOT NULL,
  display_name VARCHAR(255),
  upn VARCHAR(255),
  mail VARCHAR(255),
  enabled BOOLEAN DEFAULT true,
  properties JSONB DEFAULT '{}',
  discovered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tenant_id, object_id)
);

-- Azure role assignments
CREATE TABLE azure_role_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID REFERENCES azure_subscriptions(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES azure_tenants(id) ON DELETE CASCADE,
  assignment_id VARCHAR(255),
  principal_id VARCHAR(36) NOT NULL,
  principal_type VARCHAR(50),
  principal_name VARCHAR(255),
  role_definition_id VARCHAR(255),
  role_name VARCHAR(255),
  scope VARCHAR(500),
  discovered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cloud-specific findings
CREATE TABLE cloud_findings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  resource_id UUID REFERENCES azure_resources(id) ON DELETE SET NULL,
  tenant_id UUID REFERENCES azure_tenants(id) ON DELETE SET NULL,
  finding_type VARCHAR(100) NOT NULL,
  severity severity_level NOT NULL,
  title VARCHAR(500) NOT NULL,
  description TEXT,
  remediation TEXT,
  evidence JSONB DEFAULT '{}',
  status VARCHAR(50) DEFAULT 'open',
  discovered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE
);

-- Cloud credential tokens (cached in Redis, metadata here)
CREATE TABLE cloud_credential_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  credential_id UUID NOT NULL REFERENCES secure_credentials(id) ON DELETE CASCADE,
  redis_key VARCHAR(255) NOT NULL,
  token_type VARCHAR(50),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  last_used_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add Azure credential types to secure_credentials
ALTER TABLE secure_credentials
  DROP CONSTRAINT IF EXISTS secure_credentials_credential_type_check;

ALTER TABLE secure_credentials
  ADD CONSTRAINT secure_credentials_credential_type_check
  CHECK (credential_type IN (
    'password', 'ssh_key', 'ntlm_hash', 'kerberos_ticket', 'api_key', 'certificate',
    'azure_service_principal', 'azure_access_token', 'azure_managed_identity', 'azure_certificate',
    'aws_access_key', 'gcp_service_account'
  ));

-- Indexes
CREATE INDEX idx_azure_tenants_project ON azure_tenants(project_id);
CREATE INDEX idx_azure_subscriptions_tenant ON azure_subscriptions(tenant_id);
CREATE INDEX idx_azure_resources_subscription ON azure_resources(subscription_id);
CREATE INDEX idx_azure_resources_type ON azure_resources(resource_type);
CREATE INDEX idx_azure_resources_public ON azure_resources(public_access) WHERE public_access = true;
CREATE INDEX idx_azure_ad_objects_tenant ON azure_ad_objects(tenant_id);
CREATE INDEX idx_azure_ad_objects_type ON azure_ad_objects(object_type);
CREATE INDEX idx_azure_role_assignments_principal ON azure_role_assignments(principal_id);
CREATE INDEX idx_azure_role_assignments_role ON azure_role_assignments(role_name);
CREATE INDEX idx_azure_role_assignments_subscription ON azure_role_assignments(subscription_id);
CREATE INDEX idx_azure_role_assignments_tenant ON azure_role_assignments(tenant_id);
CREATE INDEX idx_cloud_findings_project ON cloud_findings(project_id);
CREATE INDEX idx_cloud_findings_severity ON cloud_findings(severity);
CREATE INDEX idx_cloud_findings_status ON cloud_findings(status);
CREATE INDEX idx_cloud_credential_cache_expires ON cloud_credential_cache(expires_at);

-- Views

-- Public Azure resources
CREATE VIEW public_azure_resources AS
SELECT
  r.*,
  s.subscription_name,
  t.tenant_name,
  p.name as project_name
FROM azure_resources r
JOIN azure_subscriptions s ON s.id = r.subscription_id
JOIN azure_tenants t ON t.id = s.tenant_id
JOIN projects p ON p.id = t.project_id
WHERE r.public_access = true;

-- Privileged role assignments
CREATE VIEW privileged_role_assignments AS
SELECT
  ra.*,
  s.subscription_name,
  t.tenant_name
FROM azure_role_assignments ra
LEFT JOIN azure_subscriptions s ON s.id = ra.subscription_id
LEFT JOIN azure_tenants t ON t.id = ra.tenant_id
WHERE ra.role_name IN ('Owner', 'Contributor', 'User Access Administrator', 'Global Administrator');

-- Cloud findings summary by project
CREATE VIEW cloud_findings_summary AS
SELECT
  p.id as project_id,
  p.name as project_name,
  COUNT(*) FILTER (WHERE cf.severity = 'critical') as critical_count,
  COUNT(*) FILTER (WHERE cf.severity = 'high') as high_count,
  COUNT(*) FILTER (WHERE cf.severity = 'medium') as medium_count,
  COUNT(*) FILTER (WHERE cf.severity = 'low') as low_count,
  COUNT(*) FILTER (WHERE cf.status = 'open') as open_count,
  COUNT(*) as total_findings
FROM projects p
LEFT JOIN cloud_findings cf ON cf.project_id = p.id
GROUP BY p.id, p.name;

-- Azure AD summary
CREATE VIEW azure_ad_summary AS
SELECT
  t.id as tenant_id,
  t.tenant_name,
  COUNT(*) FILTER (WHERE ao.object_type = 'user') as user_count,
  COUNT(*) FILTER (WHERE ao.object_type = 'group') as group_count,
  COUNT(*) FILTER (WHERE ao.object_type = 'servicePrincipal') as sp_count,
  COUNT(*) FILTER (WHERE ao.object_type = 'application') as app_count
FROM azure_tenants t
LEFT JOIN azure_ad_objects ao ON ao.tenant_id = t.id
GROUP BY t.id, t.tenant_name;

-- Functions

-- Get or create Azure tenant
CREATE OR REPLACE FUNCTION get_or_create_azure_tenant(
  p_project_id UUID,
  p_tenant_id VARCHAR(36),
  p_tenant_name VARCHAR(255) DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  SELECT id INTO v_id FROM azure_tenants
  WHERE project_id = p_project_id AND tenant_id = p_tenant_id;

  IF v_id IS NULL THEN
    INSERT INTO azure_tenants (project_id, tenant_id, tenant_name)
    VALUES (p_project_id, p_tenant_id, p_tenant_name)
    RETURNING id INTO v_id;
  END IF;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Get or create Azure subscription
CREATE OR REPLACE FUNCTION get_or_create_azure_subscription(
  p_tenant_uuid UUID,
  p_subscription_id VARCHAR(36),
  p_subscription_name VARCHAR(255) DEFAULT NULL,
  p_state VARCHAR(50) DEFAULT 'Enabled'
) RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  SELECT id INTO v_id FROM azure_subscriptions
  WHERE tenant_id = p_tenant_uuid AND subscription_id = p_subscription_id;

  IF v_id IS NULL THEN
    INSERT INTO azure_subscriptions (tenant_id, subscription_id, subscription_name, state)
    VALUES (p_tenant_uuid, p_subscription_id, p_subscription_name, p_state)
    RETURNING id INTO v_id;
  END IF;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Create cloud finding
CREATE OR REPLACE FUNCTION create_cloud_finding(
  p_project_id UUID,
  p_finding_type VARCHAR(100),
  p_severity severity_level,
  p_title VARCHAR(500),
  p_description TEXT DEFAULT NULL,
  p_remediation TEXT DEFAULT NULL,
  p_evidence JSONB DEFAULT '{}',
  p_resource_id UUID DEFAULT NULL,
  p_tenant_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO cloud_findings (
    project_id, resource_id, tenant_id, finding_type,
    severity, title, description, remediation, evidence
  ) VALUES (
    p_project_id, p_resource_id, p_tenant_id, p_finding_type,
    p_severity, p_title, p_description, p_remediation, p_evidence
  ) RETURNING id INTO v_id;

  -- Create notification for high/critical findings
  IF p_severity IN ('critical', 'high') THEN
    INSERT INTO notifications (
      project_id, notification_type, severity, title, message, entity_type, entity_id
    ) VALUES (
      p_project_id, 'cloud_finding', p_severity, p_title,
      COALESCE(p_description, p_title), 'cloud_finding', v_id
    );
  END IF;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Check token expiry and cleanup
CREATE OR REPLACE FUNCTION cleanup_expired_cloud_tokens() RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  DELETE FROM cloud_credential_cache
  WHERE expires_at < NOW()
  RETURNING COUNT(*) INTO v_count;

  RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql;
