# Attack Surface Management Tools - Implementation Guide

**Date:** 2025-12-15
**Status:** ✅ Complete - Ready for Testing
**Workflow:** Advanced Attack Surface Scanner Enhancement

---

## 🎯 What Was Implemented

Comprehensive attack surface management (ASM) toolset spanning three tiers of capability:

- **Tier 1**: Essential web discovery, DNS intelligence, technology detection, and content discovery
- **Tier 2**: Advanced API discovery, SSL/TLS analysis, and visual reconnaissance
- **Tier 3**: Cloud infrastructure discovery and S3 bucket enumeration

**Total tools added:** 20+ specialized security tools for complete attack surface visibility

---

## 📦 Implementation Overview

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    n8n Workflow Engine                       │
│  (Advanced Attack Surface Scanner + Custom Workflows)       │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
    │ Tier 1  │    │ Tier 2  │    │ Tier 3  │
    │Essential│    │Advanced │    │ Cloud   │
    └─────────┘    └─────────┘    └─────────┘
         │               │               │
    ┌────▼────────────────▼───────────────▼────┐
    │         Docker Container (Alpine)         │
    │  /usr/local/bin/ (Go tools)              │
    │  /usr/bin/ (System tools)                │
    │  /opt/ (Cloned repos)                    │
    └──────────────────────────────────────────┘
```

---

## 🔧 Changes Made

### 1. Dockerfile Updates

**File:** `/Users/tester/Documents/n8n_stuff/Dockerfile`

#### Tier 1: Web Discovery & Crawling (Lines 192-199)

```dockerfile
# ============================================
# TIER 1: Web Discovery & Crawling Tools
# ============================================
RUN echo "Installing Tier 1: Web Discovery Tools..." && \
    go install github.com/projectdiscovery/katana/cmd/katana@latest && \
    go install github.com/tomnomnom/waybackurls@latest && \
    go install github.com/lc/gau/v2/cmd/gau@latest && \
    go install github.com/jaeles-project/gospider@latest
```

**Tools installed:**
- **katana**: Modern web crawler with JavaScript parsing
- **waybackurls**: Fetch all URLs from Wayback Machine
- **gau**: Get All URLs from AlienVault OTX, Wayback, Common Crawl
- **gospider**: Fast web spider for crawling

#### Tier 1: Enhanced DNS Tools (Lines 201-207)

```dockerfile
# ============================================
# TIER 1: Enhanced DNS Tools
# ============================================
RUN echo "Installing Tier 1: DNS Tools..." && \
    go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest && \
    go install github.com/d3mondev/puredns/v2@latest
```

**Tools installed:**
- **dnsx**: Fast DNS toolkit (validation, resolution, wildcard detection)
- **puredns**: Fast domain resolver with wildcard filtering

#### Tier 1: Technology Detection (Lines 209-215)

```dockerfile
# ============================================
# TIER 1: Technology Detection
# ============================================
RUN echo "Installing Tier 1: Technology Detection..." && \
    npm install -g wappalyzer retire && \
    apk add --no-cache ruby ruby-dev && \
    gem install WhatWeb
```

**Tools installed:**
- **wappalyzer**: Detect web technologies (frameworks, CMS, analytics)
- **retire**: Scan JavaScript libraries for known vulnerabilities
- **WhatWeb**: Web scanner identifying technologies, versions, email addresses

#### Tier 1: Content Discovery (Lines 217-223)

```dockerfile
# ============================================
# TIER 1: Content Discovery
# ============================================
RUN echo "Installing Tier 1: Content Discovery..." && \
    go install github.com/epi052/feroxbuster/v2@latest && \
    go install github.com/ffuf/ffuf/v2@latest && \
    pip3 install --no-cache-dir --break-system-packages dirsearch
```

**Tools installed:**
- **feroxbuster**: Fast content discovery with recursion
- **ffuf**: Fast web fuzzer (directories, parameters, vhosts)
- **dirsearch**: Python-based web path scanner

#### Tier 2: API Discovery (Lines 225-230)

```dockerfile
# ============================================
# TIER 2: API Discovery
# ============================================
RUN echo "Installing Tier 2: API Discovery..." && \
    go install github.com/assetnote/kiterunner/cmd/kr@latest && \
    pip3 install --no-cache-dir --break-system-packages arjun
```

**Tools installed:**
- **kiterunner**: API endpoint discovery using wordlists
- **arjun**: HTTP parameter discovery scanner

#### Tier 2: SSL/TLS Analysis (Lines 232-239)

```dockerfile
# ============================================
# TIER 2: SSL/TLS Analysis
# ============================================
RUN echo "Installing Tier 2: SSL/TLS Analysis..." && \
    go install github.com/projectdiscovery/tlsx/cmd/tlsx@latest && \
    git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl && \
    ln -s /opt/testssl/testssl.sh /usr/local/bin/testssl && \
    chmod +x /opt/testssl/testssl.sh
