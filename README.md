# n8n Autonomous Pentesting Platform

**Self-learning, AI-powered autonomous penetration testing system with RAG (Retrieval-Augmented Generation) capabilities.** This platform combines traditional penetration testing tools with modern AI/ML for intelligent, adaptive security testing that learns from every scan.

## 🚀 What's New: Autonomous Agent Architecture

This is a **fully autonomous pentesting system** featuring:

- **🧠 RAG-Powered Intelligence**: Vector database (Chroma) + Ollama embeddings for semantic knowledge retrieval
- **🤖 Specialized Agents**: Modular agents for web, network, cloud, and API testing
- **📚 Self-Learning**: Extracts patterns from successful attacks, improves over time
- **⚡ Semi-Autonomous**: Executes recon/scanning autonomously, requires approval for exploitation
- **🔄 Continuous Learning**: Ingests CVE feeds, exploit databases, and security research
- **📊 Analytics Dashboard**: Real-time tool performance metrics and attack pattern success rates
- **🔌 Claude Desktop Integration**: Connect Claude via MCP for AI-assisted workflow management

## 🤖 LLM Model Profiles

The platform now supports multiple LLM model profiles for different resource constraints:

- **Minimal** (~2GB): Ultra-lightweight - `llama3.2:1b`, perfect for testing
- **Efficient** (~5GB): ⭐ **Recommended** - Quantized models for production use
- **Standard** (~10GB): Balanced performance and quality
- **Full** (~20GB): Complete model suite with code analysis

Configure via `LLM_MODEL_PROFILE` in `.env`. Use `./manage-models.sh` for easy model management.
📖 See **[LLM_MODELS_GUIDE.md](LLM_MODELS_GUIDE.md)** for complete documentation.

## Architecture v2.0 (Autonomous)

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERFACES                          │
│  Web UI (8080) │ n8n Dashboard (5678) │ Approval Dashboard     │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│                    AGENT ORCHESTRATOR                           │
│  • RAG Query (historical context)                              │
│  • AI Planning (Ollama llama3.2)                               │
│  • Agent Selection & Coordination                              │
└─────┬────────┬────────┬────────┬────────┬──────────────────────┘
      │        │        │        │        │
┌─────▼──┐ ┌──▼────┐ ┌─▼─────┐ ┌▼──────┐ ┌▼──────┐
│ Recon  │ │  Web  │ │Network│ │ Cloud │ │  API  │  Specialized
│ Agent  │ │ Agent │ │ Agent │ │ Agent │ │ Agent │  Agents
└────┬───┘ └───┬───┘ └───┬───┘ └───┬───┘ └───┬───┘
     │         │         │         │         │
     └─────────┴─────────┴─────────┴─────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                  LEARNING & STORAGE LAYER                       │
├─────────────────────┬───────────────────┬───────────────────────┤
│  Chroma Vector DB   │   PostgreSQL      │   MinIO              │
│  (Embeddings/RAG)   │   (Findings/Logs) │   (Evidence Files)   │
└─────────────────────┴───────────────────┴───────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                 INTELLIGENCE SOURCES                            │
│  ExploitDB │ NVD CVE Feed │ Nuclei Templates │ Security Research│
└─────────────────────────────────────────────────────────────────┘
```

**Services:**
- **Agent Orchestrator**: Master coordinator using RAG + AI planning
- **Specialized Agents**: 5 autonomous agents (recon, web, network, cloud, API)
- **Ollama**: Multi-model LLM stack (llama3.2, mistral, codellama, nomic-embed-text)
- **Chroma**: Vector database for semantic knowledge retrieval
- **PostgreSQL**: Structured data (findings, patterns, metrics, decisions)
- **Redis**: Ephemeral credentials and job queues
- **MinIO**: Evidence file storage

## 🎯 Consolidated Master Workflows (v3.0)

**NEW:** All 14 workflows consolidated into 4 master workflows for easier management!

### Master Workflows

| Workflow | Purpose | Triggers | Components |
|----------|---------|----------|------------|
| **MASTER_01_intelligence_pipeline** | Intelligence & Learning | Multiple schedules | RAG query, embedder (6h), learning (12h), analyzer (2h), feedback (6h), feeds (24h) |
| **MASTER_02_agent_orchestration** | Agent Coordination | DB polling (30s) + Webhook | Orchestrator + 5 agents (recon, web, network, cloud, API) |
| **MASTER_03_execution_control** | Approval & Exploitation | Schedule (5m) + Webhook | Approval handler + exploit runner |
| **MASTER_04_ai_interface** | 🤖 Natural Language AI | Webhook: `/webhook/ai-chat` | Ollama parser + intent router + conversational UI |

### 🚀 Quick Start: Import Only These 4 Files

**Just import these 4 workflows - that's it!**

1. `workflows/MASTER_01_intelligence_pipeline.json`
2. `workflows/MASTER_02_agent_orchestration.json`
3. `workflows/MASTER_03_execution_control.json`
4. `workflows/MASTER_04_ai_interface.json`

**Old workflows** (01-14) are in `workflows/legacy/` for reference only - **DO NOT IMPORT THEM**.

### 🤖 Usage Example: Natural Language (Easiest!)

```bash
# Option 1: Use the AI Chat Interface (Recommended!)
open http://localhost:8080/chat.html

