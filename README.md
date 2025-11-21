# n8n Recon Hub

**AI-powered penetration testing and reconnaissance automation platform.** Leverages n8n for workflow automation, Ollama for AI-driven planning, and a comprehensive suite of security tools to automate the entire recon process from target submission to final report generation.

## Architecture

```
+------------------+     +--------------------+     +---------------------+
|  User / Web UI   |---->|   NGINX (Port 80)  |---->|   n8n Recon Hub     |
+------------------+     | (Reverse Proxy)    |     | (Workflow Engine)   |
                         +--------------------+     +----------+----------+
                                                               |
                                              +----------------+----------------+
                                              |                                 |
                                   +----------v----------+          +-----------v-----------+
                                   |   Ollama (LLM)      |          |   PostgreSQL (DB)     |
                                   +---------------------+          +-----------------------+
```

**Services:**
- **n8n-recon**: Core automation engine with pre-installed security tools
- **Ollama**: Local LLM (Llama 3.2) for AI planning and report generation
- **PostgreSQL**: Database for workflow executions and scan data
- **NGINX**: Reverse proxy and web interface server

## Features

### AI Planner Versions

| Feature | v1 (Basic) | v2 (Advanced) |
|---------|------------|---------------|
| Commands | 2-4 | Mode-based (1-6+) |
| Targets | Single IP/Domain/URL | CIDR, wildcards, multiple, cloud |
| Tools | Core only | Full toolkit |
| Modes | N/A | quick/standard/thorough/stealth |

### Automatic Tool Installation
Tools are installed on-demand when the AI requests them. No need to pre-install everything.

### Scan Modes (v2)
- **quick**: Fast scan (1-2 commands)
- **standard**: Balanced scan (3-5 commands)
- **thorough**: Comprehensive scan (6+ commands)
- **stealth**: Slow, evasive scanning (-T2, -sS flags)

### Supported Targets
- Single Domain: `example.com`
- IP Address: `192.168.1.1`
- CIDR Block: `192.168.1.0/24`
- Wildcard: `*.example.com`
- Multiple: `site1.com, site2.com`
- Cloud: `s3://bucket-name`

## Available Tools

| Category | Tools |
|----------|-------|
| **Port Scanning** | `nmap` (quick/full/stealth/UDP), `naabu` |
| **DNS & Subdomain** | `subfinder`, `amass`, `dig`, `dnsrecon`, `fierce` |
| **Web Recon** | `httpx`, `nuclei`, `gobuster`, `whatweb`, `testssl.sh`, `waybackurls` |
| **OSINT** | `whois`, `theHarvester` |
| **Cloud** | `aws-cli`, cloud nuclei templates |
| **Secrets** | `trufflehog`, `gitleaks` |

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
# Edit .env with your passwords and API keys
```

### 2. Launch the Stack

```bash
docker-compose up --build -d
```

Build time: ~3-5 minutes

### 3. Pull Ollama Model

```bash
docker exec recon_ollama ollama pull llama3.2
```

### 4. Import & Activate Workflows

1. Open **http://localhost:5678**
2. Login with credentials from `.env`
3. **Workflows** → **Import from File** → `workflows/pentest_router.json`
4. **Activate** the workflow (toggle switch)

### 5. Access Web Interface

Open **http://localhost** for the web UI

## Usage Examples

### Basic Scan (v1)
```bash
curl -X POST http://localhost/webhook/pentest \
  -H "Content-Type: application/json" \
  -d '{"target": "example.com"}'
```

### Standard Scan with Mode (v2)
```bash
curl -X POST http://localhost/webhook/pentest \
  -H "Content-Type: application/json" \
  -d '{
    "target": "example.com",
    "mode": "standard"
  }'
```

### Thorough Scan on CIDR
```bash
curl -X POST http://localhost/webhook/pentest \
  -H "Content-Type: application/json" \
  -d '{
    "target": "192.168.1.0/24",
    "mode": "thorough"
  }'
```

### Stealth Scan
```bash
curl -X POST http://localhost/webhook/pentest \
  -H "Content-Type: application/json" \
  -d '{
    "target": "10.0.0.1",
    "mode": "stealth"
  }'
```

### Multiple Targets
```bash
curl -X POST http://localhost/webhook/pentest \
  -H "Content-Type: application/json" \
  -d '{
    "target": "site1.com, site2.com, site3.com",
    "mode": "quick"
  }'
```

## Web Interface

Available at **http://localhost**

- **Target Input**: Enter target(s) - supports all formats
- **Scan Mode**: Select quick/standard/thorough/stealth
- **Start Scan**: Submits to AI planner
- **Report Display**: Shows generated markdown report with copy button

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /webhook/pentest` | Main router (auto-selects v1/v2) |
| `POST /webhook/pentest-v2` | Direct v2 advanced scan |
| `POST /webhook/recon-scan` | Multi-phase database-driven scan |

### Response Format
```json
{
  "success": true,
  "report": "# Security Assessment Report\n\n## Executive Summary...",
  "target": "example.com",
  "target_type": "domain",
  "scan_mode": "standard",
  "commands_executed": 4,
  "notes": "Scan completed successfully",
  "timestamp": "2025-01-20T10:30:00.000Z"
}
```

## Workflow Logic

1. **Webhook Trigger** - Receives POST request
2. **Route Detection** - Determines v1 (basic) or v2 (advanced)
3. **AI Planner** - Ollama analyzes target, outputs JSON command plan
4. **Auto-Install** - Installs missing tools on-demand
5. **Execute Commands** - Runs each command sequentially
6. **Aggregate Results** - Collects all output
7. **AI Report** - Generates markdown security report
8. **Respond** - Returns JSON with report

## Customization

### Change LLM Model

Edit workflow HTTP Request nodes, change `llama3.2` to:
- `llama3.1:8b` - Better quality, slower
- `mistral` - Good alternative
- `codellama` - Better for technical analysis

### Add New Tools

1. Update AI Planner prompt with new tool syntax
2. Add to `install-tool` script if not in package managers

## Troubleshooting

### 502 Bad Gateway
```bash
docker-compose logs n8n-recon
# Wait for container to be healthy
```

### AI Planner Fails
```bash
docker-compose logs ollama
docker exec recon_ollama ollama list
```

### Webhook Timeout
- Long scans continue in background
- Check n8n UI → Executions for status

### Tool Not Found
```bash
docker exec -it n8n_recon_hub install-tool <toolname>
```

## Useful Commands

```bash
# Start/stop
docker-compose up -d
docker-compose down

# Logs
docker-compose logs -f n8n-recon
docker-compose logs -f ollama

# Shell access
docker exec -it n8n_recon_hub bash

# Database
docker exec -it recon_postgres psql -U recon_user -d recon_hub

# Rebuild after Dockerfile changes
docker-compose up --build -d
```

## Security Notice

- Only use against **authorized targets**
- Webhook is publicly accessible on port 80
- Consider adding authentication for production
- Results may contain sensitive reconnaissance data
- Keep API keys secure in `.env` file
