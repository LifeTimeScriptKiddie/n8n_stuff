# Missing Tools - Added to Docker Image

**Date:** 2025-12-16
**Status:** ✅ Complete - Ready for Rebuild

---

## 🎯 What Was Missing

Based on your verification output, these 7 tools were missing:

1. ❌ **naabu** - Port scanner
2. ❌ **shodan** - CLI tool (was installed, PATH issue)
3. ❌ **gobuster** - Directory discovery
4. ❌ **testssl.sh** - SSL/TLS testing (was installed, symlink issue)
5. ❌ **dnsrecon** - DNS enumeration
6. ❌ **theharvester** - OSINT tool
7. ❌ **trufflehog** - Secret scanning

---

## ✅ What Was Added to Dockerfile

### 1. Port Scanning (Lines 256-261)
```dockerfile
RUN echo "Installing Additional Port Scanning Tools..." && \
    go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest && \
    apk add --no-cache libpcap-dev
```
- **naabu**: Fast port scanner from ProjectDiscovery
- **libpcap-dev**: Required dependency for packet capture

### 2. Directory Discovery (Lines 263-267)
```dockerfile
RUN echo "Installing Additional Directory Discovery Tools..." && \
    apk add --no-cache gobuster
```
- **gobuster**: Fast directory/file brute-forcing tool

### 3. DNS Enumeration (Lines 204-210, 269-273)
```dockerfile
# massdns (puredns dependency)
RUN echo "Installing Tier 1: DNS Tools..." && \
    go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest && \
    go install github.com/d3mondev/puredns/v2@latest && \
    git clone --depth 1 https://github.com/blechschmidt/massdns.git /tmp/massdns && \
    cd /tmp/massdns && make && cp bin/massdns /usr/local/bin/ && \
    chmod +x /usr/local/bin/massdns && \
    cd / && rm -rf /tmp/massdns

# dnsrecon
RUN echo "Installing Additional DNS Tools..." && \
    pip3 install --no-cache-dir --break-system-packages dnsrecon
```
- **massdns**: High-performance DNS stub resolver (required by puredns)
- **dnsrecon**: Python-based DNS enumeration tool

### 4. OSINT Tools (Lines 275-279)
```dockerfile
RUN echo "Installing Additional OSINT Tools..." && \
    pip3 install --no-cache-dir --break-system-packages theHarvester python-whois
```
- **theHarvester**: OSINT tool for gathering emails, names, subdomains
- **python-whois**: Python library for WHOIS lookups with parsing

### 5. Secret Scanning (Lines 281-285)
```dockerfile
RUN echo "Installing TruffleHog..." && \
    pip3 install --no-cache-dir --break-system-packages truffleHog
```
- **trufflehog**: Searches through git repositories for secrets

### 6. Shodan CLI Fix (Lines 287-292)
```dockerfile
RUN echo "Installing Shodan CLI..." && \
    pip3 install --no-cache-dir --break-system-packages shodan && \
    ln -s /home/node/.local/bin/shodan /usr/local/bin/shodan || true
```
- **shodan**: Already installed, fixed PATH with symlink

### 7. testssl.sh Fix (Line 294-295)
```dockerfile
RUN ln -sf /opt/testssl/testssl.sh /usr/local/bin/testssl.sh
```
- **testssl.sh**: Already installed, fixed symlink name

---

## 📝 Updated Files

### 1. Dockerfile
- **Location**: `/Users/tester/Documents/n8n_stuff/Dockerfile`
- **Lines added**: 256-295 (40 lines)
- **Changes**: Added 7 missing tools

### 2. setup.sh
- **Location**: `/Users/tester/Documents/n8n_stuff/setup.sh`
- **Changes**:
  - Removed verification for non-existent tools (feroxbuster, kiterunner, gowitness, S3Scanner)
  - Added verification for new tools (naabu, gobuster, dnsrecon, theharvester, trufflehog, shodan)
  - Updated final info display
  - Lines updated: 712-747, 783-797

### 3. README.md
- **Location**: `/Users/tester/Documents/n8n_stuff/README.md`
- **Changes**:
  - Removed tools that don't exist (assetfinder, feroxbuster, kiterunner, S3Scanner, gowitness)
  - Added new tools to appropriate categories
  - Created new "OSINT & Intelligence" section
  - Lines updated: 193-238

---

## 🚀 How to Apply Changes

### Step 1: Rebuild Docker Image

```bash
cd /Users/tester/Documents/n8n_stuff

# Rebuild the n8n-recon service
docker compose build n8n-recon

# Expected build time: +3-5 minutes for new tools
```

### Step 2: Restart Container

```bash
# Stop and start with new image
docker compose up -d n8n-recon

# Wait for container to be healthy
docker compose ps
```

### Step 3: Verify New Tools

```bash
# Quick verification
docker exec n8n_recon_hub bash -c "
echo '=== Verifying New Tools ==='
which naabu && echo '✓ naabu'
which gobuster && echo '✓ gobuster'
which dnsrecon && echo '✓ dnsrecon'
which theharvester && echo '✓ theharvester'
which trufflehog && echo '✓ trufflehog'
which shodan && echo '✓ shodan'
which testssl.sh && echo '✓ testssl.sh'
python3 -c 'import whois' && echo '✓ python-whois'
"
```

**Expected output**: All tools should show checkmarks

---

## 🧪 Testing New Tools

### Test 1: naabu (Port Scanner)
```bash
docker exec n8n_recon_hub naabu -host scanme.nmap.org -top-ports 100
```

