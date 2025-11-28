# Consolidated Workflow Architecture

## Overview
The original 14 separate workflows have been consolidated into 3 large, maintainable workflows that provide the same functionality with better organization and error handling.

## New Workflow Structure

### 1. MASTER_01_intelligence_pipeline.json
**Purpose**: Intelligence gathering, learning, and knowledge management

**Components** (Original workflows 1-6):
- RAG Query Handler (webhook: `/webhook/rag-query`)
- Knowledge Embedder (runs every 6 hours)
- Learning Extractor (runs every 12 hours)
- Tool Analyzer (runs every 2 hours)
- Feedback Processor (runs every 6 hours)
- Feed Ingestor (runs every 24 hours)

**Triggers**:
- Webhook: POST to `/webhook/rag-query` for on-demand queries
- Multiple schedule triggers with different intervals per component

**Features**:
- Individual error handlers for each component (`onError: continueErrorOutput`)
- Centralized logging via "Log Completion" node
- Processes unembedded scan jobs, extracts learning patterns, analyzes tool performance

---

### 2. MASTER_02_agent_orchestration.json
**Purpose**: Agent coordination and execution control

**Components** (Original workflows 7-12):
- Agent Orchestrator (decides which agents to run)
- Agent: Recon (subdomain enumeration, port scanning)
- Agent: Web (web app security testing)
- Agent: Network (network scanning)
- Agent: Cloud (Azure/AWS security scanning)
- Agent: API (API testing and enumeration)

**Triggers**:
- Database Polling: Every 30 seconds for queued scan jobs
- Webhook: POST to `/webhook/pentest/v2` for manual scan initiation

**Features**:
- Automatic target type detection (web, network, cloud, API)
- Parallel agent execution based on target type
- Result aggregation from all active agents
- Individual error handlers per agent

---

### 3. MASTER_03_execution_control.json
**Purpose**: Approval management and exploit execution

**Components** (Original workflows 13-14):
- Approval Handler (monitors pending approvals)
- Exploit Runner (executes approved exploits)

**Triggers**:
- Schedule: Every 5 minutes for approval monitoring
- Webhook: POST to `/webhook/exploit/run` for exploit execution

**Features**:
- Approval verification before exploit execution
- Automatic notification generation for pending approvals
- Support for multiple exploit types: sqlmap, nuclei, nmap_vuln, searchsploit
- Command builder with proper escaping and validation
- Execution result recording with exit codes and output

---

### 4. MASTER_04_ai_interface.json (NEW!)
**Purpose**: Natural language interface for all operations

**Components**:
- Natural language parser using Ollama
- Intent extraction and routing
- Integration with all other workflows
- Conversational responses

**Triggers**:
- Webhook: POST to `/webhook/ai-chat` for natural language commands

**Features**:
- **Natural language input**: "Scan example.com" instead of JSON payloads
- **Intent recognition**: Automatically detects scan/status/query/help commands
- **Smart routing**: Routes to appropriate workflows based on intent
- **Conversational responses**: Human-friendly formatted responses
- **Chat UI included**: web-interface/chat.html provides beautiful chat interface

**Supported Commands**:
- Scanning: "Scan example.com", "Quick test on 10.0.0.1", "Thorough web scan on https://target.com"
- Status: "Show scan status", "What's running?", "Check my scans"
- Queries: "Show SQL injection findings", "What vulnerabilities were found?"
- Help: "help", "what can you do?"

---

## Migration Guide

