# n8n Recon Hub - Web Interface

Simple web form for submitting targets to n8n for automated reconnaissance scanning.

---

## What This Does

1. **User submits target** (IP address or URL) via web form
2. **Form sends to n8n webhook** at `http://localhost:5678/webhook/recon-scan`
3. **n8n workflow processes target**:
   - Validates input
   - Detects if it's IP or domain
   - Runs appropriate tools (nmap, subfinder, etc.)
   - Stores results in PostgreSQL
4. **User gets confirmation** message

---

## Quick Start

### Step 1: Start the Web Interface

```bash
# Start all services (including web interface)
docker compose up -d

# Check status
docker compose ps

# You should see:
# - recon_postgres (running)
# - n8n_recon_hub (running)
# - n8n_web_interface (running)
```

### Step 2: Import n8n Workflow

1. **Open n8n**: http://localhost:5678
2. **Login** with your credentials
3. Click **"Add workflow"** → **"Import from File"**
4. Select `n8n-recon-workflow.json` from this directory
5. **Configure PostgreSQL credential** (if not already set):
   - Click on "Store Session" node
   - Add credential:
     - Host: `postgres`
     - Database: `recon_hub`
     - User: `recon_user`
     - Password: (from your `.env` file)
6. **Activate the workflow** (toggle switch in top right)

### Step 3: Access Web Interface

Open your browser to: **http://localhost:8080**

---

## Usage

1. Enter target in the form:
   - IP address: `192.168.1.1`
   - Domain: `example.com`
   - URL: `https://example.com`

2. Click **"Submit Target"**

3. You'll see: ✅ **"Target submitted successfully!"**

4. Check n8n for execution:
   - Go to http://localhost:5678
   - Click **"Executions"** in sidebar
   - You'll see your scan running/completed

---

## How It Works

### Web Form (`index.html`)
- Dark theme hacker-style interface
- Validates input (IP or domain format)
- Sends POST request to n8n webhook
- Shows success/error messages

### n8n Workflow (`n8n-recon-workflow.json`)

```
Webhook Trigger
    ↓
Validate Target (check if target exists)
    ↓
Process Target (detect IP vs domain)
    ↓
Check Type (branch based on type)
    ↓
┌─────────────────┬─────────────────┐
│   If Domain     │    If IP        │
│   Run Subfinder │    Run Nmap     │
└─────────────────┴─────────────────┘
    ↓
Store Session in PostgreSQL
    ↓
Return Success Response
```

### Tools Executed

**For Domains:**
- `subfinder -d example.com` - Subdomain enumeration

**For IPs:**
- `nmap -sV -T4 --top-ports 100 192.168.1.1` - Port scan

---

## Customization

### Change Webhook URL

Edit `index.html` line 177:
```javascript
const N8N_WEBHOOK_URL = 'http://localhost:5678/webhook/recon-scan';
```

### Add More Tools to Workflow

In n8n workflow editor:
1. Add new **Execute Command** node
2. Configure command: `nuclei -u {{ $json.target }}`
3. Connect to the flow
4. Save and activate

### Change Web Interface Port

Edit `docker-compose.yml`:
```yaml
web-interface:
  ports:
    - "9000:80"  # Change 8080 to 9000
```

Then restart:
```bash
docker compose restart web-interface
```

---

## Troubleshooting

### Web Form Shows CORS Error

**Problem:** Browser blocks cross-origin requests to n8n.

**Solution:** Add CORS to n8n environment in `.env`:
```bash
N8N_CORS_ORIGIN=http://localhost:8080
```

Then restart:
```bash
docker compose restart n8n-recon
```

---

### Webhook Returns 404

**Problem:** n8n workflow not activated or webhook path wrong.

**Solution:**
1. Check workflow is **activated** (toggle switch in n8n)
2. Verify webhook path matches:
   - Form: `http://localhost:5678/webhook/recon-scan`
   - n8n webhook node: path should be `recon-scan`

---

### Tools Not Found

**Problem:** nmap/subfinder commands fail in n8n.

**Solution:** Tools are installed in the n8n-recon container. Verify:
```bash
docker compose exec n8n-recon which nmap
docker compose exec n8n-recon which subfinder
```

If missing, rebuild the container:
```bash
docker compose build --no-cache n8n-recon
docker compose up -d
```

---

### Web Interface Won't Load

**Problem:** nginx container not running or port conflict.

**Solution:**
```bash
# Check container status
docker compose ps web-interface

# Check logs
docker compose logs web-interface

# Restart
docker compose restart web-interface

# Check if port 8080 is available
lsof -i :8080
```

---

## Architecture

```
┌─────────────────────┐
│   User Browser      │
│  (localhost:8080)   │
└──────────┬──────────┘
           │
           │ POST /webhook/recon-scan
           │ { "target": "example.com" }
           ↓
┌─────────────────────────┐
│   n8n Workflow          │
│  (localhost:5678)       │
└──────────┬──────────────┘
           │
           ├─→ Validate Input
           ├─→ Detect IP/Domain
           ├─→ Execute Tools
           └─→ Store Results
                    ↓
           ┌────────────────┐
           │  PostgreSQL    │
           │  recon_hub DB  │
           └────────────────┘
```

---

## Files

```
web-interface/
├── index.html                    # Web form (open in browser)
├── n8n-recon-workflow.json       # Import into n8n
└── README.md                     # This file
```

---

## Access URLs

- **Web Form**: http://localhost:8080
- **n8n Interface**: http://localhost:5678
- **PostgreSQL**: localhost:5432

---

## Security Notes

⚠️ **This is for local/internal use only!**

- No authentication on web form (anyone can submit)
- Webhook URL exposed to browser
- Not suitable for internet-facing deployment

**For production:**
- Add authentication to web form
- Hide n8n behind reverse proxy
- Use HTTPS
- Add rate limiting
- Validate/sanitize all inputs

---

## Next Steps

1. ✅ Start containers: `docker compose up -d`
2. ✅ Import workflow to n8n
3. ✅ Activate workflow
4. ✅ Open http://localhost:8080
5. ✅ Submit a target and watch it scan!

---

## Support

- Check n8n logs: `docker compose logs -f n8n-recon`
- Check web logs: `docker compose logs -f web-interface`
- View executions in n8n: http://localhost:5678 → Executions
- Query database:
  ```bash
  docker compose exec postgres psql -U recon_user -d recon_hub -c "SELECT * FROM recon_sessions ORDER BY created_at DESC LIMIT 10;"
  ```

---

**Happy Scanning! 🎯**
