# AI Chat Interface Setup Guide

## Overview
Natural language interface for your pentesting automation platform. Just type commands like "Scan example.com" instead of constructing JSON webhooks!

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Browser → chat.html (Port 8080)                    │
│  "Scan example.com for vulnerabilities"             │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│  n8n Workflow: MASTER_04_ai_interface.json          │
│  Webhook: /webhook/ai-chat                          │
│                                                     │
│  1. Parse user message                              │
│  2. Call Ollama for intent extraction               │
│  3. Route to appropriate action                     │
│  4. Format and return response                      │
└─────────────────────────────────────────────────────┘
                    ↓
      ┌─────────────┴──────────────┐
      ↓                            ↓
┌──────────────┐        ┌──────────────────────┐
│  Ollama      │        │  Other n8n Workflows │
│  (llama3.2)  │        │  - Pentest           │
│              │        │  - Status            │
│              │        │  - RAG Query         │
└──────────────┘        └──────────────────────┘
```

---

## Quick Start

### Step 1: Make sure Ollama has llama3.2

```bash
# Check if llama3.2 is available
docker exec -it ollama ollama list

# If not, pull it
docker exec -it ollama ollama pull llama3.2:latest
```

### Step 2: Import the AI workflow

1. Open n8n: http://localhost:5678
2. Go to **Workflows** → **Import**
3. Select `MASTER_04_ai_interface.json`
4. Activate the workflow

### Step 3: Open the chat interface

```bash
# Open in browser
open http://localhost:8080/chat.html
```

### Step 4: Start chatting!

Try these commands:
- "help" - See all available commands
- "Scan example.com" - Start a security scan
- "Show scan status" - View recent scans
- "Quick test on 10.0.0.1" - Fast network scan

---

## Features

### Natural Language Commands

Instead of this:
```bash
curl -X POST http://localhost:5678/webhook/pentest/v2 \
  -H "Content-Type: application/json" \
  -d '{"target": "example.com", "project_id": "uuid", "mode": "standard"}'
```

Just say this:
```
Scan example.com
```

### Smart Intent Detection

The AI understands various ways to express the same intent:

**Scanning:**
- "Scan example.com"
- "Test hackthebox.com for vulnerabilities"
- "Run a pentest on 192.168.1.1"
- "Check https://target.com for SQL injection"
- "Quick network scan on 10.0.0.0/24"

**Status:**
- "Show scan status"
- "What's running?"
- "Check my scans"
- "List recent jobs"

**Queries:**
- "Show me SQL injection findings"
- "What vulnerabilities did we find?"
- "Search for CVE-2024-1234"

**Help:**
- "help"
- "what can you do?"
- "show commands"

### Automatic Target Type Detection

The AI automatically detects the target type:
- URLs starting with `http://` or `https://` → **Web scan**
- IP addresses or CIDR ranges → **Network scan**
- Mentions of "azure" or "aws" → **Cloud scan**
- URLs with `/api/` → **API scan**

### Scan Mode Detection

- "quick scan" → `mode: quick`
- "scan" (default) → `mode: standard`
- "thorough scan" or "deep scan" → `mode: thorough`

---

## Example Conversations

### Example 1: Starting a Scan

```
You: Scan hackthebox.com for vulnerabilities

AI: ✅ Scan Started Successfully!

🎯 Target: hackthebox.com
📋 Job ID: abc-123-def-456
🤖 Agents: recon, web

The scan is now running. Use "show status" to check progress.
```

### Example 2: Checking Status

```
You: Show scan status

AI: 📊 Recent Scan Jobs:

1. hackthebox.com - running
   Type: network-scan | Created: 11/24/2025, 2:30 PM

2. example.com - completed
   Type: network-scan | Created: 11/24/2025, 1:15 PM

3. 10.0.0.1 - queued
   Type: network-scan | Created: 11/24/2025, 1:00 PM
```

### Example 3: Getting Help

```
You: help

AI: 🤖 AI Pentesting Assistant

I can help you with:

Scanning Commands:
- "Scan example.com" - Start a security scan
- "Quick scan on 10.0.0.1" - Fast network scan
- "Thorough web test on https://target.com" - Deep web scan

Status Commands:
- "Show scan status" - View recent scans
- "What's running?" - Check active jobs

Query Commands:
- "Show me SQL injection findings" - Query knowledge base
- "What vulnerabilities did we find?" - Search results

Examples:
- "Scan hackthebox.com for SQL injection"
- "Run a quick network scan on 192.168.1.0/24"
- "Check status of my scans"
- "What are the latest CVEs?"

Just type naturally and I'll understand! 🎯
```

