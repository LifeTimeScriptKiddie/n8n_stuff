# AI Agent Interface Guide

## Overview

The **MASTER_04_ai_interface_v3** workflow implements an intelligent, autonomous AI agent for penetration testing with:

- **RAG Integration** - Queries historical pentest knowledge from Chroma vector DB
- **Multi-turn Conversations** - Maintains conversation context across messages (1-hour sessions)
- **Autonomous Planning** - Creates multi-step attack plans before execution
- **Tool Selection** - Intelligently recommends security tools based on target/context
- **Decision Logging** - Records all agent decisions for learning and analytics

## Architecture

```
┌─────────────┐
│   User      │
│  (Webhook)  │
└──────┬──────┘
       │
       ▼
┌──────────────────────────────────────────────────────┐
│  Validate Input & Extract Session                   │
└──────┬───────────────────────────────────────────────┘
       │
       ▼
┌──────────────────┬──────────────────┐
│  Redis: Get      │  Chroma: Query   │  Parallel
│  Conversation    │  Knowledge Base  │  Context
│  History         │  (RAG)           │  Retrieval
└──────┬───────────┴──────┬───────────┘
       │                   │
       └─────────┬─────────┘
                 ▼
         ┌──────────────┐
         │ Merge Context│
         └──────┬───────┘
                │
                ▼
      ┌──────────────────┐
      │ Build AI Agent   │  Enhanced system prompt
      │ Prompt           │  + RAG context
      └──────┬───────────┘  + conversation history
             │
             ▼
      ┌──────────────────┐
      │ Ollama LLM       │  llama3.2:1b
      │ (llama3.2:1b)    │  (ultra-fast)
      └──────┬───────────┘
             │
             ▼
      ┌──────────────────┐
      │ Parse Response   │
      └──────┬───────────┘
             │
             ▼
      ┌──────────────────┐
      │ Route Action:    │
      │ scan/plan/status │
      └──────┬───────────┘
             │
             ├─[scan]──────► Execute Scan
             ├─[plan]──────► Return Plan
             └─[status]────► Query Status
                  │
                  ▼
            ┌──────────────┐
            │ Format       │
            │ Response     │
            └──────┬───────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
  ┌─────────────┐      ┌──────────────┐
  │Redis: Update│      │PostgreSQL:   │
  │Session      │      │Log Decision  │
  └──────┬──────┘      └──────────────┘
         │
         ▼
  ┌─────────────┐
  │Return to    │
  │User         │
  └─────────────┘
```

---

## API Reference

### Endpoint

```
POST http://localhost/webhook/ai-agent
```

### Request Format

```json
{
  "message": "Your natural language request",
  "session_id": "optional-session-id",  // Auto-generated if not provided
  "user_id": "optional-user-id"         // Defaults to 'default'
}
```

### Response Format

```json
{
  "success": true,
  "response": "Formatted response text",
  "agent_response": {
    "analysis": "Agent's analysis of your request",
    "action": "scan|plan|status|help",
    "target": "target.example.com",
    "plan": [
      {
        "phase": "Reconnaissance",
        "tools": ["subfinder", "httpx"],
        "description": "Enumerate subdomains and verify live hosts"
      }
    ],
    "confidence": 0.85,
    "reasoning": "Why the agent made this decision"
  },
  "session_id": "session_1732492800000"
}
```

---

## Usage Examples

### 1. Basic Scan Request

**Request:**
```bash
curl -X POST http://localhost/webhook/ai-agent \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "Scan 10.0.0.1"
  }'
```

**Response:**
```json
{
  "success": true,
  "response": "🤖 AI Agent Analysis:\nTarget appears to be an internal IP address. Recommending standard scanning profile.\n\n✅ Scan Started!\n🎯 Target: 10.0.0.1\n📋 Job ID: abc-123-def\n🔧 Agents: agent_network, agent_web\n\n💡 Reasoning: Internal IP requires network-focused reconnaissance with service enumeration",
  "agent_response": {
    "analysis": "Target appears to be an internal IP address. Recommending standard scanning profile.",
    "action": "scan",
    "target": "10.0.0.1",
    "plan": [
      {
        "phase": "Network Discovery",
        "tools": ["nmap", "naabu"],
        "description": "Identify open ports and services"
      },
      {
        "phase": "Service Enumeration",
        "tools": ["nmap -sV", "nuclei"],
        "description": "Fingerprint services and check for vulnerabilities"
      }
    ],
    "confidence": 0.9,
    "reasoning": "Internal IP requires network-focused reconnaissance with service enumeration"
  },
  "session_id": "session_1732492800000"
}
```