# Then just type naturally:
# "Scan example.com"
# "Quick test on 10.0.0.1"
# "Show scan status"
# "Help"
```

### 📡 Usage Example: API/Webhook

```bash
# 1. Create a project
PROJECT_ID=$(docker exec -it recon_postgres psql -U recon_user -d recon_hub -tAc \
  "INSERT INTO projects (name, scope) VALUES ('Test', '[\"example.com\"]') RETURNING id;")

# 2. Option A: Natural language API
curl -X POST http://localhost:5678/webhook/ai-chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Scan scanme.nmap.org"}'

# 2. Option B: Direct webhook (traditional)
curl -X POST http://localhost:5678/webhook/pentest/v2 \
  -H "Content-Type: application/json" \
  -d "{
    \"target\": \"scanme.nmap.org\",
    \"project_id\": \"$PROJECT_ID\",
    \"mode\": \"standard\"
  }"

# 3. View dashboards
open http://localhost:8080/chat.html              # AI Chat Interface ⭐ NEW
open http://localhost:8080/index.html             # Simple Web UI
open http://localhost:8080/approval-dashboard.html # Approval Queue
open http://localhost:8080/learning-stats.html    # Learning Metrics
```

## Database Schema

### RAG & Learning Tables (Phase F)

```sql
knowledge_vectors       -- Vector embeddings for semantic search
tool_success_metrics    -- Tool effectiveness tracking
attack_patterns         -- Learned attack chains
agent_decisions         -- AI decision audit trail
learning_feedback       -- User feedback for improvement
exploit_executions      -- Exploitation attempt tracking
```

### Analytics Views

```sql
v_top_performing_tools         -- Best tools by success rate
v_successful_attack_patterns   -- Proven attack patterns
v_learning_statistics          -- Overall system learning metrics
v_pending_approvals            -- Actions awaiting approval
```

## Features

### API Versions

| Feature | v1 (Basic) | v2 (Enterprise) | v3 (Pivot) | v4 (Cloud) |
|---------|------------|-----------------|------------|------------|
| Project ID | No | Yes | Yes | Yes |
| Rate Limiting | No | Yes | Yes | Yes |
| Audit Logging | No | Yes | Yes | Yes |
| SSH Tunnels | No | No | Yes | No |
| Auto-Pivot | No | No | Yes | No |
| Cloud Scanning | No | No | No | Yes (Azure) |
| Scan Modes | N/A | 4 modes | 4 modes | 7 cloud modes |

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

### **Core Attack Surface Discovery**

| Category | Tools | Purpose |
|----------|-------|---------|
| **Subdomain Enumeration** | `subfinder`, `amass` | Discover subdomains from multiple sources |
| **DNS Intelligence** | `dnsx`, `puredns`, `massdns`, `dig`, `dnsrecon` | DNS validation, bruteforce, resolution |
| **Port Scanning** | `nmap`, `naabu` | Service discovery, version detection |
| **HTTP Probing** | `httpx` | Fast HTTP probe with tech detection |

### **Web Application Assessment**

| Category | Tools | Purpose |
|----------|-------|---------|
| **Web Crawling** | `katana`, `gospider`, `waybackurls`, `gau` | Deep web app mapping, historical URLs |
| **Content Discovery** | `ffuf`, `gobuster`, `dirsearch` | Find hidden files, directories, endpoints |
| **Technology Detection** | `wappalyzer`, `WhatWeb`, `retire.js` | Identify frameworks, libraries, versions |
| **API Discovery** | `arjun` | Find API endpoints, discover parameters |

### **Security Analysis**

| Category | Tools | Purpose |
|----------|-------|---------|
| **Vulnerability Scanning** | `nuclei` | Template-based vulnerability detection |
| **SSL/TLS Analysis** | `tlsx`, `testssl.sh` | Certificate analysis, TLS configuration |
| **Secret Scanning** | `trufflehog` | Find exposed credentials and secrets |
| **Exploitation** | `sqlmap`, `searchsploit` (ExploitDB) | SQL injection, exploit database |

### **OSINT & Intelligence**

| Category | Tools | Purpose |
|----------|-------|---------|
| **OSINT** | `theHarvester`, `dnsrecon`, `python-whois` | Email discovery, data gathering, WHOIS lookups |
| **External APIs** | `shodan` | Search engine for Internet-connected devices |

### **Cloud & Infrastructure**

| Category | Tools | Purpose |
|----------|-------|---------|
| **Cloud Discovery** | `cloud_enum` | Find cloud resources (AWS, Azure, GCP) |
| **Cloud Security** | Azure CLI, ScoutSuite, ROADrecon | Cloud platform auditing |

### **Reporting & Utilities**

| Category | Tools | Purpose |
|----------|-------|---------|
| **PDF Generation** | `WeasyPrint`, `html2pdf` | Professional PDF reports |

## PDF Report Generation

Generate professional PDF reports from HTML in your n8n workflows using **WeasyPrint** - a Python-based PDF generator with full Unicode support.

### Features
- ✅ **Full Unicode support** - Emojis, CJK characters, special symbols
- ✅ **Professional fonts** - DejaVu, Liberation, Noto (including Noto CJK & Emoji)
- ✅ **No root required** - Safe for n8n workflows
- ✅ **CSS styling** - Full CSS support for custom layouts
- ✅ **Tables & code blocks** - Perfect for security reports

### Usage in n8n

**Execute Command node:**

```bash
# From HTML file
html2pdf /tmp/report.html /tmp/report.pdf

