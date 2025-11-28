# n8n Workflow Import Checklist

## 📋 Files to Import (4 Total)

Import these 4 files into n8n at http://localhost:5678

### ✅ Step 1: Import Workflows

Navigate to: **Workflows** → **Add workflow** → **Import from File**

Then import these files:

1. **MASTER_01_intelligence_pipeline.json**
   - Location: `workflows/MASTER_01_intelligence_pipeline.json`
   - Purpose: RAG, knowledge embedding, learning, feeds
   - Contains: 6 scheduled triggers + 1 webhook

2. **MASTER_02_agent_orchestration.json**
   - Location: `workflows/MASTER_02_agent_orchestration.json`
   - Purpose: Agent coordination, scanning execution
   - Contains: Database polling + webhook for scans
   - Webhook: `/webhook/pentest/v2`

3. **MASTER_03_execution_control.json**
   - Location: `workflows/MASTER_03_execution_control.json`
   - Purpose: Approval handling, exploit execution
   - Contains: Approval monitoring + exploit webhook
   - Webhook: `/webhook/exploit/run`

4. **MASTER_04_ai_interface.json** ⭐ NEW
   - Location: `workflows/MASTER_04_ai_interface.json`
   - Purpose: Natural language AI interface
   - Contains: AI chat webhook
   - Webhook: `/webhook/ai-chat`

### ✅ Step 2: Activate Each Workflow

For each imported workflow:
1. Open the workflow
2. Click the **Active** toggle (top right) to turn it green
3. Click **Save**

### ✅ Step 3: Verify

Check that all 4 workflows show:
- ✅ Green "Active" badge
- ✅ No errors in execution history
- ✅ Credentials mapped (PostgreSQL should be ID "1")

---

## ❌ DO NOT Import These Files

Files in `workflows/legacy/` folder are old versions (01-14.json files).
**DO NOT import them** - they have been consolidated into the 4 MASTER workflows above.

---

## 🌐 Web Interfaces (No Import Needed)

These HTML files are automatically served by nginx - no import needed:

- `web-interface/index.html` - Simple form-based UI
- `web-interface/chat.html` - AI chat interface ⭐ NEW
- `web-interface/approval-dashboard.html` - Approval queue
- `web-interface/learning-stats.html` - Learning metrics

Access them at:
- http://localhost:8080/index.html
- http://localhost:8080/chat.html ⭐ Recommended!
- http://localhost:8080/approval-dashboard.html
- http://localhost:8080/learning-stats.html

---

## 🎯 Quick Test After Import

### Test 1: AI Chat (Easiest)
```bash
open http://localhost:8080/chat.html
# Then type: "help"
```

### Test 2: Direct API
```bash
curl -X POST http://localhost:5678/webhook/ai-chat \
  -H "Content-Type: application/json" \
  -d '{"message": "help"}'
```

### Test 3: Traditional Webhook
```bash
curl -X POST http://localhost:5678/webhook/pentest/v2 \
  -H "Content-Type: application/json" \
  -d '{
    "target": "scanme.nmap.org",
    "project_id": "auto-generated",
    "mode": "quick"
  }'
```

---

## 📚 Documentation

- **QUICKSTART.md** - Complete setup guide
- **README.md** - Full architecture documentation
- **AI_INTERFACE_SETUP.md** - AI chat setup and usage
- **CONSOLIDATED_WORKFLOWS_README.md** - Workflow architecture details

---

## ⚡ Summary

**Old way:** Import 14 separate workflow files
**New way:** Import 4 consolidated MASTER workflows ✅

**Total time:** ~5 minutes (vs 20+ minutes before)

**Benefits:**
- ✅ Easier to manage
- ✅ Individual error handling per component
- ✅ Separate schedules per function
- ✅ All functionality preserved
- ✅ Plus new AI chat interface!