```

**Tools installed:**
- **tlsx**: Fast TLS data grabber (certificates, ciphers, chains)
- **testssl.sh**: Comprehensive SSL/TLS testing (protocols, ciphers, vulnerabilities)

#### Tier 2: Visual Reconnaissance (Lines 241-245)

```dockerfile
# ============================================
# TIER 2: Visual Reconnaissance
# ============================================
RUN echo "Installing Tier 2: Visual Recon..." && \
    go install github.com/sensepost/gowitness@latest
```

**Tools installed:**
- **gowitness**: Web screenshot utility using Chrome headless

#### Tier 3: Cloud Discovery (Lines 247-252)

```dockerfile
# ============================================
# TIER 3: Cloud Discovery
# ============================================
RUN echo "Installing Tier 3: Cloud Discovery..." && \
    pip3 install --no-cache-dir --break-system-packages cloud-enum && \
    go install github.com/sa7mon/S3Scanner/v3@latest
```

**Tools installed:**
- **cloud_enum**: Multi-cloud OSINT tool (AWS, Azure, GCP)
- **S3Scanner**: Scan for open AWS S3 buckets

#### Global Binary Installation (Line 254)

```dockerfile
# Copy all Go binaries to /usr/local/bin for global access
RUN cp /root/go/bin/* /usr/local/bin/ 2>/dev/null || true
```

**Why:** Ensures all Go-installed tools are available system-wide for n8n Execute Command nodes

---

### 2. setup.sh Updates

**File:** `/Users/tester/Documents/n8n_stuff/setup.sh`

#### Added Comprehensive Tool Verification (Lines 695-735)

```bash
echo ""
echo -e "${CYAN}=== Attack Surface Management Tools ===${NC}"
echo -e "${CYAN}Web Discovery & Crawling (Tier 1):${NC}"
docker compose exec -T n8n-recon bash -c "katana -version 2>&1 | head -1" && print_success "katana"
docker compose exec -T n8n-recon bash -c "which waybackurls" > /dev/null && print_success "waybackurls"
docker compose exec -T n8n-recon bash -c "which gau" > /dev/null && print_success "gau"
docker compose exec -T n8n-recon bash -c "which gospider" > /dev/null && print_success "gospider"

echo -e "${CYAN}Enhanced DNS Tools (Tier 1):${NC}"
docker compose exec -T n8n-recon bash -c "dnsx -version 2>&1 | head -1" && print_success "dnsx"
docker compose exec -T n8n-recon bash -c "puredns version 2>&1 | head -1" && print_success "puredns"

echo -e "${CYAN}Technology Detection (Tier 1):${NC}"
docker compose exec -T n8n-recon bash -c "which wappalyzer" > /dev/null && print_success "wappalyzer"
docker compose exec -T n8n-recon bash -c "which retire" > /dev/null && print_success "retire.js"
docker compose exec -T n8n-recon bash -c "whatweb --version 2>&1 | head -1" && print_success "WhatWeb"

echo -e "${CYAN}Content Discovery (Tier 1):${NC}"
docker compose exec -T n8n-recon bash -c "feroxbuster --version 2>&1 | head -1" && print_success "feroxbuster"
docker compose exec -T n8n-recon bash -c "ffuf -V 2>&1" && print_success "ffuf"
docker compose exec -T n8n-recon bash -c "dirsearch --version 2>&1 | head -1" && print_success "dirsearch"

echo -e "${CYAN}API Discovery (Tier 2):${NC}"
docker compose exec -T n8n-recon bash -c "which kr" > /dev/null && print_success "kiterunner"
docker compose exec -T n8n-recon bash -c "arjun --version 2>&1 | head -1" && print_success "arjun"

echo -e "${CYAN}SSL/TLS Analysis (Tier 2):${NC}"
docker compose exec -T n8n-recon bash -c "tlsx -version 2>&1 | head -1" && print_success "tlsx"
docker compose exec -T n8n-recon bash -c "testssl --version 2>&1 | head -1" && print_success "testssl.sh"

echo -e "${CYAN}Visual Reconnaissance (Tier 2):${NC}"
docker compose exec -T n8n-recon bash -c "gowitness version 2>&1 | head -1" && print_success "gowitness"

echo -e "${CYAN}Cloud Discovery (Tier 3):${NC}"
docker compose exec -T n8n-recon bash -c "cloud_enum --help 2>&1 | head -1" && print_success "cloud_enum"
docker compose exec -T n8n-recon bash -c "S3Scanner --version 2>&1 | head -1" && print_success "S3Scanner"
```

**Verifies:** All 20+ tools across all three tiers

#### Updated Final Info Display (Lines 771-785)

```bash
echo -e "  ${MAGENTA}Subdomain Enum:${NC}    subfinder, amass, assetfinder"
echo -e "  ${MAGENTA}DNS Tools:${NC}         dnsx, puredns, dig, dnsrecon"
echo -e "  ${MAGENTA}Web Crawling:${NC}      katana, gospider, waybackurls, gau"
echo -e "  ${MAGENTA}Content Discovery:${NC} ffuf, feroxbuster, dirsearch"
echo -e "  ${MAGENTA}Port Scanning:${NC}     nmap, masscan, naabu"
echo -e "  ${MAGENTA}Tech Detection:${NC}    wappalyzer, WhatWeb, retire.js"
echo -e "  ${MAGENTA}Vulnerability:${NC}     nuclei (with templates), nikto, wpscan, sqlmap"
echo -e "  ${MAGENTA}API Discovery:${NC}     kiterunner, arjun"
echo -e "  ${MAGENTA}SSL/TLS Analysis:${NC}  tlsx, testssl.sh"
echo -e "  ${MAGENTA}Screenshots:${NC}       gowitness"
echo -e "  ${MAGENTA}Cloud Discovery:${NC}   cloud_enum, S3Scanner, ScoutSuite"
echo -e "  ${MAGENTA}Azure Tools:${NC}       ROADtools, Azure CLI"
echo -e "  ${MAGENTA}Exploit Search:${NC}    searchsploit (ExploitDB)"
echo -e "  ${MAGENTA}Pivoting:${NC}          proxychains, sshpass, SSH tunnel support"
echo -e "  ${MAGENTA}PDF Generation:${NC}    WeasyPrint, html2pdf"
```

**Shows:** Complete categorized tool inventory

---

### 3. README.md Updates

**File:** `/Users/tester/Documents/n8n_stuff/README.md`

#### Reorganized Tools Table (Lines 191-232)

```markdown
### **Core Attack Surface Discovery**

| Category | Tools | Purpose |
|----------|-------|---------|
| **Subdomain Enumeration** | `subfinder`, `amass`, `assetfinder` | Discover subdomains via passive sources |
| **DNS Intelligence** | `dnsx`, `puredns`, `dig`, `dnsrecon` | DNS validation, resolution, bruteforce |
| **Web Crawling** | `katana`, `gospider`, `waybackurls`, `gau` | Map web applications, find historical URLs |
| **Content Discovery** | `ffuf`, `feroxbuster`, `dirsearch` | Enumerate directories, files, parameters |
| **Technology Detection** | `wappalyzer`, `WhatWeb`, `retire.js` | Identify frameworks, CMS, vulnerable libraries |
| **Port Scanning** | `nmap`, `masscan`, `naabu` | Network service discovery |
| **HTTP Probing** | `httpx` | Fast HTTP service verification |

### **Vulnerability Assessment**

| Category | Tools | Purpose |
|----------|-------|---------|
| **Automated Scanning** | `nuclei` (with templates) | Template-based vulnerability detection |
| **Web Scanners** | `nikto`, `wpscan`, `sqlmap` | Web server, WordPress, SQL injection testing |
| **API Discovery** | `kiterunner`, `arjun` | Discover API endpoints and parameters |
| **SSL/TLS Analysis** | `tlsx`, `testssl.sh` | Certificate analysis, cipher testing |
| **Visual Recon** | `gowitness` | Web application screenshots |

### **Cloud & Infrastructure**

| Category | Tools | Purpose |
|----------|-------|---------|
| **Cloud Discovery** | `cloud_enum`, `S3Scanner` | Find exposed cloud resources (AWS, Azure, GCP) |
| **Cloud Security** | `ScoutSuite` | Multi-cloud security auditing |
| **Azure Tools** | `ROADtools`, `Azure CLI` | Azure AD reconnaissance and management |

### **Utilities & Support**

| Category | Tools | Purpose |
|----------|-------|---------|
| **Exploit Research** | `searchsploit` | Search ExploitDB for known exploits |
| **Network Pivoting** | `proxychains`, `sshpass`, SSH tunnels | Route traffic through compromised hosts |
| **Report Generation** | `WeasyPrint`, `html2pdf` | Generate professional PDF reports |
```

#### Added Comprehensive Tool Documentation (Lines 352-633)

Detailed sections for each tool including:
- Purpose and use cases
- Command syntax
- Example commands for n8n Execute Command nodes
- Output format
- Integration tips

**Example structure:**

```markdown
### **Tier 1: Web Discovery & Crawling**

#### **katana** - Advanced Web Crawler

**Purpose:** Modern web crawler with JavaScript rendering support

**Usage in n8n:**
```bash
# Basic crawl with JSON output
docker exec n8n_recon_hub katana -u https://target.com -jc -d 3 -silent

# Crawl with custom headers and depth
docker exec n8n_recon_hub katana -u https://target.com \
  -H "User-Agent: CustomBot" -d 5 -jc -silent

# Crawl multiple domains from file
docker exec n8n_recon_hub katana -list /tmp/domains.txt -jc -silent
```

**Output:** JSON-lines format with discovered URLs, status codes, and metadata
```
[... continues for all tools ...]
```

---

## 🚀 How to Test

### Step 1: Rebuild Docker Image

```bash
cd /Users/tester/Documents/n8n_stuff

# Rebuild with all ASM tools
docker compose build n8n-recon

# Start the stack
docker compose up -d

# Wait for container to be healthy (2-3 minutes)
docker compose ps
```

**Expected build time:** +5-8 minutes for all tools (first build with cache)

---

### Step 2: Verify Installation

Run the setup.sh verification:

```bash
cd /Users/tester/Documents/n8n_stuff
./setup.sh
```

Or verify manually:

```bash
# Tier 1: Web Discovery
docker exec n8n_recon_hub katana -version
docker exec n8n_recon_hub waybackurls -h
docker exec n8n_recon_hub gau -h
docker exec n8n_recon_hub gospider -h

# Tier 1: DNS Tools
docker exec n8n_recon_hub dnsx -version
docker exec n8n_recon_hub puredns version

# Tier 1: Tech Detection
docker exec n8n_recon_hub wappalyzer --version
docker exec n8n_recon_hub retire --version
docker exec n8n_recon_hub whatweb --version

# Tier 1: Content Discovery
docker exec n8n_recon_hub feroxbuster --version
docker exec n8n_recon_hub ffuf -V
docker exec n8n_recon_hub dirsearch --version

# Tier 2: API Discovery
docker exec n8n_recon_hub kr --help
docker exec n8n_recon_hub arjun --version

# Tier 2: SSL/TLS
docker exec n8n_recon_hub tlsx -version
docker exec n8n_recon_hub testssl --version

# Tier 2: Screenshots
docker exec n8n_recon_hub gowitness version

# Tier 3: Cloud Discovery
docker exec n8n_recon_hub cloud_enum --help
docker exec n8n_recon_hub S3Scanner --version
```

---

### Step 3: Test Individual Tools

#### Test 1: Web Crawling (katana)

```bash
docker exec n8n_recon_hub katana -u https://example.com -jc -d 2 -silent
```

**Expected output:** JSON lines with discovered URLs

#### Test 2: DNS Resolution (dnsx)

```bash
echo "example.com" | docker exec -i n8n_recon_hub dnsx -silent -resp
```

**Expected output:** IP addresses for domain

#### Test 3: Technology Detection (wappalyzer)

```bash
docker exec n8n_recon_hub wappalyzer https://example.com
```

**Expected output:** Detected technologies in JSON format

#### Test 4: Content Discovery (ffuf)

```bash
docker exec n8n_recon_hub ffuf -u https://example.com/FUZZ \
  -w /usr/share/seclists/Discovery/Web-Content/common.txt \
  -mc 200 -t 10
```

**Expected output:** Found directories/files with 200 status

#### Test 5: SSL/TLS Analysis (tlsx)

```bash
echo "example.com:443" | docker exec -i n8n_recon_hub tlsx -silent -json
```

**Expected output:** SSL certificate details in JSON

#### Test 6: Cloud Enumeration (cloud_enum)

```bash
docker exec n8n_recon_hub cloud_enum -k example -l /tmp/cloud_enum.log
```

**Expected output:** Discovered cloud resources

---

## 🔧 Using in n8n Workflows

### Example: Enhanced Attack Surface Scanner Workflow

**Workflow Structure:**

```
1. [Webhook/Schedule] - Trigger
      ↓
2. [Code: Parse Target] - Extract domain
      ↓
3. [Execute: Subdomain Enum] - subfinder + amass
      ↓
4. [Execute: DNS Validation] - dnsx
      ↓
5. [Execute: Web Crawling] - katana
      ↓
6. [Execute: Tech Detection] - wappalyzer
      ↓
7. [Execute: Content Discovery] - ffuf
      ↓
8. [Execute: API Discovery] - kiterunner
      ↓
9. [Execute: SSL Analysis] - tlsx
      ↓
10. [Execute: Screenshots] - gowitness
      ↓
11. [Execute: Cloud Discovery] - cloud_enum
      ↓
12. [Code: Aggregate Results] - Merge all findings
      ↓
13. [Code: Generate HTML Report] - Format results
      ↓
14. [Execute: Create PDF] - html2pdf
      ↓
15. [Upload to MinIO/Email] - Deliver report
```

---

### Node 3: Subdomain Enumeration

**Execute Command Node:**

```bash
# Combine subfinder and amass results
subfinder -d ${{ $json.domain }} -silent -all | tee /tmp/subdomains_subfinder.txt
amass enum -passive -d ${{ $json.domain }} -o /tmp/subdomains_amass.txt
cat /tmp/subdomains_*.txt | sort -u > /tmp/all_subdomains.txt
cat /tmp/all_subdomains.txt
```

**Output handling:** Parse stdout as line-separated subdomains

---

### Node 4: DNS Validation

**Execute Command Node:**

```bash
# Validate discovered subdomains with dnsx
cat /tmp/all_subdomains.txt | dnsx -silent -resp -json
```

**Output:** JSON objects with domain, A records, AAAA records, CNAME

**Code Node (Parse Results):**

```javascript
const input = $input.item.json.stdout;
const lines = input.trim().split('\n');
const validDomains = lines.map(line => JSON.parse(line));

return validDomains.map(d => ({
  domain: d.host,
  ips: d.a || [],
  ipv6: d.aaaa || [],
  cname: d.cname || []
}));
```

---

### Node 5: Web Crawling

**Execute Command Node:**

```bash
# Crawl all discovered subdomains
cat /tmp/all_subdomains.txt | while read domain; do
  echo "https://$domain"
done | katana -jc -d 3 -silent -timeout 30
```

**Output:** JSON-lines with URLs, titles, status codes

---

### Node 6: Technology Detection

**Execute Command Node:**

```bash
# Detect technologies for all live domains
cat /tmp/all_subdomains.txt | while read domain; do
  wappalyzer "https://$domain" 2>/dev/null || echo "{}"
done | jq -s '.'
```

**Output:** JSON array of detected technologies per domain

---

### Node 7: Content Discovery

**Execute Command Node:**

```bash
# Fuzz common paths on main domain
ffuf -u https://${{ $json.domain }}/FUZZ \
  -w /usr/share/seclists/Discovery/Web-Content/common.txt \
  -mc 200,204,301,302,307,401,403 \
  -t 20 -o /tmp/ffuf_results.json -of json -silent

cat /tmp/ffuf_results.json
```

**Output:** JSON with discovered paths and status codes

---

### Node 8: API Discovery

**Execute Command Node:**

```bash
# Discover API endpoints with kiterunner
kr scan https://${{ $json.domain }} \
  -w /usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt \
  -x 20 --fail-status-codes 404 -j /tmp/kr_results.json

cat /tmp/kr_results.json
```

**Output:** JSON with API endpoints and response codes

---

### Node 9: SSL/TLS Analysis

**Execute Command Node:**

```bash
# Analyze SSL certificates for all domains
cat /tmp/all_subdomains.txt | while read domain; do
  echo "$domain:443"
done | tlsx -silent -json
```

**Output:** JSON with certificate details, SANs, expiry, ciphers

---

### Node 10: Screenshots

**Execute Command Node:**

```bash
# Capture screenshots of all live web services
cat /tmp/all_subdomains.txt | while read domain; do
  echo "https://$domain"
done | gowitness file -f - --screenshot-path /opt/loot/screenshots/ \
  --db-path /opt/loot/gowitness.db --write-db
```

**Output:** Screenshots saved to `/opt/loot/screenshots/`, database at `/opt/loot/gowitness.db`

---

### Node 11: Cloud Discovery

**Execute Command Node:**

```bash
# Enumerate cloud resources based on target organization
cloud_enum -k ${{ $json.orgname }} -l /tmp/cloud_enum.log --disable-azure --disable-gcp

# Also scan for S3 buckets
S3Scanner --bucket-file /tmp/potential_buckets.txt --out-file /tmp/s3_results.json
```

**Output:** Discovered cloud resources with accessibility status

---

### Node 12: Aggregate Results (Code Node)

```javascript
// Aggregate all findings from previous nodes
const target = $('Code').item.json.domain;
const subdomains = $('Execute Command 1').all().map(i => i.json.stdout.split('\n')).flat();
const dnsRecords = $('Execute Command 2').all().map(i => JSON.parse(i.json.stdout));
const crawledUrls = $('Execute Command 3').all().map(i => i.json.stdout.split('\n').map(l => JSON.parse(l))).flat();
const technologies = JSON.parse($('Execute Command 4').item.json.stdout);
const contentPaths = JSON.parse($('Execute Command 5').item.json.stdout).results;
const apiEndpoints = JSON.parse($('Execute Command 6').item.json.stdout);
const sslData = $('Execute Command 7').all().map(i => i.json.stdout.split('\n').map(l => JSON.parse(l))).flat();
const cloudResources = $('Execute Command 8').item.json.stdout.split('\n');

return {
  target,
  scan_date: new Date().toISOString(),
  summary: {
    subdomains_found: subdomains.length,
    urls_discovered: crawledUrls.length,
    technologies_detected: technologies.length,
    api_endpoints: apiEndpoints.length,
    cloud_resources: cloudResources.length
  },
  findings: {
    subdomains,
    dns: dnsRecords,
    urls: crawledUrls,
    technologies,
    content: contentPaths,
    apis: apiEndpoints,
    ssl: sslData,
    cloud: cloudResources
  }
};
```

---

### Node 13: Generate HTML Report (Code Node)

```javascript
const data = $input.item.json;

const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Attack Surface Assessment - ${data.target}</title>
  <style>
    body { font-family: 'DejaVu Sans', sans-serif; margin: 0; padding: 20px; }
    h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
    h2 { color: #34495e; margin-top: 30px; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
    th { background-color: #34495e; color: white; }
    .summary { background: #ecf0f1; padding: 15px; border-radius: 5px; margin: 20px 0; }
    .critical { background-color: #e74c3c; color: white; }
    .high { background-color: #e67e22; color: white; }
    .medium { background-color: #f39c12; }
    .low { background-color: #3498db; color: white; }
    .info { background-color: #95a5a6; color: white; }
    code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
  </style>
</head>
<body>
  <h1>🔒 Attack Surface Assessment Report</h1>

  <div class="summary">
    <h3>Executive Summary</h3>
    <p><strong>Target:</strong> ${data.target}</p>
    <p><strong>Scan Date:</strong> ${new Date(data.scan_date).toLocaleString()}</p>
    <p><strong>Subdomains Discovered:</strong> ${data.summary.subdomains_found}</p>
    <p><strong>URLs Mapped:</strong> ${data.summary.urls_discovered}</p>
    <p><strong>Technologies Identified:</strong> ${data.summary.technologies_detected}</p>
    <p><strong>API Endpoints Found:</strong> ${data.summary.api_endpoints}</p>
    <p><strong>Cloud Resources:</strong> ${data.summary.cloud_resources}</p>
  </div>

  <h2>📊 Subdomain Enumeration</h2>
  <table>
    <tr><th>#</th><th>Subdomain</th></tr>
    ${data.findings.subdomains.slice(0, 50).map((sub, i) => `
    <tr><td>${i+1}</td><td><code>${sub}</code></td></tr>
    `).join('')}
    ${data.findings.subdomains.length > 50 ? `<tr><td colspan="2"><em>... and ${data.findings.subdomains.length - 50} more</em></td></tr>` : ''}
  </table>

  <h2>🌐 DNS Records</h2>
  <table>
    <tr><th>Domain</th><th>A Records</th><th>CNAME</th></tr>
    ${data.findings.dns.slice(0, 30).map(d => `
    <tr>
      <td><code>${d.domain}</code></td>
      <td>${(d.ips || []).join(', ') || 'N/A'}</td>
      <td>${(d.cname || []).join(', ') || 'N/A'}</td>
    </tr>
    `).join('')}
  </table>

  <h2>💻 Detected Technologies</h2>
  <table>
    <tr><th>Domain</th><th>Technology</th><th>Version</th><th>Category</th></tr>
    ${data.findings.technologies.slice(0, 50).map(t => `
    <tr>
      <td><code>${t.url || 'N/A'}</code></td>
      <td>${t.technology || 'N/A'}</td>
      <td>${t.version || 'N/A'}</td>
      <td>${t.category || 'N/A'}</td>
    </tr>
    `).join('')}
  </table>

  <h2>🔍 Discovered Content</h2>
  <table>
    <tr><th>URL</th><th>Status</th><th>Size</th></tr>
    ${data.findings.content.slice(0, 50).map(c => `
    <tr>
      <td><code>${c.url}</code></td>
      <td>${c.status}</td>
      <td>${c.length} bytes</td>
    </tr>
    `).join('')}
  </table>

  <h2>🔌 API Endpoints</h2>
  <table>
    <tr><th>Endpoint</th><th>Method</th><th>Status</th></tr>
    ${data.findings.apis.slice(0, 30).map(api => `
    <tr>
      <td><code>${api.url || api.endpoint}</code></td>
      <td>${api.method || 'GET'}</td>
      <td>${api.status || 'N/A'}</td>
    </tr>
    `).join('')}
  </table>

  <h2>🔐 SSL/TLS Analysis</h2>
  <table>
    <tr><th>Domain</th><th>Issuer</th><th>Valid Until</th><th>SANs</th></tr>
    ${data.findings.ssl.slice(0, 30).map(ssl => `
    <tr>
      <td><code>${ssl.host}</code></td>
      <td>${ssl.issuer_cn || 'N/A'}</td>
      <td>${ssl.not_after || 'N/A'}</td>
      <td>${(ssl.subject_an || []).length} domains</td>
    </tr>
    `).join('')}
  </table>

  <h2>☁️ Cloud Resources</h2>
  <table>
    <tr><th>Resource</th><th>Type</th></tr>
    ${data.findings.cloud.slice(0, 30).map(cloud => `
    <tr>
      <td><code>${cloud}</code></td>
      <td>Cloud Storage/Service</td>
    </tr>
    `).join('')}
  </table>

  <hr>
  <p><em>Generated by n8n Autonomous Pentesting Platform - ${new Date().toLocaleString()}</em></p>
  <p><em>⚠️ CONFIDENTIAL - For Authorized Security Assessment Only</em></p>
</body>
</html>
`;

return { html, timestamp: Date.now(), target: data.target };
```

---

### Node 14: Generate PDF Report

**Execute Command Node:**

```bash
echo '${{ $json.html }}' | html2pdf /tmp/attack_surface_report_${{ $json.timestamp }}.pdf
```

---

### Node 15: Deliver Report

**Multiple options:**

**A. Upload to MinIO (S3-compatible storage):**
- Use "AWS S3" node
- Select "Upload" operation
- File path: `/tmp/attack_surface_report_${{ $('Code 2').item.json.timestamp }}.pdf`

**B. Email Report:**
- Use "Send Email" node
- Attach file from `/tmp/attack_surface_report_*.pdf`

**C. Save to workspace:**
```bash
cp /tmp/attack_surface_report_${{ $json.timestamp }}.pdf /opt/loot/reports/
```

---

## 📊 Tool Usage Reference

### Quick Command Cheatsheet

**Subdomain Enumeration:**
```bash
subfinder -d target.com -silent -all
amass enum -passive -d target.com
```

**DNS Validation:**
```bash
echo "domain.com" | dnsx -silent -resp -json
puredns resolve domains.txt -r /usr/share/resolvers.txt
```

**Web Crawling:**
```bash
katana -u https://target.com -jc -d 3 -silent
gospider -s https://target.com -d 2 -c 10 -t 20
waybackurls target.com
gau target.com
```

**Content Discovery:**
```bash
ffuf -u https://target.com/FUZZ -w wordlist.txt -mc 200
feroxbuster -u https://target.com -w wordlist.txt -t 50
dirsearch -u https://target.com -w wordlist.txt -t 30
```

**Technology Detection:**
```bash
wappalyzer https://target.com
whatweb https://target.com -a 3
retire --js https://target.com
```

**API Discovery:**
```bash
kr scan https://target.com -w api-wordlist.txt -x 20
arjun -u https://target.com/api/endpoint
```

**SSL/TLS Analysis:**
```bash
echo "target.com:443" | tlsx -silent -json
testssl https://target.com
```

**Screenshots:**
```bash
gowitness single https://target.com
```

**Cloud Discovery:**
```bash
cloud_enum -k targetorg
S3Scanner --bucket targetorg-backups
```

---

## 🔍 Troubleshooting

### Issue: "command not found" for Go tools

**Cause:** Go binaries not in PATH or not copied to `/usr/local/bin/`

**Fix:**
```bash
# Check if binaries exist
docker exec n8n_recon_hub ls /root/go/bin/

# Manual copy if needed
docker exec n8n_recon_hub cp /root/go/bin/* /usr/local/bin/

# Verify PATH
docker exec n8n_recon_hub echo $PATH
```

---

### Issue: "wappalyzer: not found"

**Cause:** npm global packages not in PATH

**Fix:**
```bash
# Check npm global path
docker exec n8n_recon_hub npm root -g

# Verify installation
docker exec n8n_recon_hub npm list -g wappalyzer
```

---

### Issue: "Permission denied" when running tools

**Cause:** Tool not executable or running as wrong user

**Fix:**
```bash
# Check permissions
docker exec n8n_recon_hub ls -la /usr/local/bin/testssl

# Make executable
docker exec n8n_recon_hub chmod +x /usr/local/bin/testssl

# Check current user in Execute Command node
docker exec n8n_recon_hub whoami
# Should be: node
```

---

### Issue: Tools hanging or timing out

**Cause:** Network restrictions, rate limiting, or tool-specific timeouts

**Fix:**
```bash
# Add timeout to all commands
timeout 60 katana -u https://target.com -d 2

# Reduce concurrency
ffuf -u https://target.com/FUZZ -w wordlist.txt -t 5 -rate 10

# Use delays between requests
nuclei -u https://target.com -rl 50
```

---

### Issue: SecLists wordlists missing

**Cause:** SecLists not installed in container

**Fix:**
```bash
# Install SecLists manually
docker exec n8n_recon_hub git clone --depth 1 \
  https://github.com/danielmiessler/SecLists.git /usr/share/seclists

# Use smaller, built-in wordlists
ffuf -u https://target.com/FUZZ -w /usr/share/wordlists/dirb/common.txt
```

---

### Issue: Cloud tools require credentials

**Cause:** cloud_enum and S3Scanner may need AWS credentials for authenticated enumeration

**Fix:**
```bash
# For unauthenticated scans, ensure no AWS creds are set
docker exec n8n_recon_hub env | grep AWS
# Should be empty

# For authenticated scans, add to docker-compose.yml:
environment:
  - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
  - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
```

---

## 📈 Performance Optimization

### Resource Usage

**Expected CPU/Memory per tool:**
- **Light:** subfinder, dnsx, waybackurls (50-100MB RAM)
- **Medium:** katana, ffuf, feroxbuster (100-300MB RAM)
- **Heavy:** amass, nuclei, gowitness (300MB-1GB RAM)
- **Very Heavy:** testssl.sh (complex scans can use 1-2GB RAM)

### Workflow Optimization Tips

1. **Parallelize independent tasks:**
   - Run subdomain enum and DNS validation in parallel
   - Crawl multiple subdomains concurrently

2. **Use rate limiting:**
   ```bash
   # Example: Limit ffuf to 50 requests/second
   ffuf -u https://target.com/FUZZ -w wordlist.txt -rate 50
   ```

3. **Filter early:**
   - Use dnsx to filter dead domains before crawling
   - Use httpx to validate HTTP services before fuzzing

4. **Cache results:**
   - Save intermediate results to `/tmp/` files
   - Reuse subdomain lists across multiple scans

5. **Optimize wordlists:**
   - Use targeted wordlists instead of comprehensive ones
   - Create custom wordlists based on target context

---

## ✅ Verification Checklist

After rebuilding:

- [ ] Container builds successfully without errors
- [ ] All Tier 1 tools installed and executable
- [ ] All Tier 2 tools installed and executable
- [ ] All Tier 3 tools installed and executable
- [ ] Go binaries accessible from `/usr/local/bin/`
- [ ] npm global packages (wappalyzer, retire) work
- [ ] Ruby gems (WhatWeb) accessible
- [ ] Python packages (dirsearch, arjun, cloud_enum) work
- [ ] testssl.sh symlink created and executable
- [ ] n8n Execute Command nodes can run all tools
- [ ] Sample scans complete without errors
- [ ] Results parse correctly in n8n Code nodes

---

## 🎯 Next Steps

1. **Rebuild your container:**
   ```bash
   cd /Users/tester/Documents/n8n_stuff
   docker compose build n8n-recon
   docker compose up -d
   ```

2. **Run verification:**
   ```bash
   ./setup.sh
   ```

3. **Test individual tools** using examples from "Step 3: Test Individual Tools"

4. **Import/Update "Advanced Attack Surface Scanner" workflow** in n8n

5. **Customize workflow** based on your specific targets and requirements

6. **Create custom wordlists** for your target's technology stack

7. **Set up automated scheduling** for continuous attack surface monitoring

---

## 📚 Additional Resources

### Official Documentation

- **ProjectDiscovery:** https://docs.projectdiscovery.io/
- **OWASP Amass:** https://github.com/owasp-amass/amass/blob/master/doc/user_guide.md
- **ffuf:** https://github.com/ffuf/ffuf
- **testssl.sh:** https://testssl.sh/
- **cloud_enum:** https://github.com/initstring/cloud_enum

### Tool Collections

- **SecLists:** https://github.com/danielmiessler/SecLists (wordlists)
- **Nuclei Templates:** https://github.com/projectdiscovery/nuclei-templates
- **PayloadsAllTheThings:** https://github.com/swisskyrepo/PayloadsAllTheThings

### Learning Resources

- **Bug Bounty Methodology:** https://www.bugcrowd.com/hackers/bugcrowd-university/
- **Attack Surface Management:** https://owasp.org/www-community/attacks/
- **n8n Workflow Examples:** https://n8n.io/workflows/

---

**Implementation complete! Ready for testing.** 🚀
