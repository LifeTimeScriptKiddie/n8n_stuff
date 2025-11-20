# Setup Demo Webhook at http://localhost/webhook/demo-recon

## Current Configuration ✅

Your setup is already configured:
- **Web Interface**: http://localhost/ (nginx port 80)
- **Webhook URL**: `/webhook/demo-recon` (proxied through nginx)
- **n8n Backend**: http://n8n-recon:5678 (Docker internal network)

## Setup Steps

### 1. Import Demo Workflow into n8n

```bash
# Access n8n UI
open http://127.0.0.1:5678

# Or use credentials
Username: admin
Password: (check your .env file for N8N_BASIC_AUTH_PASSWORD)
```

In n8n UI:
1. Go to **Workflows** → **Import from File**
2. Select: `/Users/tester/Documents/n8n_stuff/workflows/demo_standalone_recon.json`
3. Click **Import**
4. **Activate** the workflow (toggle in top-right)

### 2. Verify Webhook is Active

```bash
# Check webhook registration
curl -X POST http://127.0.0.1:5678/webhook/demo-recon \
  -H "Content-Type: application/json" \
  -d '{"target": "scanme.nmap.org"}'

# Should return:
# {"status":"scan_complete","message":"Demo scan completed","timestamp":"..."}
```

### 3. Restart Nginx (to load updated web interface)

```bash
cd /Users/tester/Documents/n8n_stuff

# Restart nginx container
docker-compose restart nginx

# Verify nginx is running
docker ps | grep nginx
```

### 4. Test Web Interface

```bash
# Open web interface
open http://localhost/

# Or
open http://127.0.0.1/
```

**In the web form:**
1. Enter target: `scanme.nmap.org`
2. Click **Submit Target**
3. Should see: ✅ Target submitted successfully!

### 5. Verify Request Flow

```bash
# Check nginx logs
docker logs n8n_nginx_proxy --tail=50

# Check n8n logs
docker logs n8n_recon_hub --tail=50

# Check workflow execution in n8n UI
open http://127.0.0.1:5678/executions
```

## Request Flow

```
Browser (http://localhost/)
    ↓
Web Interface (submit form)
    ↓
POST /webhook/demo-recon
    ↓
Nginx (port 80)
    ↓
Proxy to http://n8n-recon:5678/webhook/demo-recon
    ↓
n8n Workflow Execution
    ↓
Response back to browser
```

## Troubleshooting

### Webhook Not Found (404)

**Problem**: n8n returns 404 for webhook

**Solution**:
```bash
# Check if demo workflow is active in n8n
# Go to http://127.0.0.1:5678/workflows
# Make sure demo workflow has green "Active" toggle

# Check webhook path in workflow
# Open workflow → "Webhook: Start Demo Scan" node
# Verify path is: demo-recon
```

### CORS Error in Browser Console

**Problem**: Browser blocks request

**Solution**: Already configured in nginx.conf (lines 52-56)
```nginx
add_header Access-Control-Allow-Origin *;
add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
```

If still failing:
```bash
# Restart nginx
docker-compose restart nginx
```

### Connection Refused

**Problem**: Can't reach webhook

**Solution**:
```bash
# Check all containers are running
docker-compose ps

# Should show:
# - n8n_recon_hub (healthy)
# - n8n_nginx_proxy (healthy)
# - recon_postgres (healthy)

# If not running:
docker-compose up -d
```

### No Response from Workflow

**Problem**: Workflow executes but no response

**Check execution logs**:
```bash
# In n8n UI
http://127.0.0.1:5678/executions

# Click on latest execution
# Check each node for errors
```

## Testing Commands

### Test Direct (bypassing nginx)
```bash
curl -X POST http://127.0.0.1:5678/webhook/demo-recon \
  -H "Content-Type: application/json" \
  -d '{"target": "example.com"}'
```

### Test Through Nginx
```bash
curl -X POST http://localhost/webhook/demo-recon \
  -H "Content-Type: application/json" \
  -d '{"target": "example.com"}'
```

### Test Web Interface with Browser DevTools
```bash
# Open browser
open http://localhost/

# Open DevTools (F12)
# Go to Console tab
# Submit a target
# Check Network tab for the POST request to /webhook/demo-recon
```

## Switch Back to Full Workflow

To use the full workflow with PostgreSQL:

**Edit web-interface/index.html:**
```javascript
// Change line 262 from:
const N8N_WEBHOOK_URL = '/webhook/demo-recon';

// To:
const N8N_WEBHOOK_URL = '/webhook/recon-scan';
```

**Restart nginx:**
```bash
docker-compose restart nginx
```

## Expected Output

### Web Interface Response
```json
{
  "status": "scan_complete",
  "message": "Demo scan completed",
  "timestamp": "2025-11-18T14:30:00.000Z"
}
```

### Scan Results Location
```bash
# Results saved to:
ls -la /tmp/recon/

# View latest results:
ls -lt /tmp/recon/ | head -5
cat /tmp/recon/20251118-143000-scanme-nmap-org/subfinder.txt
cat /tmp/recon/20251118-143000-scanme-nmap-org/amass.txt
```

## Quick Verification Checklist

- [ ] Demo workflow imported into n8n
- [ ] Demo workflow is **Active** (green toggle)
- [ ] Web interface updated (webhook URL = `/webhook/demo-recon`)
- [ ] Nginx restarted (`docker-compose restart nginx`)
- [ ] Can access http://localhost/ in browser
- [ ] Form submits without errors
- [ ] Can see executions in http://127.0.0.1:5678/executions
- [ ] Results appear in `/tmp/recon/`

## Success!

If all steps work, you should see:
1. ✅ Green success message in web interface
2. ✅ New execution in n8n executions list
3. ✅ Results files in `/tmp/recon/{timestamp}-{target}/`

Your webhook is now live at: **http://localhost/webhook/demo-recon**
