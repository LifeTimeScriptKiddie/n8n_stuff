# Scope Management for Red Team Operations

This directory contains the scope validation system for authorizing red team reconnaissance operations.

## ⚠️ CRITICAL: Authorization Required

**NEVER scan targets without explicit written authorization.** Unauthorized security testing is illegal and can result in:
- Federal criminal charges (Computer Fraud and Abuse Act)
- Civil lawsuits
- Loss of professional certifications
- Permanent ban from bug bounty platforms

## Files in this Directory

- `schema.json` - JSON Schema definition for scope files
- `example_scope.json` - Example scope file showing all available options
- `scope-validator.js` - Node.js script for validating targets against scope
- `README.md` - This file

## How to Create a Scope File

1. Copy `example_scope.json` to a new file (e.g., `my_engagement.json`)
2. Edit the file with your engagement details:
   - **scope_name**: Unique identifier for this engagement
   - **in_scope**: List of authorized domains/IPs/CIDR ranges
   - **out_of_scope**: Explicitly forbidden targets
   - **authorization**: Details about who authorized the engagement and when
   - **rules**: Technical constraints (stealth level, rate limits, allowed tools)

### Example Minimal Scope File

```json
{
  "scope_name": "my_company_2025",
  "description": "Internal assessment of mycompany.com",

  "in_scope": [
    "*.mycompany.com",
    "10.0.0.0/8"
  ],

  "out_of_scope": [
    "prod-db.mycompany.com",
    "mail.mycompany.com"
  ],

  "authorization": {
    "authorized_by": "Jane Doe <jane@mycompany.com>",
    "authorization_date": "2025-01-15",
    "expiry_date": "2025-04-15",
    "engagement_type": "red_team"
  }
}
```

## Using the Scope Validator

### CLI Usage

```bash
# Validate a single target
node scope-validator.js api.example.com scopes/my_engagement.json

# Test multiple targets
node scope-validator.js dev.example.com scopes/my_engagement.json
node scope-validator.js 10.0.1.50 scopes/my_engagement.json
```

### Exit Codes

- `0` - Target is authorized (in scope)
- `1` - Target is not authorized (out of scope)
- `2` - Error (invalid scope file, missing arguments)

### Example Output

**Authorized target:**
```
═══════════════════════════════════════════════════════════
  Red Team Scope Validator
═══════════════════════════════════════════════════════════

Target:      api.example.com
Scope File:  scopes/my_engagement.json

Scope:       my_company_2025
Type:        red_team

✓ AUTHORIZED
  Reason: Target matches in-scope pattern: *.example.com
  Matched Pattern: *.example.com
  Stealth Level: medium
  Rate Limit: 10 req/sec

You may proceed with reconnaissance.
```

**Unauthorized target:**
```
✗ UNAUTHORIZED
  Reason: Target matches out-of-scope pattern: prod-db.example.com

⚠ WARNING: Scanning this target is NOT AUTHORIZED!
Proceeding could violate laws and regulations.
```

## Using in n8n Workflows

The validator can be called from n8n Execute Command nodes:

```javascript
// In an n8n Function node
const target = $input.item.json.target;
const scopeFile = '/opt/n8n-data/scopes/my_engagement.json';

// This will be passed to Execute Command node
return {
  command: `node`,
  arguments: [
    '/opt/n8n-data/scopes/scope-validator.js',
    target,
    scopeFile
  ]
};
```

Then check the exit code:
- Exit code 0 = proceed with scan
- Exit code 1 = reject target (log and skip)
- Exit code 2 = error (alert operator)

## Scope Definition Reference

### Required Fields

- `scope_name` - Unique identifier (alphanumeric, dashes, underscores)
- `in_scope` - Array of authorized targets (domains, IPs, CIDR ranges)
- `authorization` - Object with:
  - `authorized_by` - Name/email of authorizing party
  - `authorization_date` - Date in YYYY-MM-DD format

### Optional Fields