# From workflow variable (stdin)
echo '${{ $json.htmlContent }}' | html2pdf /tmp/report.pdf

# Direct Python usage with custom CSS
python3 -c "
from weasyprint import HTML, CSS
html = '''${{ $json.html }}'''
HTML(string=html).write_pdf('/tmp/report.pdf')
"
```

### Example Workflow: Security Report PDF

1. **Generate HTML Report** (Code node)
   ```javascript
   const findings = $input.all();
   const html = `
   <!DOCTYPE html>
   <html>
   <head>
     <meta charset="utf-8">
     <title>Security Assessment Report</title>
   </head>
   <body>
     <h1>Security Assessment Report</h1>
     <p>Target: ${findings[0].json.target}</p>
     <table>
       <tr><th>Severity</th><th>Finding</th><th>Count</th></tr>
       ${findings.map(f => `<tr>
         <td>${f.json.severity}</td>
         <td>${f.json.title}</td>
         <td>${f.json.count}</td>
       </tr>`).join('')}
     </table>
   </body>
   </html>
   `;
   return { html };
   ```

2. **Convert to PDF** (Execute Command)
   ```bash
   echo '${{ $json.html }}' | html2pdf /tmp/security-report.pdf
   ```

3. **Read PDF** (Read Binary File)
   - File path: `/tmp/security-report.pdf`

4. **Save/Send PDF**
   - Upload to MinIO
   - Email as attachment
   - Save to shared drive

### Advanced: Custom Styling

Create a styled report with custom CSS:

```python
from weasyprint import HTML, CSS

html = '''
<html>
<body>
  <h1>Vulnerability Report 🔒</h1>
  <p>Critical findings detected 🚨</p>
</body>
</html>
'''

