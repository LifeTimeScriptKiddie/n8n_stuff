# Quick Start Guide - Autonomous Pentesting Platform

This guide will get you up and running with the autonomous pentesting system in under 30 minutes.

## Prerequisites

- Docker & Docker Compose
- 24GB RAM minimum (32GB recommended)
- 150GB free disk space
- Fast internet (15GB Ollama models to download)

---

## 🚀 Installation (5 minutes)

```bash
cd /path/to/n8n_stuff

# Build and start all services
./setup.sh

# Wait for all containers to be healthy
docker ps
```

**Expected output:**
```
✓ n8n_recon_hub (healthy)
✓ recon_postgres (healthy)
✓ recon_redis (healthy)
✓ recon_minio (healthy)
✓ recon_chroma (up)
✓ recon_ollama (up)
✓ n8n_nginx_proxy (up)
```

---

## 📥 Pull Ollama Models (30-60 minutes)

**Required for AI functionality:**

```bash
# Model 1: Main reasoning (2GB)
docker exec recon_ollama ollama pull llama3.2

# Model 2: Embeddings for RAG (274MB)
docker exec recon_ollama ollama pull nomic-embed-text

# Model 3: Fast decisions (4GB)
docker exec recon_ollama ollama pull mistral:7b-instruct

# Model 4: Code analysis (7GB)
docker exec recon_ollama ollama pull codellama:13b
```

**Verify models installed:**
```bash
docker exec recon_ollama ollama list
```

---

## 🔐 Get Your Credentials

```bash
cat CREDENTIALS.txt
```

Note your **n8n username** and **password**.

---

## 📋 Import Workflows (5 minutes) - UPDATED v3.0!

### Step 1: Access n8n
Open http://localhost:5678 and login with credentials from above.

### Step 2: Import 4 Master Workflows

**✨ NEW: Only 4 files to import now! (Old 14 workflows consolidated)**

Navigate to: **Workflows** → **Add workflow** → **Import from File**

**Import these 4 files (any order is fine):**
1. ✅ `workflows/MASTER_01_intelligence_pipeline.json`
2. ✅ `workflows/MASTER_02_agent_orchestration.json`
3. ✅ `workflows/MASTER_03_execution_control.json`
4. ✅ `workflows/MASTER_04_ai_interface.json` ⭐ **NEW: AI Chat**

**⚠️ DO NOT import files from `workflows/legacy/` folder - those are old versions!**

### Step 3: Activate Workflows

For **each imported workflow**:
1. Open the workflow
2. Toggle the **Active** switch (top right)
3. Click **Save**

**Verify:** All 4 workflows should show green "Active" badges.

---

## 🎯 Create Test Project

```bash
# Create project and save the UUID
docker exec -it recon_postgres psql -U recon_user -d recon_hub -c "
INSERT INTO projects (name, scope, rules_of_engagement)
VALUES (
  'Test Project',
  '[\"scanme.nmap.org\", \"example.com\"]',
  'Authorized test pentest'
)
RETURNING id;
"
```

**Copy the returned UUID** (looks like: `550e8400-e29b-41d4-a716-446655440000`)

---

## 🧪 Test the System

### Option 1: AI Chat Interface (Easiest!) ⭐ Recommended

```bash
# Open the AI chat interface
open http://localhost:8080/chat.html

# Then just type naturally:
# "Scan scanme.nmap.org"
# "Quick test on example.com"
# "Show scan status"
# "help"
```

### Option 2: Traditional Webhook API

Replace `YOUR_PROJECT_UUID` with the UUID from above:

```bash
# Option A: Natural language API
curl -X POST http://localhost:5678/webhook/ai-chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Scan scanme.nmap.org"}'

# Option B: Direct webhook (traditional)
curl -X POST http://localhost:5678/webhook/pentest/v2 \
  -H "Content-Type: application/json" \
  -d '{
    "target": "scanme.nmap.org",
    "project_id": "YOUR_PROJECT_UUID",
    "mode": "quick"
  }'
```

**Expected response:**
```json
{
  "success": true,
  "scan_job_id": "abc123...",
  "target": "scanme.nmap.org",
  "agents": ["recon", "network"],
  "timestamp": "2025-11-24T..."
}
```

---

## 📊 View Dashboards

### AI Chat Interface ⭐ NEW
```bash
open http://localhost:8080/chat.html
```
Natural language interface - just type "Scan example.com"

### Simple Web UI
```bash
open http://localhost:8080/index.html
```
Form-based interface for creating projects and scans

### Approval Dashboard
```bash
open http://localhost:8080/approval-dashboard.html
```
View pending actions requiring human approval

### Learning Statistics
```bash
open http://localhost:8080/learning-stats.html
```
View tool performance, attack patterns, and knowledge base metrics

### n8n Workflow Editor
```bash
open http://localhost:5678
```
Monitor workflow executions, view logs, edit workflows

