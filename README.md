# n8n Reconnaissance Hub

**Complete Offensive Security Automation Platform**

A fully dockerized n8n automation hub pre-loaded with 20+ penetration testing and reconnaissance tools, integrated with PostgreSQL for storing and managing reconnaissance data.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  User Access Points                                              │
│  • Web Interface: http://localhost/                             │
│  • n8n Admin: http://localhost:5678/                            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  Nginx Reverse Proxy (Port 80)                                  │
│  Container: n8n_nginx_proxy                                      │
│                                                                  │
│  Routes:                                                         │
│  • /                 → Static web interface                     │
│  • /webhook/*        → n8n:5678/webhook/*                       │
│  • /api/*            → n8n:5678/api/*                           │
│  • /health, /healthz → Health checks                            │
└─────────────────┬────────────────┬──────────────────────────────┘
                  │                │
                  ▼                ▼
       ┌──────────────┐  ┌─────────────────────────────────┐
       │ Static Files │  │  n8n Workflow Engine            │
       │ (web-interface)  │  Container: n8n_recon_hub      │
       └──────────────┘  │  Port: 127.0.0.1:5678 (admin)  │
                         │                                  │
                         │  Pre-installed Security Tools:   │
                         │  • 20+ recon & pentest tools    │
                         │  • Subdomain enumeration         │
                         │  • Port scanning                 │
                         │  • Vulnerability scanning        │
                         │  • Web fuzzing                   │
                         │  • Credential testing            │
                         └─────────┬───────────────────────┘
                                   │
                                   ▼
                         ┌─────────────────────────────────┐
                         │  PostgreSQL Database            │
                         │  Container: recon_postgres       │
                         │  Port: 127.0.0.1:5432           │
                         │                                  │
                         │  Custom Schema:                  │
                         │  • recon_sessions                │
                         │  • subdomain_intel               │
                         │  • port_scan_results             │
                         │  • vulnerability_findings        │
                         │  • + 15 more tables              │
                         └─────────────────────────────────┘

Docker Network: recon-net (isolated internal network)
```

### Key Features:
- **Single Entry Point:** All traffic goes through nginx (port 80)
- **Localhost-Only Admin:** n8n admin bound to 127.0.0.1:5678
- **No External Dependencies:** No ngrok or tunnel services required
- **Secure by Default:** PostgreSQL and n8n not exposed to network
- **Persistent Storage:** Docker volumes for data persistence

---

## 🎯 Overview

This platform combines the power of n8n workflow automation with industry-standard offensive security tools to create a complete reconnaissance and vulnerability assessment hub.

### Features

- ✅ **n8n Workflow Automation** - Visual workflow builder for chaining security tools
- ✅ **Web Interface** - Simple dark-themed form for submitting targets (no auth required)
- ✅ **20+ Security Tools** - Pre-installed and ready to use
- ✅ **PostgreSQL Database** - Custom schema for storing recon results
- ✅ **Automated Setup** - One-command deployment
- ✅ **Persistent Storage** - All data preserved across restarts
- ✅ **Network Capabilities** - NET_ADMIN and NET_RAW for advanced scanning
- ✅ **Multi-User Support** - Offline user management scripts included
- ✅ **Backup & Restore** - Automated scripts with password mismatch detection

---

## 🛠️ Installed Tools

### Subdomain Enumeration
- **subfinder** - Fast subdomain discovery
- **amass** - In-depth attack surface mapping
- **assetfinder** - Find domains and subdomains
- **httprobe** - Probe for working HTTP/HTTPS servers

### Network Scanning
- **nmap** - Network mapper with vulners & vulscan scripts
- **naabu** - Fast port scanner

### Web Reconnaissance
- **httpx** - Fast HTTP toolkit
- **katana** - Web crawling framework
- **ffuf** - Fast web fuzzer
- **waybackurls** - Fetch URLs from Wayback Machine
- **gau** - Fetch URLs from various sources
- **hakrawler** - Web crawler for gathering URLs

### Vulnerability Scanning
- **nuclei** - Vulnerability scanner with auto-updated templates
- **nikto** - Web server scanner

### Credential Testing
- **NetExec (nxc)** - Network protocol tester (SMB, WinRM, etc.)
- **hydra** - Password brute-forcing tool

### Exploitation
- **sqlmap** - Automatic SQL injection tool
- **searchsploit** - Exploit database search

### Additional Tools
- **john** - Password cracker
- **impacket** - Network protocol toolkit
- **SecLists** - Complete wordlist collection

---

## 🚀 Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- OpenSSL (for credential generation)
- 5GB+ free disk space

### Installation

```bash
# 1. Clone or navigate to this directory
cd /path/to/n8n-recon-hub

# 2. Run the automated setup script
./setup.sh

# 3. Wait for build to complete (10-20 minutes first time)

# 4. Access n8n at http://localhost:5678
# Credentials are in CREDENTIALS.txt
```

### Manual Setup (Alternative)

```bash
# Copy environment template
cp .env.example .env

# Edit .env and set strong passwords
vim .env

# Build and start
docker compose build
docker compose up -d

# Check status
docker compose ps
```

---

## 🎯 Web Interface - Target Submission

A simple, dark-themed web form for submitting reconnaissance targets without authentication.

### Quick Start with Web Interface

**Step 1: Setup (Automatic via setup.sh)**
```bash
./setup.sh
# This will start all services including the web interface at http://localhost:8080
```

**Step 2: Import n8n Workflow (One-Time Setup)**
1. Open n8n: http://localhost:5678
2. Login with credentials from `CREDENTIALS.txt`
3. Click **"Add workflow"** → **"Import from File"**
4. Select `web-interface/n8n-recon-workflow.json`
5. Configure PostgreSQL credential:
   - Host: `postgres`
   - Database: `recon_hub`
   - User: `recon_user`
   - Password: (from your `.env` file)
6. **Activate the workflow** (toggle switch in top-right)

**Step 3: Submit Targets**
1. Open web form: http://localhost:8080
2. Enter target (IP address or domain):
   - `192.168.1.1`
   - `example.com`
   - `https://example.com`
3. Click **"Submit Target"**
4. View execution in n8n: http://localhost:5678 → Executions

### Web Interface Features

- 🎨 **Dark hacker-style theme** with neon green accents
- 📝 **Single input field** - just enter IP or URL
- ✅ **Client-side validation** - checks IP/domain format
- 🚀 **Direct webhook submission** to n8n
- 📊 **Real-time feedback** - success/error messages
- 📱 **Mobile responsive** - works on any device
- 🔓 **No authentication** - single-user interface for internal use

### Access URLs

After running `./setup.sh`:

| Service | URL | Purpose |
|---------|-----|---------|
| **Web Form** | http://localhost:8080 | Submit targets for scanning |
| **n8n Interface** | http://localhost:5678 | Manage workflows, view executions |
| **PostgreSQL** | localhost:5432 | Database (internal) |

### How It Works

```
User submits target → Web form POSTs to n8n webhook → n8n workflow:
  ├─ Validates input
  ├─ Detects IP vs domain
  ├─ Runs appropriate tools:
  │  ├─ Domain: subfinder → httpx → nuclei
  │  └─ IP: nmap → nuclei
  ├─ Stores results in PostgreSQL
  └─ Returns success response
```

For detailed documentation, see: `web-interface/README.md`

---

## 👥 User Management

Multi-user support with offline user management scripts.

### Adding Users (Offline)

```bash
# Add a new user
./add-user.sh

# List all users
./list-users.sh

# Reset user password
./reset-password.sh

# Delete a user
./delete-user.sh
```

### Available Roles

- **global:owner** - Full system access
- **global:admin** - Manage workflows and users
- **global:member** - Create/edit own workflows

For detailed documentation, see: `OFFLINE_USER_MANAGEMENT.md`

---

## 📁 Project Structure

```
n8n-recon-hub/
├── Dockerfile                      # Custom n8n image with security tools
├── docker-compose.yml              # Service orchestration (n8n, postgres, web)
├── init-db.sql                    # PostgreSQL recon schema
├── .env.example                   # Environment variables template
├── setup.sh                       # Automated setup script
├── README.md                      # This file
├── OFFLINE_USER_MANAGEMENT.md     # User management guide
│
├── web-interface/                 # Web form for target submission
│   ├── index.html                # Dark-themed submission form
│   ├── n8n-recon-workflow.json   # Pre-built n8n workflow (import this)
│   └── README.md                 # Web interface documentation
│
├── User Management Scripts:
│   ├── add-user.sh               # Add new users offline
│   ├── list-users.sh             # List all users
│   ├── reset-password.sh         # Reset user passwords
│   └── delete-user.sh            # Delete users
│
├── Backup & Restore:
│   ├── backup.sh                 # Automated backup script
│   ├── restore.sh                # Automated restore script
│   └── BACKUP_GUIDE.md           # Complete backup/restore guide
│
# Auto-generated (gitignored):
├── .env                          # Your environment config
├── CREDENTIALS.txt               # Access credentials (KEEP SECURE!)
└── backups/                      # Backup directory (auto-created)
    ├── backup_YYYYMMDD_HHMMSS/   # Timestamped backups
    └── latest → backup_*/        # Symlink to most recent