- `description` - Human-readable description
- `out_of_scope` - Blacklist of forbidden targets
- `authorization.expiry_date` - When authorization expires
- `authorization.engagement_type` - red_team | penetration_test | vulnerability_assessment | bug_bounty
- `authorization.documentation_url` - Link to authorization documents
- `rules` - Technical constraints:
  - `max_ports` - Maximum ports to scan per host
  - `allowed_tools` - Whitelist of security tools
  - `stealth_level` - low | medium | high
  - `max_concurrent_scans` - Limit concurrent operations
  - `rate_limit_per_sec` - HTTP request rate limit
  - `require_manual_approval` - Require operator confirmation
  - `allowed_hours` - Time windows for scanning
- `contacts` - Emergency contact information
- `notes` - Additional notes

### Pattern Matching

**Domain Wildcards:**
- `*.example.com` - Matches any subdomain: api.example.com, dev.example.com
- `example.com` - Exact match only

**IP Addresses:**
- `192.168.1.100` - Exact IP match
- `10.0.0.0/8` - CIDR range (10.0.0.0 - 10.255.255.255)
- `172.16.0.0/12` - Private network range

**Priority:**
- `out_of_scope` takes precedence over `in_scope`
- More specific patterns should be in `out_of_scope`

### Time-Based Restrictions

You can limit scanning to specific days/hours:

```json
{
  "rules": {
    "allowed_hours": {
      "timezone": "America/New_York",
      "days": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      "start_time": "09:00",
      "end_time": "17:00"
    }
  }
}
```

This ensures scans only run during business hours in the specified timezone.

## Best Practices

1. **Always verify authorization** before creating a scope file
2. **Set expiry dates** to ensure time-limited engagements
3. **Be explicit with out_of_scope** - list all known third-party services
4. **Use appropriate stealth levels**:
   - `high` - For production environments, SOC monitoring active
   - `medium` - For staging/dev environments
   - `low` - For internal networks, testing labs
5. **Document everything** - Include links to authorization documents
6. **Test scope files** - Validate sample targets before starting scans
7. **Review regularly** - Check if scope has changed during engagement

## Common Out-of-Scope Targets

Always exclude:
- Third-party services (CDNs, analytics, payment processors)
- Shared infrastructure (mail servers, VPNs)
- Production databases with sensitive data
- Employee-facing applications (HR, payroll)
- Systems managed by vendors

## Troubleshooting

### "Failed to load scope file"
- Check file path is correct
- Ensure JSON is valid (use `jq` to validate)
- Verify file permissions

### "Target does not match any in-scope pattern"
- Check for typos in domain/IP
- Ensure wildcard patterns are correct
- Verify CIDR notation for IP ranges

### "Authorization expired"
- Check `expiry_date` in authorization section
- Request extension if engagement is ongoing
- Update scope file with new expiry date

## Security Considerations

1. **Scope files may contain sensitive information** - Do not commit to public repositories
2. **Encryption key in .env** - Required to decrypt n8n credentials
3. **Audit logging** - All scope checks should be logged
4. **Manual approval** - Enable for high-risk engagements
5. **Emergency contacts** - Ensure escalation paths are clear

## Integration with Database

Scope definitions can be loaded into the PostgreSQL database:

```sql
-- Load scope from JSON file
INSERT INTO scope_definitions (
    scope_name,
    in_scope,
    out_of_scope,
    stealth_level,
    rate_limit_per_sec,
    notes,
    authorized_by,
    authorization_date,
    expiry_date
)
SELECT
    scope_name,
    in_scope::text[],
    COALESCE(out_of_scope, '{}')::text[],
    rules->>'stealth_level',
    (rules->>'rate_limit_per_sec')::integer,
    notes,
    authorization->>'authorized_by',
    (authorization->>'authorization_date')::date,
    (authorization->>'expiry_date')::date
FROM json_populate_record(null::scope_definitions, '{...}');
```

This allows workflows to query the database instead of loading JSON files each time.

## Need Help?

- Review `example_scope.json` for a complete reference
- Check schema validation: `node -e "require('ajv').compile(require('./schema.json'))"`
- Test validator: `node scope-validator.js test.example.com example_scope.json`
- Consult RED_TEAM_GUIDE.md for operational guidance