custom_css = CSS(string='''
  @page {
    size: A4;
    margin: 2.5cm;
    @top-right { content: "Confidential"; }
  }
  body {
    font-family: 'Noto Sans', sans-serif;
    color: #333;
  }
  h1 { color: #c0392b; border-bottom: 2px solid #e74c3c; }
''')

HTML(string=html).write_pdf('/tmp/report.pdf', stylesheets=[custom_css])
```

### Available Fonts

The system includes comprehensive font support:
- **Sans-serif:** DejaVu Sans, Liberation Sans, Noto Sans
- **Serif:** DejaVu Serif, Liberation Serif, Noto Serif
- **Monospace:** DejaVu Sans Mono, Liberation Mono
- **CJK:** Noto Sans CJK (Chinese, Japanese, Korean)
- **Emoji:** Noto Color Emoji

Check available fonts:
```bash
docker exec n8n_recon_hub fc-list
```

## Enhanced Attack Surface Scanning Tools

The platform includes comprehensive attack surface management tools across all tiers.

### **Tier 1: Web Discovery & Crawling**

#### **katana** - Advanced Web Crawler
```bash
# Basic crawl
docker exec n8n_recon_hub katana -u https://target.com

# JS-aware crawling with depth 3
docker exec n8n_recon_hub katana -u https://target.com -jc -d 3 -silent

# Crawl with output
docker exec n8n_recon_hub katana -u https://target.com -o /tmp/urls.txt
```

#### **waybackurls** - Historical URL Discovery
```bash
# Get URLs from Wayback Machine
docker exec n8n_recon_hub waybackurls target.com > /tmp/historical-urls.txt

# Pipe to grep for interesting paths
docker exec n8n_recon_hub bash -c "waybackurls target.com | grep -i admin"
```

#### **gau** - GetAllUrls from Multiple Sources
```bash
# Fetch URLs from AlienVault, Wayback, Common Crawl
docker exec n8n_recon_hub gau target.com

# Filter by blacklist
docker exec n8n_recon_hub gau --blacklist png,jpg,gif target.com
```

#### **gospider** - Fast Web Spider
```bash
# Quick spider with depth 2
docker exec n8n_recon_hub gospider -s https://target.com -d 2 -c 10
```

### **Tier 1: DNS Intelligence**

#### **dnsx** - DNS Toolkit
```bash
# Resolve subdomains with A records
docker exec n8n_recon_hub dnsx -l subs.txt -a -resp

# Get CNAME records
docker exec n8n_recon_hub dnsx -l subs.txt -cname

# JSON output
docker exec n8n_recon_hub dnsx -l subs.txt -json -o /tmp/resolved.json
```

#### **puredns** - DNS Bruteforce & Validation
```bash
# Bruteforce subdomains
docker exec n8n_recon_hub puredns bruteforce /opt/SecLists/Discovery/DNS/subdomains-top1million-5000.txt target.com

# Resolve and validate
docker exec n8n_recon_hub puredns resolve subs.txt -r /etc/resolv.conf
```

### **Tier 1: Technology Detection**

#### **wappalyzer** - Technology Stack Fingerprinting
```bash
# Detect technologies
docker exec n8n_recon_hub wappalyzer https://target.com

# JSON output
docker exec n8n_recon_hub wappalyzer https://target.com --pretty
```

#### **WhatWeb** - Web Technology Identifier
```bash
# Aggressive scan
docker exec n8n_recon_hub whatweb -a 3 https://target.com

# Scan multiple URLs
docker exec n8n_recon_hub whatweb -i urls.txt
```

#### **retire.js** - Detect Vulnerable JavaScript Libraries
```bash
# Scan a directory
docker exec n8n_recon_hub retire --path /tmp/js-files

# Scan with verbose output
docker exec n8n_recon_hub retire --verbose --path /tmp/js
```

### **Tier 1: Content Discovery**

#### **ffuf** - Fast Web Fuzzer
```bash
# Directory fuzzing
docker exec n8n_recon_hub ffuf -u https://target.com/FUZZ -w /opt/SecLists/Discovery/Web-Content/common.txt

