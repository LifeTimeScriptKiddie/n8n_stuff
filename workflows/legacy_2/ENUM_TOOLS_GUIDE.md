# Enumeration Tools Workflows Guide

This guide covers the enumeration tool workflows created for your n8n setup. All workflows run **without root privileges** and work with your existing Docker container setup.

## Available Workflows

### 1. **nmap.json** - Network Port Scanner
**Purpose:** Comprehensive port scanning with CVE vulnerability enrichment

**Command Pattern:**
```bash
nmap -sT -sV -sC -p- -T4 --min-parallelism 40 --max-parallelism 250 --max-retries 2 -oX /tmp/nmap_[timestamp].xml [target]
```

**Features:**
- Full port scan (-p-)
- Service/version detection (-sV -sC)
- TCP connect scan (-sT, no root required)
- CVE enrichment via NVD API
- Password-protected PDF reports
- Email/Telegram distribution

**Input:**
```json
{
  "network": "10.129.138.155"  // or "192.168.1.0/24" or "scanme.nmap.org"
}
```

**Triggers:** Webhook, Form, Manual, Scheduled

---

### 2. **subfinder.json** - Subdomain Enumeration
**Purpose:** Discover subdomains using passive reconnaissance

**Command Pattern:**
```bash
subfinder -d [domain] -silent -o /tmp/subfinder_[timestamp].txt
```

**Features:**
- Passive subdomain discovery
- Multiple public data sources
- JSON output with timestamps
- HTML report generation
- Fast execution (no DNS queries)

**Input:**
```json
{
  "domain": "example.com"
}
```

**Output:**
- List of discovered subdomains
- Source attribution
- Total count statistics

---

### 3. **httpx.json** - HTTP Service Probe
**Purpose:** Probe HTTP/HTTPS services for detailed information

**Command Pattern:**
```bash
httpx -l [input_file] -silent -json -status-code -title -tech-detect -web-server -method -ip -cname -cdn -location -content-length -threads 50
```

**Features:**
- Status code detection
- Technology identification
- CDN detection
- Web server fingerprinting
- Title extraction
- IP resolution

**Input:**
```json
{
  "target": "https://example.com"  // Single URL
}
```

Or multiple targets (newline separated):
```json
{
  "target": "https://example.com\nhttps://api.example.com\nhttps://admin.example.com"
}
```

**Use Case:** Perfect for probing subfinder results

---

### 4. **nuclei.json** - Vulnerability Scanner
**Purpose:** Automated vulnerability detection using templates

**Command Pattern:**
```bash
nuclei -l [input_file] -severity critical,high,medium -json -silent -stats -o /tmp/nuclei_output_[timestamp].json
```

**Features:**
- 5000+ vulnerability templates
- Severity filtering (critical/high/medium/low/info)
- Tag-based filtering
- CVE detection
- Misconfigurations
- Exposed panels

**Input:**
```json
{
  "target": "https://example.com",
  "severity": "critical,high,medium",  // Optional, default: "critical,high,medium"
  "tags": "cve,exposure"               // Optional, filter by tags
}
```

**Use Case:** Run against httpx results for comprehensive vuln scanning

---

### 5. **amass.json** - Network Mapping
**Purpose:** Comprehensive subdomain enumeration with DNS intelligence

**Command Pattern:**
```bash
# Passive mode
amass enum -passive -d [domain] -json /tmp/amass_[timestamp]/output.json

# Active mode
amass enum -d [domain] -json /tmp/amass_[timestamp]/output.json
```

**Features:**
- Passive mode: Fast, external sources only
- Active mode: Comprehensive with DNS queries
- IP resolution
- Source tracking
- OSINT integration

**Input:**
```json
{
  "domain": "example.com",
  "mode": "passive"  // or "active"
}
```

**Comparison with Subfinder:**
- **Subfinder:** Fast, passive only, simple output
- **Amass:** More comprehensive, includes DNS intelligence, slower

---

## Typical Recon Workflow Chain

Here's a recommended workflow sequence for comprehensive reconnaissance:

```
1. Subfinder/Amass (Subdomain Discovery)
   ↓
2. httpx (Probe Live Services)
   ↓
3. Nuclei (Vulnerability Scanning)
   ↓
4. nmap (Port Scanning for interesting targets)
```

### Example: Full Domain Recon

**Step 1: Discover Subdomains**
```bash
# Via webhook
curl -X POST http://localhost:5678/webhook/subfinder \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com"}'
```