---

## ✅ Verification Checklist

- [ ] All 7 containers running
- [ ] Ollama model llama3.2 pulled
- [ ] 4 MASTER workflows imported and activated
- [ ] Test project created
- [ ] AI chat test successful
- [ ] All dashboards accessible

---

## 🎓 Next Steps

### 1. Run Your First Real Scan

```bash
# Replace with your authorized target
curl -X POST http://localhost:5678/webhook/agent/orchestrate \
  -H "Content-Type: application/json" \
  -d '{
    "target": "your-authorized-target.com",
    "project_id": "YOUR_PROJECT_UUID",
    "scan_mode": "standard"
  }'
```

**Scan modes:**
- `quick`: Fast reconnaissance (1-2 min)
- `standard`: Balanced scan (5-10 min)
- `thorough`: Deep scan (15-30 min)

### 2. Monitor Learning

The system learns automatically:
- **Every 6 hours**: Knowledge embedder runs
- **Every 12 hours**: Learning extractor runs
- **Daily 2 AM**: Tool analyzer runs
- **Daily 3 AM**: Feed ingestor updates CVEs/exploits

Check learning stats: http://localhost:8080/learning-stats.html

### 3. Review Findings

```bash
# View findings in database
docker exec -it recon_postgres psql -U recon_user -d recon_hub -c "
SELECT
  f.title,
  f.severity,
  h.ip_address,
  f.created_at
FROM findings f
JOIN hosts h ON f.host_id = h.id
WHERE f.project_id = 'YOUR_PROJECT_UUID'
ORDER BY f.created_at DESC
LIMIT 10;
"
```

### 4. Approve High-Risk Actions

1. Visit http://localhost:8080/approval-dashboard.html
2. Review pending approvals
3. Click **Approve** or **Reject** with reason
4. Approved actions execute automatically

---

## 🔧 Troubleshooting

### Issue: "Ollama model not found"
```bash
# Re-pull the model
docker exec recon_ollama ollama pull llama3.2
```

### Issue: "Workflow not found"
- Ensure workflows are imported in correct order
- Verify workflows are **activated** (toggle switch)

### Issue: "Database connection failed"
```bash
# Restart postgres
docker-compose restart postgres
```

### Issue: "Chroma unhealthy"
- This is normal - Chroma works fine despite health check
- Services will start after dependencies are healthy

### View Logs
```bash
# n8n logs
docker logs -f n8n_recon_hub

# Ollama logs
docker logs -f recon_ollama

# Postgres logs
docker logs -f recon_postgres
```

---

## 🔌 Optional: Connect Claude Desktop

Integrate Claude Desktop with your n8n instance for AI-assisted workflow management.

### Quick Setup (5 minutes)

1. **Generate API Key in n8n**
   - Visit http://localhost:5678
   - Settings → API → Create API Key
   - Copy the key

2. **Add to Claude Desktop config**

   Edit: `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS)

   ```json
   {
     "mcpServers": {
       "n8n": {
         "command": "npx",
         "args": ["-y", "n8n-mcp"],
         "env": {
           "MCP_MODE": "stdio",
           "LOG_LEVEL": "error",
           "DISABLE_CONSOLE_OUTPUT": "true",
           "N8N_API_URL": "http://localhost:5678",
           "N8N_API_KEY": "paste_your_api_key_here"
         }
       }
     }
   }
   ```

3. **Restart Claude Desktop**
   - Quit completely (Cmd+Q)
   - Reopen
   - Look for MCP icon (🔌) in chat

**What you can do:**
- "List my n8n workflows"
- "Debug the agent orchestrator workflow"
- "Create a workflow to monitor SSL certificates"
- "Show recent workflow executions"

📖 **Detailed guide**: [CLAUDE_DESKTOP_N8N_MCP_SETUP.md](CLAUDE_DESKTOP_N8N_MCP_SETUP.md)

---

## 📚 Learn More

- **README.md** - Full architecture documentation
- **CLAUDE_DESKTOP_N8N_MCP_SETUP.md** - MCP integration guide
- **LLM_MODELS_GUIDE.md** - Model selection and management
- **AI_AGENT_GUIDE.md** - Autonomous agent system guide
- **Database Schema** - Check migrations/ directory
- **n8n Docs** - https://docs.n8n.io

---

## 🛡️ Security Reminders

⚠️ **CRITICAL:**
1. Only scan **authorized targets**
2. Backup your **N8N_ENCRYPTION_KEY** (in CREDENTIALS.txt)
3. Never commit **.env** or **CREDENTIALS.txt** to git
4. Use on **isolated networks** for sensitive pentests
5. Review all **approval queue** actions before approving

---

## 🎉 You're Ready!

Your autonomous pentesting platform is now operational and learning from every scan. The more you use it, the smarter it gets!

**Happy Hacking! 🚀**