```

---

## 💾 Database Schema

The platform includes custom PostgreSQL tables for storing reconnaissance data:

| Table | Purpose |
|-------|---------|
| `subdomain_intel` | Discovered subdomains, IPs, HTTP status |
| `network_scans` | Port scan results, services, versions |
| `smb_enum` | SMB enumeration data (shares, users) |
| `vulnerabilities` | Vulnerability findings with CVE, CVSS |
| `fuzzing_results` | Web fuzzing discoveries |
| `credentials` | Found or cracked credentials |
| `web_technologies` | Detected technologies and versions |
| `nuclei_results` | Nuclei scanner findings |
| `sqli_results` | SQL injection vulnerabilities |
| `recon_sessions` | Track reconnaissance campaigns |

---

## 🔧 Usage Examples

### Access the Container

```bash
# Enter the recon container
docker compose exec n8n-recon bash

# Run tools directly
docker compose exec n8n-recon subfinder -d example.com
docker compose exec n8n-recon nuclei -u https://example.com
```

### Example n8n Workflows

Create workflows using **Execute Command** nodes in n8n with these examples:

#### 1. Subdomain Discovery

```bash
# Using subfinder
subfinder -d example.com -o /opt/recon-workspace/subdomains.txt

# Using amass
amass enum -d example.com -o /opt/recon-workspace/amass_results.txt
```

#### 2. Network Scanning

```bash
# Fast port scan with naabu
naabu -host example.com -o /opt/recon-workspace/ports.txt