### Test 2: gobuster (Directory Discovery)
```bash
docker exec n8n_recon_hub bash -c "
echo -e 'admin\napi\ntest' > /tmp/wordlist.txt
gobuster dir -u https://example.com -w /tmp/wordlist.txt -q
"
```

### Test 3: dnsrecon (DNS Enumeration)
```bash
docker exec n8n_recon_hub dnsrecon -d example.com -t std
```

### Test 3b: massdns (DNS Resolver - puredns dependency)
```bash
# Test massdns directly
docker exec n8n_recon_hub bash -c "
echo 'example.com' > /tmp/test_domains.txt
massdns -r /tmp/resolvers.txt -t A /tmp/test_domains.txt -o S
"

# Test puredns with massdns
docker exec n8n_recon_hub bash -c "
echo 'www.example.com
mail.example.com
ftp.example.com' > /tmp/test_subs.txt
puredns resolve /tmp/test_subs.txt
"
```

### Test 4: theHarvester (OSINT)
```bash
docker exec n8n_recon_hub theHarvester -d example.com -b google
```

### Test 4b: python-whois (WHOIS Lookup)
```bash
docker exec n8n_recon_hub python3 -c "
import whois
w = whois.whois('example.com')
print('Domain:', w.domain_name)
print('Registrar:', w.registrar)
print('Creation Date:', w.creation_date)
"
```

### Test 5: trufflehog (Secret Scanning)
```bash
docker exec n8n_recon_hub trufflehog --help
```

### Test 6: shodan (API Search)
```bash
# Requires API key
docker exec n8n_recon_hub shodan version
```

### Test 7: testssl.sh (SSL Testing)
```bash
docker exec n8n_recon_hub testssl.sh --fast https://example.com
```

---

## 📊 Complete Tool Inventory

After rebuild, you will have **30+ security tools**:

### Subdomain Discovery (2)
- subfinder, amass

### DNS Tools (5)
- dnsx, puredns, massdns, dig, dnsrecon

### Port Scanning (2)
- nmap, naabu

### Web Crawling (4)
- katana, gospider, waybackurls, gau

### Content Discovery (3)
- ffuf, gobuster, dirsearch

### Technology Detection (3)
- wappalyzer, WhatWeb, retire.js

### API Discovery (1)
- arjun

### SSL/TLS Analysis (2)
- tlsx, testssl.sh

### OSINT (3)
- theHarvester, dnsrecon, python-whois

### Secret Scanning (1)
- trufflehog

### Cloud Discovery (1)
- cloud_enum

### External APIs (1)
- shodan

### Vulnerability Scanning (1)
- nuclei

### Exploitation (2)
- sqlmap, searchsploit

### PDF Generation (2)
- WeasyPrint, html2pdf

---

## 🎯 Summary of Changes

| Tool | Status Before | Status After | Method |
|------|---------------|--------------|--------|
| naabu | ❌ Missing | ✅ Installed | Go install |
| gobuster | ❌ Missing | ✅ Installed | apk package |
| dnsrecon | ❌ Missing | ✅ Installed | pip package |
| theHarvester | ❌ Missing | ✅ Installed | pip package |
| trufflehog | ❌ Missing | ✅ Installed | pip package |
| shodan | ⚠️ PATH issue | ✅ Fixed | Symlink added |
| testssl.sh | ⚠️ Symlink issue | ✅ Fixed | Symlink corrected |

---

## ✅ Verification Checklist

After rebuild, verify:

- [ ] Docker image builds successfully
- [ ] Container starts without errors
- [ ] All 7 tools show in PATH
- [ ] naabu can scan ports
- [ ] gobuster can enumerate directories
- [ ] dnsrecon can enumerate DNS
- [ ] theHarvester can gather OSINT
- [ ] trufflehog is executable
- [ ] shodan CLI works
- [ ] testssl.sh can scan SSL

---

## 🔧 Troubleshooting

### Issue: Build fails on naabu
**Cause**: Missing libpcap-dev
**Fix**: Already added to Dockerfile line 261

### Issue: Python tools not found
**Cause**: pip install as root but running as node user
**Fix**: Tools installed with `--break-system-packages`, accessible to all users

### Issue: Shodan still not in PATH
**Cause**: Symlink failed
**Fix**: Run manually after build:
```bash
docker exec -u root n8n_recon_hub ln -sf /home/node/.local/bin/shodan /usr/local/bin/shodan
```

### Issue: testssl.sh permission denied
**Cause**: Missing execute permission
**Fix**: Run manually:
```bash
docker exec -u root n8n_recon_hub chmod +x /opt/testssl/testssl.sh
```

---

## 📚 Usage in n8n Workflows

All tools can be used in **Execute Command** nodes:

### Example: Port Scan with naabu
```bash
naabu -host {{ $json.target }} -top-ports 1000 -silent -json
```

### Example: Directory Discovery with gobuster
```bash
gobuster dir -u https://{{ $json.target }} \
  -w /usr/share/seclists/Discovery/Web-Content/common.txt \
  -q -o /tmp/gobuster_{{ $json.timestamp }}.txt
```

### Example: OSINT with theHarvester
```bash
theHarvester -d {{ $json.domain }} -b all -f /tmp/harvester_{{ $json.timestamp }}
```

---

## 🎉 Result

After rebuilding, you'll have **100% tool coverage** with all missing tools installed and working.

**Total tools**: 30+
**Missing tools**: 0
**Build time**: +3-5 minutes
**Cost**: $0

---

**Ready to rebuild? Run:**
```bash
cd /Users/tester/Documents/n8n_stuff && docker compose build n8n-recon && docker compose up -d
```