# Virtual host discovery
docker exec n8n_recon_hub ffuf -u https://target.com -H "Host: FUZZ.target.com" -w /opt/SecLists/Discovery/DNS/subdomains-top1million-5000.txt

# Parameter fuzzing
docker exec n8n_recon_hub ffuf -u https://target.com/api?FUZZ=value -w /opt/SecLists/Discovery/Web-Content/burp-parameter-names.txt
```

#### **feroxbuster** - Recursive Content Discovery
```bash
# Recursive scan
docker exec n8n_recon_hub feroxbuster -u https://target.com -w /opt/SecLists/Discovery/Web-Content/common.txt

# With extensions
docker exec n8n_recon_hub feroxbuster -u https://target.com -x php,asp,aspx,jsp -w wordlist.txt

# Rate limited
docker exec n8n_recon_hub feroxbuster -u https://target.com --rate-limit 10
```

#### **dirsearch** - Web Path Scanner
```bash
# Basic scan
docker exec n8n_recon_hub dirsearch -u https://target.com

# With extensions and threads
docker exec n8n_recon_hub dirsearch -u https://target.com -e php,asp,aspx -t 50

# Exclude status codes
docker exec n8n_recon_hub dirsearch -u https://target.com -x 403,404
```

### **Tier 2: API Discovery**

#### **kiterunner** - API Endpoint Discovery
```bash
# Scan API endpoints
docker exec n8n_recon_hub kr scan https://target.com/api -w /usr/local/share/kiterunner/routes.json

# Brute force
docker exec n8n_recon_hub kr brute https://target.com -w wordlist.txt
```

#### **arjun** - HTTP Parameter Discovery
```bash
# Discover GET parameters
docker exec n8n_recon_hub arjun -u https://target.com/api/user

# POST parameters
docker exec n8n_recon_hub arjun -u https://target.com/api/login -m POST

# Custom wordlist
docker exec n8n_recon_hub arjun -u https://target.com/api -w params.txt
```

### **Tier 2: SSL/TLS Analysis**

#### **tlsx** - TLS Data Extraction
```bash
# Get TLS info
docker exec n8n_recon_hub tlsx -u target.com -json

# Scan multiple hosts
docker exec n8n_recon_hub tlsx -l hosts.txt -san -cn -org

# Check certificate expiry
docker exec n8n_recon_hub tlsx -u target.com -expired
```

#### **testssl.sh** - Comprehensive SSL/TLS Testing
```bash
# Full test
docker exec n8n_recon_hub testssl --full https://target.com

# Check for vulnerabilities only
docker exec n8n_recon_hub testssl --vuln https://target.com

# JSON output
docker exec n8n_recon_hub testssl --jsonfile /tmp/ssl-results.json https://target.com
```

### **Tier 2: Visual Reconnaissance**

#### **gowitness** - Web Screenshot Utility
```bash
# Single URL screenshot
docker exec n8n_recon_hub gowitness single https://target.com

# Multiple URLs from file
docker exec n8n_recon_hub gowitness file -f urls.txt --screenshot-path /tmp/screenshots

# With report
docker exec n8n_recon_hub gowitness file -f urls.txt --write-db --db-path /tmp/gowitness.db
```

### **Tier 3: Cloud Discovery**

#### **cloud_enum** - Multi-Cloud OSINT Tool
```bash
# Enumerate cloud resources
docker exec n8n_recon_hub cloud_enum -k target

# Specific provider
docker exec n8n_recon_hub cloud_enum -k target --aws-only

# With output
docker exec n8n_recon_hub cloud_enum -k target -l /tmp/cloud-enum.txt
```

#### **S3Scanner** - S3 Bucket Scanner
```bash
# Scan single bucket
docker exec n8n_recon_hub S3Scanner scan -b target-bucket

# Scan from list
docker exec n8n_recon_hub S3Scanner scan -f buckets.txt