### Importing Workflows
1. Open n8n web interface (http://localhost:5678)
2. Go to Workflows → Import
3. Import each MASTER workflow:
   - MASTER_01_intelligence_pipeline.json
   - MASTER_02_agent_orchestration.json
   - MASTER_03_execution_control.json
4. Verify PostgreSQL credentials are set (should auto-map to credential ID "1")
5. Activate each workflow

### Testing

#### Test Intelligence Pipeline:
```bash
curl -X POST http://localhost:5678/webhook/rag-query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "show me recent vulnerability findings",
    "project_id": "YOUR_PROJECT_UUID",
    "limit": 5
  }'
```

#### Test Agent Orchestration:
```bash
curl -X POST http://localhost:5678/webhook/pentest/v2 \
  -H "Content-Type: application/json" \
  -d '{
    "target": "example.com",
    "project_id": "YOUR_PROJECT_UUID",
    "mode": "standard"
  }'
```

#### Test Exploit Execution:
```bash
# First, create an approval in the database
docker exec -i recon_postgres psql -U recon_user -d recon_hub -c "
INSERT INTO approval_queue (project_id, agent_type, decision_type, target_info, status)
VALUES ('YOUR_PROJECT_UUID', 'exploit', 'vulnerability_scan', 'example.com', 'approved')
RETURNING id;"

# Then execute the exploit (use the returned approval ID)
curl -X POST http://localhost:5678/webhook/exploit/run \
  -H "Content-Type: application/json" \
  -d '{
    "approval_id": "APPROVAL_UUID_FROM_ABOVE",
    "exploit_type": "nuclei",
    "target": "example.com"
  }'
```

#### Test AI Chat Interface:
```bash
# Method 1: Open in browser (recommended)
open http://localhost:8080/chat.html

# Method 2: Test via curl
curl -X POST http://localhost:5678/webhook/ai-chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Scan example.com for vulnerabilities"
  }'

# Example natural language commands:
# "Scan hackthebox.com"
# "Show me the scan status"
# "Quick network test on 192.168.1.1"
# "help"
```

---

## Key Benefits

### 1. **Better Organization**
- Logical grouping: Intelligence, Agents, Execution
- Easier to navigate and understand
- Clear separation of concerns

### 2. **Individual Error Handling**
- Each component has `onError: continueErrorOutput`
- One component failure doesn't stop the entire workflow
- Better reliability and debugging

### 3. **Separate Schedules**
- Different polling intervals optimized for each component
- Reduced database load
- Flexible scheduling per component needs

### 4. **Shared Triggers**
- Agent orchestrator uses single database polling trigger
- All agents receive data through orchestrator decision
- Consistent execution flow

### 5. **Maintainability**
- 3 files instead of 14
- Easier version control
- Simpler backup and deployment

---

## Legacy Workflows

The original 14 workflows have been moved to `workflows/legacy/` for reference:
- 01_rag_query_helper.json
- 02_knowledge_embedder.json
- 03_learning_extractor.json
- 04_tool_analyzer.json
- 05_feedback_processor.json
- 06_feed_ingestor.json
- 07_agent_orchestrator.json
- 08_agent_recon.json
- 09_agent_web.json
- 10_agent_network.json
- 11_agent_cloud.json
- 12_agent_api.json
- 13_approval_handler.json
- 14_exploit_runner.json

**Do not import legacy workflows** - they are kept for reference only.

---

## Troubleshooting

### Workflow Not Executing
1. Check workflow is activated (toggle in n8n UI)
2. Verify PostgreSQL credentials are configured
3. Check n8n logs: `docker logs recon_n8n`

### Database Errors
1. Verify all migrations have run: `docker exec -i recon_postgres psql -U recon_user -d recon_hub -c "\dt"`
2. Check for missing tables in error message
3. Re-run migrations if needed: `./setup.sh`

### Webhook Not Responding
1. Verify webhook URLs in n8n UI match documentation
2. Check n8n is accessible: `curl http://localhost:5678/healthz`
3. Review webhook node settings (responseMode should be "lastNode")

### Schedule Not Triggering
1. Verify schedule trigger is properly configured
2. Check execution history in n8n UI
3. Ensure workflow is activated

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  MASTER 01: Intelligence Pipeline            │
│                                                              │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌───────────┐  │
│  │   RAG    │  │  Embedder │  │ Learning │  │  Analyzer │  │
│  │  Query   │  │  (6h)     │  │  (12h)   │  │   (2h)    │  │
│  └────┬─────┘  └─────┬─────┘  └────┬─────┘  └─────┬─────┘  │
│       │              │              │              │         │
│       └──────────────┴──────────────┴──────────────┘         │
│                          │                                   │
│                    [PostgreSQL]                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                MASTER 02: Agent Orchestration               │
│                                                              │
│  ┌──────────────┐          ┌────────────────────────┐       │
│  │  DB Polling  │──────────│   Orchestrator         │       │
│  │  (30s)       │          │   (Decision Engine)    │       │
│  └──────────────┘          └──────────┬─────────────┘       │
│                                       │                      │
│                  ┌────────────────────┼─────────────┐        │
│                  │         │          │        │    │        │
│            ┌─────▼───┐ ┌──▼───┐ ┌───▼────┐ ┌─▼──┐ ┌▼───┐   │
│            │  Recon  │ │ Web  │ │Network │ │Cloud│ │API │   │
│            └─────────┘ └──────┘ └────────┘ └────┘ └────┘   │
│                  │         │          │        │    │        │
│                  └─────────┴──────────┴────────┴────┘        │
│                                 │                            │
│                           [Aggregate]                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                MASTER 03: Execution Control                 │
│                                                              │
│  ┌──────────────┐          ┌────────────────────────┐       │
│  │  Approval    │──────────│   Send Notifications   │       │
│  │  Check (5m)  │          └────────────────────────┘       │
│  └──────────────┘                                           │
│                                                              │
│  ┌──────────────┐          ┌────────────────────────┐       │
│  │   Exploit    │──────────│   Verify Approval      │       │
│  │   Webhook    │          └──────────┬─────────────┘       │
│  └──────────────┘                     │                     │
│                              ┌─────────▼──────────┐          │
│                              │  Execute & Record  │          │
│                              └────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

---

## Next Steps

1. **Import the 3 MASTER workflows into n8n**
2. **Activate all workflows**
3. **Test each webhook endpoint**
4. **Monitor execution logs**
5. **Delete or archive old workflows from n8n UI** (legacy files are already moved to workflows/legacy/)

---

**Created**: 2025-11-24
**Status**: Production Ready
**Workflows**: 3 consolidated (replacing 14 individual workflows)
