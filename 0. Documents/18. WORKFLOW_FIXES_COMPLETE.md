# Complete Workflow Fixes - All Phases

## Overview

All 5 workflow phases have been analyzed and fixed for webhook data access issues.

**Status:** ✅ **ALL WORKFLOWS FIXED** (Phase 0-4)

**Date Completed:** 2025-11-18

---

## Root Cause

When n8n webhook nodes receive POST requests with JSON bodies, the data is placed inside a `body` property:

```javascript
// ❌ WRONG - This returns undefined
$json.session_id

// ✅ CORRECT - This accesses the POST body data
$json.body.session_id
```

All workflows were trying to access `session_id` and other fields directly from `$json` instead of `$json.body`, causing them to fail with "undefined" errors.

---

## Fixes Applied

### Phase 0: Pre-Flight Validation
**Status:** ✅ Already correct (no fixes needed)

### Phase 1: Passive Reconnaissance
**Status:** ✅ Fixed (2025-11-18 morning)
- **References fixed:** 15+
- **Pattern:** `$json.session_id` → `$json.body.session_id`
- **Pattern:** `$('Webhook: Start Phase 1').item.json.session_id` → `$('Webhook: Start Phase 1').item.json.body.session_id`

### Phase 2: Active Reconnaissance
**Status:** ✅ Fixed (2025-11-18 afternoon)
- **References fixed:** 25
- **Pattern:** `$json.session_id` → `$json.body.session_id`
- **Pattern:** `$('Webhook: Start Phase 2').item.json.session_id` → `$('Webhook: Start Phase 2').item.json.body.session_id`

### Phase 3: Vulnerability Assessment
**Status:** ✅ Fixed (2025-11-18 afternoon)
- **References fixed:** 24
- **Pattern:** `$json.session_id` → `$json.body.session_id`
- **Pattern:** `$('Webhook: Start Phase 3').item.json.session_id` → `$('Webhook: Start Phase 3').item.json.body.session_id`

### Phase 4: Analysis & Reporting
**Status:** ✅ Fixed (2025-11-18 afternoon)
- **References fixed:** 16
- **Pattern:** `$json.session_id` → `$json.body.session_id`
- **Pattern:** `$('Webhook: Start Phase 4').item.json.session_id` → `$('Webhook: Start Phase 4').item.json.body.session_id`

### Recon Dispatcher
**Status:** ✅ Already correct (triggers phases correctly)

---

## Fix Commands Used

```bash
# Phase 2
sed -i '' "s/\$('Webhook: Start Phase 2').item.json.session_id/\$('Webhook: Start Phase 2').item.json.body.session_id/g" phase2_active_recon.json
sed -i '' 's/{{ $json.session_id }}/{{ $json.body.session_id }}/g' phase2_active_recon.json

# Phase 3
sed -i '' "s/\$('Webhook: Start Phase 3').item.json.session_id/\$('Webhook: Start Phase 3').item.json.body.session_id/g" phase3_vulnerability_assessment.json
sed -i '' 's/{{ $json.session_id }}/{{ $json.body.session_id }}/g' phase3_vulnerability_assessment.json

# Phase 4
sed -i '' "s/\$('Webhook: Start Phase 4').item.json.session_id/\$('Webhook: Start Phase 4').item.json.body.session_id/g" phase4_analysis_reporting.json
sed -i '' 's/{{ $json.session_id }}/{{ $json.body.session_id }}/g' phase4_analysis_reporting.json
```

---

## Workflow Chain

```
User Request
    ↓
Recon Dispatcher (creates session)
    ↓
Phase 1: Passive Recon (webhooks phase1-passive-recon)
    ↓
Phase 2: Active Recon (webhooks phase2-active-recon)
    ↓
Phase 3: Vuln Assessment (webhooks phase3-vuln-assessment)
    ↓
Phase 4: Analysis & Reporting (webhooks phase4-reporting)
```

Each phase:
1. Receives webhook POST with `{session_id, target, ...}`
2. Loads session details from database
3. Performs scanning/analysis
4. Stores results in database
5. Triggers next phase

---

## What To Do Now

### 1. Re-import ALL Workflows in n8n

**Delete existing workflows:**
- Phase 0: Pre-Flight Validation
- Phase 1: Passive Reconnaissance
- Phase 2: Active Reconnaissance
- Phase 3: Vulnerability Assessment
- Phase 4: Analysis & Reporting
- Recon Dispatcher