# Detailed scan with nmap + vulners
nmap -sV --script vulners example.com -oN /opt/recon-workspace/nmap_vulners.txt

# Scan with vulscan
nmap -sV --script vulscan example.com -oN /opt/recon-workspace/nmap_vulscan.txt
```

#### 3. SMB Enumeration

```bash
# Enumerate SMB shares
nxc smb 192.168.1.0/24 -u '' -p '' --shares

# With credentials
nxc smb 192.168.1.100 -u admin -p password --shares --users
```

#### 4. Web Fuzzing

```bash
# Directory fuzzing with ffuf
ffuf -u https://example.com/FUZZ \
     -w /opt/SecLists/Discovery/Web-Content/common.txt \
     -o /opt/recon-workspace/ffuf_results.json

# Large directory list
ffuf -u https://example.com/FUZZ \
     -w /opt/SecLists/Discovery/Web-Content/raft-large-directories.txt
```

#### 5. Vulnerability Scanning

```bash
# Nuclei scan (auto-updated templates)
nuclei -u https://example.com -severity high,critical -o /opt/recon-workspace/nuclei.txt

# Scan multiple URLs
nuclei -l /opt/recon-workspace/urls.txt -severity medium,high,critical
```

#### 6. SQL Injection Testing

```bash
# Automated SQLi testing with sqlmap
sqlmap -u "https://example.com/page?id=1" --batch --dbs