**Step 2: Probe HTTP Services**
```bash
# Take subfinder output, feed to httpx
curl -X POST http://localhost:5678/webhook/httpx \
  -H "Content-Type: application/json" \
  -d '{"target": "sub1.example.com\nsub2.example.com\nsub3.example.com"}'
```

**Step 3: Scan for Vulnerabilities**
```bash
# Take live services, scan with nuclei
curl -X POST http://localhost:5678/webhook/nuclei \
  -H "Content-Type: application/json" \
  -d '{"target": "https://sub1.example.com", "severity": "critical,high"}'
```

**Step 4: Deep Port Scan**
```bash
# For interesting targets, run nmap
curl -X POST http://localhost:5678/webhook/vuln-scan \
  -H "Content-Type: application/json" \
  -d '{"network": "10.0.1.50"}'
```

---

## Common Patterns

### All Workflows Support:
✅ **Webhook triggers** - For API automation
✅ **Manual triggers** - For testing in n8n UI
✅ **JSON output** - Structured data for processing
✅ **HTML reports** - Professional formatted results
✅ **Timestamp tracking** - Unique filenames per run
✅ **Non-root execution** - Works in your Docker setup

### Output Locations
All tools write to `/tmp/` inside the container:
- Raw results: `/tmp/[tool]_[timestamp].{txt,json,xml}`
- Parsed JSON: `/tmp/[tool]_parsed_[timestamp].json`
- HTML reports: `/tmp/[tool]_report_[timestamp].html`

---

## Tool Selection Guide

| Tool | Speed | Depth | Use Case |
|------|-------|-------|----------|
| **Subfinder** | ⚡⚡⚡ Fast | 🔍 Surface | Quick subdomain discovery |
| **Amass** | ⚡⚡ Moderate | 🔍🔍 Deep | Comprehensive subdomain intel |
| **httpx** | ⚡⚡⚡ Fast | 🔍 Surface | HTTP service enumeration |
| **Nuclei** | ⚡⚡ Moderate | 🔍🔍🔍 Deep | Vulnerability detection |
| **nmap** | ⚡ Slow | 🔍🔍🔍 Deep | Port/service/CVE scanning |

---

## Webhook URLs

After importing workflows, your webhooks will be:

- **nmap:** `http://localhost:5678/webhook/vuln-scan`
- **Subfinder:** `http://localhost:5678/webhook/subfinder`
- **httpx:** `http://localhost:5678/webhook/httpx`
- **Nuclei:** `http://localhost:5678/webhook/nuclei`
- **Amass:** `http://localhost:5678/webhook/amass`

---

## Importing Workflows

```bash
# Import all workflows
cd /Users/tester/Documents/n8n_stuff/workflows/

# Import via n8n UI (recommended)
# 1. Open n8n at http://localhost:5678
# 2. Click "+" → "Import from file"
# 3. Select workflow JSON files

# Or via CLI (if available)
docker exec n8n_recon_hub n8n import:workflow --input=/data/workflows/subfinder.json
docker exec n8n_recon_hub n8n import:workflow --input=/data/workflows/httpx.json
docker exec n8n_recon_hub n8n import:workflow --input=/data/workflows/nuclei.json
docker exec n8n_recon_hub n8n import:workflow --input=/data/workflows/amass.json
```

---

## Troubleshooting

### Issue: "Command not found"
**Solution:** Verify tool is in Dockerfile and container is rebuilt
```bash
docker exec n8n_recon_hub which [tool-name]
```

### Issue: "Permission denied"
**Solution:** These workflows run as `node` user (non-root) - this is by design
- Use `-sT` instead of `-sS` for nmap (TCP connect vs SYN)
- Don't use sudo or elevated commands

### Issue: "No results found"
**Solution:** Check tool-specific issues:
- **Subfinder:** Domain may not have public subdomain data
- **httpx:** Targets may be down or blocking requests
- **Nuclei:** Templates may not match target
- **Amass:** Passive mode has limited sources

---

## Next Steps

1. **Import all workflows** into n8n
2. **Test with manual triggers** first
3. **Chain workflows** together for automated recon
4. **Integrate with your AI agents** via webhooks
5. **Schedule periodic scans** using Schedule Trigger nodes

---

## Notes

- All tools respect rate limits and are safe for authorized testing
- CVE enrichment (nmap) uses NVD API with 1-second delays
- Reports are saved to `/tmp` and can be exported as needed
- Consider adding database storage for long-term result tracking