---

## How It Works

### 1. User Input → Parse
```javascript
User: "Scan example.com for vulnerabilities"
↓
Parse Chat Input node extracts:
- user_message: "Scan example.com for vulnerabilities"
- conversation_id: "conv_xxx"
- project_id: null (or from context)
```

### 2. Ollama → Intent Extraction
```javascript
Ollama receives prompt:
"Parse: 'Scan example.com for vulnerabilities'"
↓
Returns JSON:
{
  "intent": "scan",
  "target": "example.com",
  "scan_mode": "standard",
  "target_type": "auto"
}
```

### 3. Route → Action
```javascript
Switch node routes based on intent:
- intent: "scan" → Call /webhook/pentest/v2
- intent: "status" → Query scan_jobs table
- intent: "query" → Call /webhook/rag-query
- intent: "help" → Return help text
```

### 4. Format → Response
```javascript
Format Response node creates human-friendly message:
"✅ Scan Started Successfully!
🎯 Target: example.com
📋 Job ID: abc-123
🤖 Agents: recon, web"
```

---

## Customization

### Change Ollama Model

Edit the "Ollama: Parse Intent" node in MASTER_04:
```json
{
  "model": "llama3.2:latest"  // Change to mistral, codellama, etc.
}
```

### Add Custom Intents

1. Edit "Route by Intent" switch node
2. Add new case: `intent: "custom_action"`
3. Create action node
4. Connect to "Format Response"

### Modify System Prompt

Edit the Ollama node's prompt parameter to change how the AI interprets commands:
```
You are a pentesting assistant specialized in...
```

---

## Troubleshooting

### Chat UI shows "Connection error"

**Check n8n is running:**
```bash
docker ps | grep n8n
```

**Check workflow is active:**
1. Open n8n UI
2. Go to MASTER_04_ai_interface
3. Ensure toggle is ON (green)

**Check webhook URL:**
- Should be: `/webhook/ai-chat`
- Test: `curl http://localhost:5678/webhook/ai-chat`

### Ollama not responding

**Check Ollama is running:**
```bash
docker ps | grep ollama
docker logs ollama
```

**Check model is downloaded:**
```bash
docker exec -it ollama ollama list
```

**Pull model if missing:**
```bash
docker exec -it ollama ollama pull llama3.2:latest
```

### AI gives wrong responses

**Issue**: Intent detection is inaccurate

**Solution**: Adjust the Ollama temperature:
- Lower temperature (0.1) = More consistent, less creative
- Higher temperature (0.7) = More creative, less consistent

Edit the Ollama node → options → temperature

### Scans not starting

**Check project_id:**
- AI interface needs a valid project_id
- Either create a project first or modify workflow to auto-generate

**Check MASTER_02 workflow:**
- Make sure MASTER_02_agent_orchestration.json is active
- Test the webhook directly: `/webhook/pentest/v2`

---

## Advanced Usage

### Adding Context from Database

Modify "Parse Chat Input" to load user's recent scans:
```javascript
// Query user's recent scans
const recentScans = await $('PostgreSQL').executeQuery(
  `SELECT target FROM scan_jobs WHERE project_id = '${projectId}' LIMIT 5`
);

// Pass to Ollama as context
```

### Multi-turn Conversations

Store conversation history in PostgreSQL:
```sql
CREATE TABLE chat_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id TEXT,
  role TEXT, -- 'user' or 'assistant'
  message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

Then pass recent messages to Ollama for context.

### Voice Input

Add Web Speech API to chat.html:
```javascript
const recognition = new webkitSpeechRecognition();
recognition.onresult = (event) => {
  chatInput.value = event.results[0][0].transcript;
  sendMessage();
};
```

---

## Next Steps

1. **Integrate with existing projects**: Load project_id from localStorage or URL param
2. **Add authentication**: Protect the chat endpoint with API keys
3. **Enhance RAG**: Connect to knowledge_vectors for better context
4. **Add file uploads**: Upload scan results or configuration files
5. **Create custom commands**: Add domain-specific commands for your workflow

---

**Created**: 2025-11-24
**Workflow**: MASTER_04_ai_interface.json
**UI**: web-interface/chat.html
**Status**: Production Ready ✅