# With POST data
sqlmap -u "https://example.com/login" --data="user=admin&pass=test" --batch
```

#### 7. Credential Testing

```bash
# Password spraying with hydra
hydra -L /opt/wordlists/users.txt \
      -P /opt/wordlists/10-million-password-list-top-1000000.txt \
      ssh://192.168.1.100
```

#### 8. Web Crawling

```bash
# Crawl with katana
katana -u https://example.com -d 3 -o /opt/recon-workspace/katana_urls.txt

# Get URLs from Wayback Machine
waybackurls example.com > /opt/recon-workspace/wayback.txt
```

### Storing Results in Database

Use **Postgres** nodes in n8n to insert results:

```sql
-- Insert subdomain discovery results
INSERT INTO subdomain_intel (domain, subdomain, source, ip, http_status)
VALUES ('example.com', 'api.example.com', 'subfinder', '1.2.3.4', 200);

-- Insert vulnerability finding
INSERT INTO vulnerabilities (target, vulnerability_name, severity, cvss_score, description, cve_id)
VALUES ('example.com', 'SQL Injection', 'Critical', 9.8, 'SQLi in login form', 'CVE-2024-XXXXX');

-- Query all high/critical vulnerabilities
SELECT * FROM vulnerabilities WHERE severity IN ('High', 'Critical') ORDER BY cvss_score DESC;
```

---

## 🗂️ Workspace Directories

| Directory | Purpose |
|-----------|---------|
| `/opt/recon-workspace` | Store scan results, reports |
| `/opt/loot` | Store extracted data, credentials |
| `/opt/SecLists` | Complete SecLists wordlist collection |
| `/opt/wordlists` | Curated common wordlists |

Access from host:
```bash
# Copy files from container
docker cp n8n_recon_hub:/opt/recon-workspace/results.txt ./

# Or use docker volume inspect
docker volume inspect recon_workspace
```

---

## 🔒 Security & Usage Guidelines

### ⚠️ Legal Warning

**CRITICAL:** Only use this platform on systems you own or have explicit written authorization to test. Unauthorized use of these tools is illegal and unethical.

### Best Practices

1. **Authorization First** - Always get written permission before scanning
2. **Scope Definition** - Clearly define what's in/out of scope
3. **Rate Limiting** - Don't DOS targets with aggressive scans
4. **Data Protection** - Encrypt and secure all reconnaissance data
5. **Credential Security** - Never commit credentials to version control

### Securing the Platform

```bash
# Change default passwords immediately
vim .env
docker compose restart n8n-recon

# Backup encryption key
cat CREDENTIALS.txt | grep ENCRYPTION_KEY > encryption_key_backup.txt
# Store in password manager or encrypted vault

# Use HTTPS in production (via reverse proxy)
# Restrict network access with firewall rules
# Regular updates: docker compose pull && docker compose up -d
```

---

## 📊 Database Access

### Connect to PostgreSQL

```bash
# Via Docker
docker compose exec postgres psql -U recon_user -d recon_hub

# From host (requires psql client)
psql postgresql://recon_user:<password>@localhost:5432/recon_hub
```

### Useful SQL Queries

```sql
-- View all discovered subdomains for a domain
SELECT subdomain, ip, http_status, discovered_at
FROM subdomain_intel
WHERE domain = 'example.com'
ORDER BY discovered_at DESC;

-- Count vulnerabilities by severity
SELECT severity, COUNT(*)
FROM vulnerabilities
GROUP BY severity
ORDER BY COUNT(*) DESC;

-- Find all open ports on a target
SELECT port, service, version
FROM network_scans
WHERE target = '192.168.1.100';

-- Get all high/critical findings
SELECT target, vulnerability_name, severity, cvss_score
FROM vulnerabilities
WHERE severity IN ('High', 'Critical')
ORDER BY cvss_score DESC;

