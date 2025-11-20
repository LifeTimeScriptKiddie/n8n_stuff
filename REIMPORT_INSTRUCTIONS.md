# n8n Workflow Reimport Instructions

## ⚠️ CRITICAL: Your workflows need to be reimported!

The JSON files in `/Users/tester/Documents/n8n_stuff/workflows/` have been fixed with:
- ✅ PostgreSQL query expression prefixes (`=`)
- ✅ IF node operation fixes (`isNotEmpty` instead of `exists`)
- ✅ Subdomain storage query corrections
- ✅ Merge node configuration fixes

**BUT** n8n is still running the OLD versions from its database!

---

## How to Reimport (Choose ONE method)

### Method 1: Web Interface (RECOMMENDED)

1. **Open n8n**: http://127.0.0.1:5678

2. **Delete old workflows** (one by one):
   - Phase 1: Passive Reconnaissance
   - Phase 2: Active Reconnaissance
   - Phase 3: Vulnerability Assessment
   - Phase 4: Analysis & Reporting
   - Recon Dispatcher

3. **Import updated workflows**:
   - Click **"+"** → **"Import from File"**
   - Select and import each file:
     - `phase0_recon_dispatcher.json`
     - `phase1_passive_recon.json`
     - `phase2_active_recon.json`
     - `phase3_vulnerability_assessment.json`
     - `phase4_analysis_reporting.json`

4. **Verify**: Open each workflow and check that:
   - PostgreSQL nodes have queries starting with `=`
   - IF nodes use `isNotEmpty` (not `exists`)

---

### Method 2: Restart n8n with Fresh Import

```bash
# Stop n8n
docker-compose down

# Remove workflow database (⚠️ WARNING: This deletes ALL workflows!)
# Only do this if you want a completely fresh start
docker volume rm n8n_stuff_n8n_data

# Start n8n
docker-compose up -d

# Import all workflows via web interface
```

---

## Common Issues

### Error: "compareOperationFunctions[compareData.operation] is not a function"
- **Cause**: Old IF nodes with invalid `"operation": "exists"`
- **Fix**: Reimport Phase 2, 3, 4 workflows

### Error: "Template expressions not evaluating"
- **Cause**: PostgreSQL queries missing `=` prefix
- **Fix**: Reimport ALL workflows

### Error: "Store Subdomains in DB stuck"
- **Cause**: Query trying to insert `$json.subdomains` which doesn't exist
- **Fix**: Reimport Phase 1 workflow

---

## Quick Check

After reimporting, test with:

```bash
curl -X POST http://127.0.0.1:5678/webhook/recon-scan \
  -H "Content-Type: application/json" \
  -d '{"target": "example.com", "session_id": "test-'$(date +%s)'"}'
```

If successful, you should see all 4 phases start simultaneously!