### 2. Planning Request (No Execution)

**Request:**
```bash
curl -X POST http://localhost/webhook/ai-agent \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "What would you recommend for testing example.com?"
  }'
```

**Response:**
```json
{
  "success": true,
  "response": "🤖 AI Agent Plan:\n\n📋 Analysis: Web target requiring comprehensive OWASP-style assessment\n\n🎯 Proposed Attack Plan:\n\nPhase 1: Subdomain Enumeration\nTools: subfinder, amass\n→ Discover all subdomains to expand attack surface\n\nPhase 2: Web Reconnaissance\nTools: httpx, katana, waybackurls\n→ Identify live hosts, crawl endpoints, gather historical data\n\nPhase 3: Vulnerability Scanning\nTools: nuclei, ffuf\n→ Test for common web vulnerabilities and hidden directories\n\nPhase 4: Deep Analysis\nTools: sqlmap, nmap\n→ Test for SQL injection and enumerate backend services\n\n💡 Reasoning: Public domain requires thorough web-focused testing\n📊 Confidence: 85%\n\nReview the plan and use 'scan' command to execute",
  "session_id": "session_1732492800000"
}
```

### 3. Multi-turn Conversation

**First Message:**
```bash
curl -X POST http://localhost/webhook/ai-agent \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "I need to test a login page",
    "session_id": "my-session-123"
  }'
```

**Agent asks for clarification...**

**Second Message (same session):**
```bash
curl -X POST http://localhost/webhook/ai-agent \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "It is at https://app.example.com/login",
    "session_id": "my-session-123"
  }'
```

**Agent remembers context and provides targeted recommendations.**

### 4. Status Check

**Request:**
```bash
curl -X POST http://localhost/webhook/ai-agent \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "What is the status of recent scans?"
  }'
```

**Response:**
```
📊 Recent Scans:

1. 10.0.0.1 - completed
   11/24/2025, 3:45:00 PM

2. example.com - running
   11/24/2025, 3:30:00 PM
```

---

## Agent Capabilities

### 1. Tool Selection

The agent knows about these security tools:
- **Subdomain enumeration**: subfinder, amass, assetfinder
- **Network scanning**: nmap, naabu
- **Web reconnaissance**: httpx, katana, waybackurls, gau
- **Fuzzing**: ffuf
- **Vulnerability scanning**: nuclei
- **Exploitation**: sqlmap, hydra, netexec

### 2. Intelligent Planning

The agent creates multi-phase plans:
- **Phase 1**: Reconnaissance (passive/active intel gathering)
- **Phase 2**: Enumeration (service/endpoint discovery)
- **Phase 3**: Vulnerability Assessment (automated scanning)
- **Phase 4**: Exploitation (manual/automated exploitation)

### 3. Context Awareness

The agent uses:
- **RAG Knowledge**: Historical pentesting data from Chroma vector DB
- **Conversation History**: Last 10 messages in current session
- **Decision Logs**: Past agent decisions and outcomes

### 4. Mode Recommendations

The agent recommends scan modes based on target:
- **quick**: Known safe targets, quick checks
- **standard**: Default for most targets
- **thorough**: Unknown targets, comprehensive assessment

---

## Advanced Features

### Session Management

Sessions are stored in Redis with 1-hour TTL:
- Automatically creates new sessions if not provided
- Maintains conversation context across multiple requests
- Session ID format: `session_<timestamp>`

### RAG Integration

The agent queries the Chroma vector database:
- Retrieves top 3 most relevant historical contexts
- Uses semantic search based on current message
- Improves recommendations with past learnings

### Decision Logging