**Import updated workflows:**
```bash
# In n8n UI (http://localhost:5678):
# For each workflow:
1. Click "Workflows" → "Import from File"
2. Select /Users/tester/Documents/n8n_stuff/workflows/[workflow_name].json
3. Reconnect PostgreSQL credentials
4. Activate the workflow
```

**Import order:**
1. `phase0_preflight_validation.json`
2. `phase1_passive_recon.json` ← Fixed
3. `phase2_active_recon.json` ← Fixed
4. `phase3_vulnerability_assessment.json` ← Fixed
5. `phase4_analysis_reporting.json` ← Fixed
6. `recon_dispatcher.json`

### 2. Test The Complete Chain

```bash
# Submit a target via the web interface or curl:
curl -X POST http://localhost:5678/webhook/recon-scan \
  -H "Content-Type: application/json" \
  -d '{
    "target": "example.com",
    "source": "manual-test"
  }'
```

**Expected behavior:**
1. ✅ Recon Dispatcher creates session
2. ✅ Phase 1 loads session, runs passive recon
3. ✅ Phase 2 loads session, runs active recon
4. ✅ Phase 3 loads session, runs vuln assessment
5. ✅ Phase 4 loads session, generates report

### 3. Monitor Execution

Check n8n execution logs at: http://localhost:5678/executions

**Each phase should:**
- Load session details successfully (no "undefined")
- Execute scanning tools
- Store results in database
- Trigger next phase

---

## Common Issues & Solutions

### Issue: "session_id = 'undefined'" in SQL
**Cause:** Workflow still has old code accessing `$json.session_id`
**Solution:** Re-import the updated workflow file

### Issue: Phase doesn't trigger next phase
**Cause:** HTTP Request node may have wrong URL or body format
**Solution:** Check the "Trigger Phase X" node in each workflow

### Issue: "Table does not exist" error
**Cause:** Database missing required tables
**Solution:** Already fixed! All 15 tables exist ✅

### Issue: Workflow shows "Webhook not found"
**Cause:** Workflow not activated in n8n
**Solution:** Click "Active" toggle on workflow

---

## Files Modified

✅ `/workflows/phase1_passive_recon.json` - Fixed webhook refs (15+ changes)
✅ `/workflows/phase2_active_recon.json` - Fixed webhook refs (25 changes)
✅ `/workflows/phase3_vulnerability_assessment.json` - Fixed webhook refs (24 changes)
✅ `/workflows/phase4_analysis_reporting.json` - Fixed webhook refs (16 changes)

---

## Verification Checklist

After re-importing all workflows:

- [ ] All 6 workflows imported
- [ ] All workflows activated (green toggle)
- [ ] PostgreSQL credentials connected
- [ ] Test scan submitted successfully
- [ ] Phase 1 executes without errors
- [ ] Phase 2 executes without errors
- [ ] Phase 3 executes without errors
- [ ] Phase 4 executes without errors
- [ ] Final report generated

---

## Database Schema Status

✅ All 15 required tables exist:
- api_endpoints
- attack_chains
- finding_hashes
- http_services ← Added today
- passive_intel
- port_scan_results ← Added today
- recon_sessions
- scan_checkpoints
- scan_reports ← Added today
- screenshots ← Added today
- scope_definitions
- security_headers
- ssl_results
- subdomain_intel
- vulnerability_findings ← Added today

---

## Summary

**Before fixes:**
- ❌ Phase 1: Failed with "session_id = 'undefined'"
- ❌ Phase 2: Would fail (not tested yet)
- ❌ Phase 3: Would fail (not tested yet)
- ❌ Phase 4: Would fail (not tested yet)

**After fixes:**
- ✅ Phase 0: Pre-Flight validation works
- ✅ Phase 1: Passive recon works
- ✅ Phase 2: Active recon ready (webhook refs fixed)
- ✅ Phase 3: Vuln assessment ready (webhook refs fixed)
- ✅ Phase 4: Reporting ready (webhook refs fixed)

**Total changes:** 80+ webhook data references corrected across 4 workflows

---

**Action Required:** Re-import all workflows in n8n and test the complete chain!

**Last Updated:** 2025-11-18
**Status:** ✅ All workflows fixed and ready
