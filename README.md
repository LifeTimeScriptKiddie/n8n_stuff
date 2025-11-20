# n8n Reconnaissance Hub

An agentic penetration testing and reconnaissance hub powered by **n8n**, **Ollama** (local LLM), and security tools. Submit any target and an AI agent will automatically plan and execute reconnaissance, generating a professional security report.

Built on a lightweight, on-demand architecture where security tools are installed as needed.

## Architecture

```
+-----------------+      +--------------------+      +---------------------+
|   User / API    |----->|   NGINX (Port 80)  |----->|   n8n Recon Hub     |
+-----------------+      | (Reverse Proxy)    |      | (Workflow Engine)   |
                         +--------------------+      +----------+----------+
                                                                |
                                                     +----------v----------+
                                                     |   Ollama (Local LLM)|
                                                     +---------------------+
```

**Services:**
- **n8n Recon Hub** - Workflow automation engine with security tools
- **Ollama** - Local LLM for planning and report generation
- **PostgreSQL** - Database backend for n8n
- **NGINX** - Reverse proxy exposing webhooks on port 80

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
# Edit .env with your passwords
```

### 2. Launch the Stack

```bash
docker-compose up -d
```

Build time: ~3-5 minutes (lightweight image)

### 3. Pull Ollama Model

```bash
docker exec recon_ollama ollama pull llama3.2
```

### 4. Import & Activate Workflow

1. Open **http://localhost:5678**
2. Login (default: `admin` / see `.env`)
3. **Workflows** → **Import from File** → `workflows/agentic_pentest_demo.json`
4. **Activate** the workflow (toggle switch)

### 5. Test

```bash
curl -X POST http://localhost/webhook/pentest \
  -H "Content-Type: application/json" \
  -d '{"target": "example.com"}'
```

## Available Tools

### Pre-installed
- `nmap` - Network scanning
- `subfinder` - Subdomain enumeration
- `httpx` - HTTP probing
- `nuclei` - Vulnerability scanning
- `amass` - Attack surface mapping
- `dig`, `whois`, `curl`, `wget`

### On-Demand Installation

The AI can install additional tools using `/usr/local/bin/install-tool`:

```bash
install-tool ffuf      # Web fuzzer
install-tool katana    # JS endpoint discovery
install-tool naabu     # Port scanner
install-tool waybackurls
install-tool gau
```

## Workflow Logic

1. **Webhook Trigger** - Receives POST at `/webhook/pentest`
2. **AI Recon Planner** - Ollama analyzes target, outputs JSON command plan
3. **Execute Commands** - Loops through and runs each command
4. **Aggregate Results** - Collects all stdout/stderr
5. **AI Report Generator** - Ollama generates Markdown security report
6. **Respond** - Returns JSON with report

## API Endpoint

**POST** `http://localhost/webhook/pentest`

**Request:**
```json
{
  "target": "example.com"
}
```

**Response:**
```json
{
  "success": true,
  "report": "# Security Assessment Report\n\n## Executive Summary...",
  "target": "example.com",
  "target_type": "domain",
  "commands_executed": 4,
  "timestamp": "2025-01-20T10:30:00.000Z"
}
```

## Customization

### Change LLM Model

Edit the workflow's HTTP Request nodes and change `llama3.2` to:
- `llama3.1:8b` - Better quality, slower
- `mistral` - Good alternative
- `tinyllama` - Fastest, lower quality

### Add New Tools

1. Add installation logic to `install-tool` script in `Dockerfile`
2. Update the AI Recon Planner prompt to include the new tool

## Troubleshooting

### Ollama Not Responding
```bash
docker logs recon_ollama
curl http://localhost:11434/api/tags
```

### Model Not Found
```bash
docker exec recon_ollama ollama list
docker exec recon_ollama ollama pull llama3.2
```

### Command Execution Fails
- Check n8n UI → **Executions** → inspect failed workflow
- Click "Run Command" node to see stdout/stderr

### Webhook Timeout
- The process can take several minutes
- Check n8n UI for execution status (continues in background)

## Useful Commands

```bash
# Start/stop services
docker-compose up -d
docker-compose down

# View logs
docker-compose logs -f n8n-recon
docker-compose logs -f ollama

# Access container shell
docker exec -it n8n_recon_hub bash

# Database access
docker exec -it recon_postgres psql -U recon_user -d recon_hub
```

## Security Notice

- Only use against **authorized targets**
- Webhook is publicly accessible on port 80
- Consider adding authentication for production
- Results may contain sensitive reconnaissance data