All agent decisions are logged to PostgreSQL:
```sql
CREATE TABLE agent_decisions (
  id SERIAL PRIMARY KEY,
  session_id VARCHAR(255),
  user_id VARCHAR(255),
  user_message TEXT,
  agent_response JSONB,
  action_taken VARCHAR(50),
  confidence FLOAT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

This enables:
- Analytics on agent performance
- Learning from past decisions
- Debugging and improvement

---

## Configuration

### Model Selection

The agent uses `llama3.2:1b` by default for ultra-fast inference.

To change the model, edit the workflow node "AI Agent: Reasoning":
```json
{
  "model": "mistral:7b-instruct-q4_0"  // For better quality
}
```

### Temperature & Sampling

Current settings (low temperature for consistency):
```json
{
  "temperature": 0.3,    // Lower = more deterministic
  "top_p": 0.9,          // Nucleus sampling
  "top_k": 40            // Top-k sampling
}
```

For more creative/varied responses, increase temperature to 0.7-0.9.

### Session TTL

Sessions expire after 1 hour (3600 seconds).

To change, edit the "Redis: Update Session" node:
```
http://redis:6379/SETEX/ai_session:{{ $json.session_id }}/7200  // 2 hours
```

---

## Integration with Web Interface

Update your web interface (`web-interface/chat.html`) to use the AI agent:

```javascript
async function sendMessage() {
  const message = document.getElementById('userMessage').value;
  const sessionId = localStorage.getItem('ai_session_id') || `session_${Date.now()}`;

  const response = await fetch('http://localhost/webhook/ai-agent', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
      message: message,
      session_id: sessionId
    })
  });

  const data = await response.json();

  // Save session ID for multi-turn conversations
  localStorage.setItem('ai_session_id', data.session_id);

  // Display response
  displayMessage('Agent', data.response);

  // Optional: Show detailed agent response
  console.log('Agent Analysis:', data.agent_response);
}
```

---

## Troubleshooting

### Agent Returns Generic Responses

**Issue**: Agent doesn't understand requests
**Solution**:
1. Check if llama3.2:1b model is pulled: `docker exec recon_ollama ollama list`
2. Pull if missing: `docker exec recon_ollama ollama pull llama3.2:1b`
3. Consider using larger model for better understanding

### RAG Returns No Context

**Issue**: Chroma vector DB is empty
**Solution**:
1. Populate knowledge base with CVE data, exploit-db, etc.
2. Check Chroma is running: `curl http://localhost:8000/api/v1/heartbeat`
3. Verify collection exists: Check `pentest_knowledge` collection

### Session Not Persisting

**Issue**: Conversation history not maintained
**Solution**:
1. Check Redis is running: `docker ps | grep redis`
2. Verify Redis connection: `curl http://localhost:6379/PING`
3. Check session_id is being passed correctly

### Slow Response Times

**Issue**: Agent takes >30 seconds to respond
**Solution**:
1. Ensure llama3.2:1b (not larger model) is being used
2. Reduce RAG query results: Change `n_results` from 5 to 3
3. Check Ollama container resources: `docker stats recon_ollama`

---

## Performance Metrics

### Response Times (Typical)

| Component | Time |
|-----------|------|
| Redis lookup | 5-10ms |
| Chroma RAG query | 50-100ms |
| LLM inference (llama3.2:1b) | 2-5s |
| Total | 2-6s |

### Resource Usage

| Component | CPU | RAM |
|-----------|-----|-----|
| llama3.2:1b | 20-40% | 2-3GB |
| Redis | <5% | 100MB |
| Chroma | 5-10% | 500MB |

---

## Example Prompts to Try

### Reconnaissance
```
"Scan example.com"
"What subdomains exist for target.com?"
"Enumerate services on 192.168.1.0/24"
```

### Planning
```
"How would you approach testing a banking app?"
"Create a plan for testing api.example.com"
"What's the best way to test a WordPress site?"
```

### Learning
```
"What have we learned about SQL injection in past scans?"
"Show me successful exploitation techniques"
"What tools work best for API testing?"
```

### Status & Help
```
"What scans are running?"
"Show recent results"
"Help me understand your capabilities"
```

---

## Best Practices

1. **Use Session IDs** - Maintain context for complex assessments
2. **Review Plans First** - Ask for a plan before executing scans
3. **Provide Context** - Give the agent details about target type
4. **Check Confidence** - Low confidence (<0.5) means uncertain
5. **Learn from Logs** - Review `agent_decisions` table periodically

---

## Future Enhancements

Planned improvements:
- **Feedback loop**: Learn from scan results to improve recommendations
- **Multi-model support**: Use different models for different tasks
- **Custom tool integrations**: Add your own tools to the agent's repertoire
- **Risk assessment**: Automatically evaluate and prioritize findings
- **Report generation**: Create professional pentest reports

---

## Support

For issues or questions:
1. Check workflow execution logs in n8n UI
2. Review `agent_decisions` table for decision history
3. Monitor Ollama logs: `docker logs recon_ollama`
4. Verify all services are healthy: `docker compose ps`