-- Active recon sessions
SELECT * FROM recon_sessions WHERE status = 'active';
```

### Backup & Restore

**Automated Backup/Restore (Recommended):**

```bash
# Create full backup (database, encryption key, .env)
./backup.sh

# Restore from backup
./restore.sh backups/backup_20251028_150030/

# Restore with dry-run (see what would happen)
./restore.sh backups/latest --dry-run
```

**What Gets Backed Up:**
- ✅ PostgreSQL database (users, passwords, workflows, credentials, recon data)
- ✅ n8n encryption key (CRITICAL - needed to decrypt credentials)
- ✅ Environment configuration (.env)
- ✅ Metadata and checksums

**Automatic Features:**
- 🔐 Detects and fixes password mismatches during restore
- 🗂️ 30-day retention with automatic cleanup
- 📊 Checksums for verification
- 🔄 Creates safety backups before restore
- ⚡ Fast and reliable

**Manual Backup (Alternative):**

```bash
# Backup database only
docker compose exec -T postgres pg_dump -U recon_user recon_hub > backup_$(date +%Y%m%d).sql

# Restore database only
docker compose exec -T postgres psql -U recon_user -d recon_hub < backup_20250101.sql

# Backup Docker volumes
docker run --rm -v recon_workspace:/data -v $(pwd):/backup alpine \
  tar czf /backup/workspace_backup.tar.gz -C /data .
```

**📖 For comprehensive backup strategies, see:** [`BACKUP_GUIDE.md`](BACKUP_GUIDE.md)

---

## 🔄 Container Management

### Start/Stop Services

```bash
# Start all services
docker compose up -d

# Stop all services (data persists)
docker compose down

# Stop and remove ALL data (DESTRUCTIVE!)
docker compose down -v

# Restart specific service
docker compose restart n8n-recon
```

### View Logs

```bash
# All services
docker compose logs -f

# Only n8n
docker compose logs -f n8n-recon

# Only PostgreSQL
docker compose logs -f postgres

# Last 100 lines
docker compose logs --tail=100
```

### Check Status

```bash
# Container status
docker compose ps

# Resource usage
docker stats

# Disk usage
docker system df

# Volume list
docker volume ls | grep recon
```

---

## 🔧 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker compose logs n8n-recon

# Verify database is ready
docker compose exec postgres pg_isready -U recon_user -d recon_hub

# Force recreate
docker compose down
docker compose up -d --force-recreate
```

### Tool Not Found

```bash
# Verify tool is installed
docker compose exec n8n-recon which nuclei

# Check PATH
docker compose exec n8n-recon echo $PATH

# Rebuild container
docker compose build --no-cache n8n-recon
docker compose up -d
```

### Database Connection Issues

```bash
# Test connection
docker compose exec postgres psql -U recon_user -d recon_hub -c "SELECT 1;"

# Check environment variables
docker compose exec n8n-recon env | grep DB_

# Reinitialize (DELETES DATA!)
docker compose down -v
docker compose up -d
```

### Port Already in Use

```bash
# Check what's using port 5678
lsof -i :5678

# Change port in docker-compose.yml
# Edit: "8080:5678" instead of "5678:5678"
vim docker-compose.yml
docker compose up -d
```

### Out of Disk Space

```bash
# Clean Docker system
docker system prune -a --volumes

# Check volume sizes
docker system df -v

# Remove old images
docker image prune -a
```

---

## 🎯 Advanced Configuration

### Update Nuclei Templates

```bash
docker compose exec n8n-recon nuclei -update-templates
```

### Add Custom Tools

Edit `Dockerfile` and add your tools:

```dockerfile
# Install custom Go tool
RUN go install github.com/your/tool@latest

# Install custom Python tool
RUN pip3 install --break-system-packages your-tool
```

Then rebuild:
```bash
docker compose build --no-cache
docker compose up -d
```

### Custom Wordlists

```bash
# Copy wordlist into container
docker cp custom_wordlist.txt n8n_recon_hub:/opt/wordlists/

# Or add to Dockerfile
RUN wget https://example.com/wordlist.txt -O /opt/wordlists/custom.txt
```

### Environment Variables