# Check for public access
docker exec n8n_recon_hub S3Scanner dump -b target-bucket -d /tmp/s3-dump
```

### **Using Tools in n8n Workflows**

**Execute Command Node Example:**

```bash
# Comprehensive subdomain discovery
subfinder -d target.com -silent | \
dnsx -silent -a -resp | \
httpx -silent -tech-detect -json | \
tee /tmp/live-hosts.json
```

**Code Node Example (Parse Results):**

```javascript
// Parse technology detection results
const results = JSON.parse($json.output);
const technologies = results.map(r => ({
  url: r.url,
  statusCode: r['status-code'],
  technologies: r.tech || [],
  server: r.webserver || 'unknown'
}));

return technologies;
```

### **Tool Combinations for Maximum Coverage**

#### **Complete Subdomain Discovery:**
```bash
# Combine multiple tools
subfinder -d target.com -silent > subs.txt
amass enum -passive -d target.com >> subs.txt
assetfinder --subs-only target.com >> subs.txt

# Validate and resolve
cat subs.txt | sort -u | dnsx -silent -a -resp > validated.txt
```

#### **Deep Web Application Mapping:**
```bash
# Crawl + historical + content discovery
katana -u https://target.com -silent > crawled.txt
waybackurls target.com >> crawled.txt
gau target.com >> crawled.txt

# Unique URLs
cat crawled.txt | sort -u > all-urls.txt

# Fuzz for hidden content
ffuf -u https://target.com/FUZZ -w wordlist.txt -mc 200,301,302
```

#### **API Comprehensive Assessment:**
```bash
# Discover + test APIs
kr scan https://target.com/api -w routes.json > endpoints.txt
arjun -u https://target.com/api/user -oJ params.json
nuclei -l endpoints.txt -t /root/nuclei-templates/http/
```

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
# Edit .env with your passwords and API keys
```

### 2. Launch the Stack

```bash
./setup.sh
# Or manually:
# docker-compose up --build -d
```

Build time: ~3-5 minutes

### 3. Pull Ollama Model

```bash
docker exec -it ollama ollama pull llama3.2:latest
```

### 4. Import & Activate the 4 Master Workflows

1. Open **http://localhost:5678**
2. Login with credentials from `.env`
3. **Workflows** → **Import from File**
4. Import these 4 files (in order):
   - ✅ `workflows/MASTER_01_intelligence_pipeline.json`
   - ✅ `workflows/MASTER_02_agent_orchestration.json`
   - ✅ `workflows/MASTER_03_execution_control.json`
   - ✅ `workflows/MASTER_04_ai_interface.json`
5. **Activate** each workflow (toggle switch to green)

### 5. Access Interfaces

```bash
# AI Chat Interface (Natural Language) ⭐ Recommended!
open http://localhost:8080/chat.html

# Simple Web UI (Form-based)
open http://localhost:8080/index.html

# n8n Dashboard
open http://localhost:5678
```

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
| `POST /webhook/pentest` | v1 - Legacy (no project) |
| `POST /webhook/pentest/v2` | v2 - Enterprise (rate limiting, audit) |
| `POST /webhook/pentest/v3` | v3 - Pivot capable (SSH tunnels) |
| `POST /webhook/pentest/v4/cloud` | v4 - Azure cloud scanning |
| `POST /webhook/evidence/upload` | Upload evidence files to MinIO |
| `POST /webhook/recon-scan` | Multi-phase database-driven scan |

### Enterprise Workflow (v2) - Requires project_id

```bash
# First create a project
docker exec -i recon_postgres psql -U recon_user -d recon_hub -c "
INSERT INTO projects (name, scope)
VALUES ('My Pentest', '[\"example.com\"]')
RETURNING id;"

# Then run scan with project_id
curl -X POST http://localhost/webhook/pentest/v2 \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "your-project-uuid-here",
    "target": "example.com",
    "mode": "standard"
  }'
```

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

## Claude Desktop Integration (Optional)

Connect Claude Desktop to your n8n instance via the Model Context Protocol (MCP) for AI-assisted workflow management.

### Benefits
- Ask Claude to list, analyze, and debug your workflows
- Build new workflows using natural language
- Query workflow executions and troubleshoot issues
- Get AI-powered suggestions for workflow optimization

### Quick Setup

1. **Generate n8n API Key**
   - Open http://localhost:5678
   - Settings → API → Create API Key
   - Copy the generated key

2. **Configure Claude Desktop**
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
           "N8N_API_KEY": "your_api_key_here"
         }
       }
     }
   }
   ```

   Config file location:
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
   - **Linux**: `~/.config/Claude/claude_desktop_config.json`

3. **Restart Claude Desktop** (Cmd+Q then reopen)

📖 **Full guide**: See [CLAUDE_DESKTOP_N8N_MCP_SETUP.md](CLAUDE_DESKTOP_N8N_MCP_SETUP.md)

## Security Notice

- Only use against **authorized targets**
- Webhook is publicly accessible on port 80
- Consider adding authentication for production
- Results may contain sensitive reconnaissance data
- Keep API keys secure in `.env` file
- **MCP Security**: Never commit `claude_desktop_config.json` with API keys to version control

## Enterprise Features (v2/v3/v4)

### Available Workflows

| Workflow | Purpose |
|----------|---------|
| `pentest_router_v2.json` | v2 - Enterprise scan with rate limiting, audit |
| `pentest_router_v3.json` | v3 - Pivot capable with SSH tunnel support |
| `pentest_v4_cloud.json` | v4 - Azure cloud security scanning |
| `pivot_orchestrator.json` | Auto-pivot management on SSH success |
| `credential_tester.json` | Test credentials (SSH/SMB/FTP), auto-queue pivots |
| `evidence_ingest.json` | Upload evidence to MinIO, queue for parsing |
| `nmap_parser.json` | Parse Nmap XML, upsert hosts/ports to database |
| `daily_housekeeping.json` | Expire old data, generate metrics, cleanup |
| `notification_sender.json` | Send alerts via Slack or database |

### Database Schema

**Phase A (Core):** projects, hosts, ports, evidence, scan_jobs, rate_limits, audit_log
**Phase B (Credentials):** secure_credentials, credential_usage, relationships, credential_test_queue
**Phase C (Findings):** findings, loot, enrichment, notifications, approval_queue
**Phase D (Pivoting):** ssh_tunnels, pivot_queue, internal_networks, proxy_chains
**Phase E (Cloud):** azure_tenants, azure_subscriptions, azure_resources, azure_ad_objects, azure_role_assignments, cloud_findings

### Pivot Capability (v3)

```bash
# Scan through an active SSH tunnel
curl -X POST http://localhost/webhook/pentest/v3 \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "your-project-uuid",
    "target": "10.0.0.1",
    "mode": "standard",
    "tunnel_id": "your-tunnel-uuid"
  }'
```

Features:
- Auto-pivot on SSH credential success
- Max 4 hops depth
- Tunnels persist until project ends
- Full internal recon through SOCKS proxies
- View tunnels: `SELECT * FROM active_tunnels;`

### Cloud Scanning (v4)

```bash
# Azure cloud security scan
curl -X POST http://localhost/webhook/pentest/v4/cloud \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "your-project-uuid",
    "tenant_id": "azure-tenant-guid",
    "credential_id": "credential-uuid",
    "scan_mode": "full-cloud"
  }'
```

**Cloud Scan Modes:**
| Mode | Description |
|------|-------------|
| `full-cloud` | Comprehensive scan (all checks) |
| `aad-enum` | Azure AD enumeration (users, groups, SPs) |
| `resource-discovery` | Find all Azure resources |
| `blob-scan` | Storage account scanning |
| `privilege-audit` | IAM misconfiguration check |
| `keyvault-access` | Key Vault permissions |
| `api-abuse` | Graph API testing |

**Cloud Tools:** Azure CLI, ScoutSuite, ROADrecon, msticpy

### Rate Limiting

- Max 3 concurrent scans per project
- 5-minute cooldown per target
- 100 credential tests per hour

### MinIO Console

Access at **http://localhost:9001** with credentials from CREDENTIALS.txt

Buckets: `raw-evidence`, `reports`

### Useful Commands

```bash
# Access MinIO console
open http://localhost:9001

# Check Redis
docker exec recon_redis redis-cli ping

# View project summary
docker exec -i recon_postgres psql -U recon_user -d recon_hub -c "SELECT * FROM project_summary;"

# View recent scans
docker exec -i recon_postgres psql -U recon_user -d recon_hub -c "SELECT * FROM recent_scan_jobs;"
```