Edit `.env` file to customize:

```bash
# Change timezone
TIMEZONE=America/New_York

# Change database name
POSTGRES_DB=my_recon_db

# Restart to apply
docker compose restart
```

---

## 📚 Workflow Examples

### Complete Subdomain Recon Workflow

1. **Trigger**: Manual or scheduled
2. **Subfinder**: Discover subdomains → save to `/opt/recon-workspace/subs.txt`
3. **HTTPx**: Probe live hosts → save active to variable
4. **Postgres**: INSERT into `subdomain_intel` table
5. **Nuclei**: Scan active hosts for vulns
6. **Postgres**: INSERT results into `vulnerabilities` table
7. **Notification**: Send summary via email/Slack

### Network Enumeration Workflow

1. **Trigger**: HTTP webhook with target IP
2. **Naabu**: Fast port discovery
3. **Nmap**: Detailed service scan on open ports
4. **Postgres**: INSERT into `network_scans` table
5. **Conditional**: If SMB port open → run NetExec
6. **Postgres**: INSERT SMB results into `smb_enum`
7. **Generate Report**: Query database and format results

---

## 🆙 Updating

### Update n8n and Tools

```bash
# Pull latest images
docker compose pull

# Rebuild with latest tools
docker compose build --no-cache

# Restart with new versions
docker compose up -d

# Verify versions
docker compose exec n8n-recon nuclei -version
docker compose exec n8n-recon nmap --version
```

### Update PostgreSQL

```bash
# Backup first!
docker compose exec -T postgres pg_dump -U recon_user recon_hub > backup.sql

# Edit docker-compose.yml - change postgres:15-alpine to postgres:16-alpine
vim docker-compose.yml

# Restart
docker compose down
docker compose up -d
```

---

## 🤝 Contributing

Suggestions for additional tools or improvements? Open an issue or submit a pull request!

### Tool Suggestions

- Add your favorite recon tool to the Dockerfile
- Share workflow templates
- Improve database schema
- Enhance automation scripts

---

## 📄 License

This setup configuration is provided for authorized security testing only.

Individual tools retain their respective licenses:
- n8n: [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md)
- Security tools: Various open-source licenses (check individual repos)

---

## 📞 Support & Resources

### Documentation

- **n8n Docs**: https://docs.n8n.io
- **n8n Community**: https://community.n8n.io
- **ProjectDiscovery**: https://docs.projectdiscovery.io
- **SecLists**: https://github.com/danielmiessler/SecLists

### Getting Help

1. Check this README thoroughly
2. Review logs: `docker compose logs -f`
3. Verify tool installation: `docker compose exec n8n-recon <tool> --version`
4. Check n8n community forums
5. Review tool-specific documentation

---

## ⚠️ Disclaimer

**This platform is designed for authorized security testing and educational purposes only.**

The authors and contributors:
- Are NOT responsible for misuse or damage caused by this software
- Do NOT condone illegal or unauthorized use
- Assume users have proper authorization and legal right to test targets
- Recommend compliance with all applicable laws and regulations

**Use responsibly. Get authorization. Test ethically. 🛡️**

---

## 🎯 Quick Reference Card

```bash
# Essential Commands
./setup.sh                                  # Initial setup
docker compose up -d                         # Start services
docker compose down                          # Stop services
docker compose logs -f n8n-recon            # View logs
docker compose exec n8n-recon bash          # Access container
docker compose exec postgres psql -U recon_user -d recon_hub  # Access DB

# Access
http://localhost:5678                        # n8n Web UI
cat CREDENTIALS.txt                          # View credentials

# Common Tool Paths
/opt/SecLists/                              # Wordlists
/opt/recon-workspace/                       # Output directory
/opt/loot/                                  # Extracted data
/opt/wordlists/                             # Curated wordlists

# Tool Verification
docker compose exec n8n-recon nuclei -version
docker compose exec n8n-recon nxc --version
docker compose exec n8n-recon subfinder -version
```

---

**Happy Hunting! 🎯 Remember: With great power comes great responsibility! 🛡️**
