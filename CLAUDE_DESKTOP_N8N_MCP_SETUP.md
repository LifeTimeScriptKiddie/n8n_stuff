# Connecting Claude Desktop to n8n via MCP Server

**Created:** 2025-12-13
**Updated:** 2025-12-14
**Purpose:** Enable Claude Desktop to interact with your n8n instance through the Model Context Protocol (MCP)

---

## Overview

This guide explains how to connect Claude Desktop to your locally-running n8n instance using the Model Context Protocol. This allows Claude to:
- View and manage your n8n workflows
- Execute workflows
- Query workflow status and executions
- Help build and debug n8n automations

---

## Architecture Overview

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│ Claude Desktop  │  MCP    │  n8n-mcp Server  │  HTTP   │   n8n Instance  │
│  (Your Computer)│ ◄────►  │   (via npx)      │ ◄────►  │ (Docker/Local)  │
└─────────────────┘  stdio  └──────────────────┘  API    └─────────────────┘
                                                  :5678
```

**Why this architecture:**
- **n8n can run anywhere**: Docker, local install, cloud - doesn't matter as long as it's accessible
- **MCP server runs on your computer**: The `n8n-mcp` package runs via `npx` on your machine, not in Docker
- **Communication**: MCP server connects to n8n's REST API (typically `http://localhost:5678` for local setups)
- **Claude Desktop**: Communicates with MCP server via stdio (standard input/output)

---

## Prerequisites

✅ **Required:**
- n8n instance running and accessible (Docker, local, or cloud)
- n8n accessible at a URL (e.g., `http://localhost:5678` or your domain)
- Claude Desktop installed (macOS, Windows, or Linux)
- Node.js/npm installed on your computer (for npx)
- n8n API key (to be generated in Step 1)

**Common n8n setups this works with:**
- n8n in Docker with port exposed to localhost
- n8n installed locally via npm
- n8n cloud instance (use your cloud URL instead of localhost)
- Self-hosted n8n with domain name

---

## Step 1: Generate n8n API Key

### Why:
The MCP server needs an API key to authenticate with your n8n instance. Without it, the MCP server cannot access your workflows or execute any n8n operations.

### How:

1. Open n8n in your browser: `http://localhost:5678`
2. Log in with your credentials:
   - Username: `admin`
   - Password: Check your `CREDENTIALS.txt` file or `.env` file (`N8N_BASIC_AUTH_PASSWORD`)
3. Navigate to: **Settings** → **API** → **Create API Key**
4. Copy the generated API key (it's a JWT token)
5. Save it securely

**Example API key format:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzZmQxZDZ...
```

---

## Step 2: Verify n8n API Access

### Why:
Before configuring Claude Desktop, we need to confirm that:
1. n8n is running and healthy
2. The API is accessible from the host machine
3. The API key works correctly

### Commands:

**Check n8n health:**
```bash
curl http://localhost:5678/healthz
```
Expected output: `{"status":"ok"}`

**Test API authentication:**
```bash
curl -H "X-N8N-API-KEY: YOUR_API_KEY_HERE" http://localhost:5678/api/v1/workflows
```

**Why `X-N8N-API-KEY` header:**
n8n's API requires the API key in a custom header (not standard `Authorization: Bearer`). This is n8n-specific authentication.

Expected output: JSON array of your workflows

---

## Step 3: Choose the Correct MCP Server Package

### The Problem:
The official `@n8n/mcp-server` package **does not exist**. There are several community-built alternatives.

### Available Options:

1. **`n8n-mcp`** (by czlonkowski) ⭐ **RECOMMENDED**
   - Provides full n8n workflow management
   - Works with locally-hosted n8n
   - Actively maintained
   - npm: `n8n-mcp`

2. **`@illuminaresolutions/n8n-mcp-server`**
   - Similar functionality
   - Alternative option

3. **`n8n-mcp-server`** (by leonardsellem)
   - Another community alternative

### Why we chose `n8n-mcp`:
- Most popular in the community
- Well-documented
- Specifically designed for connecting Claude to n8n instances
- Supports local n8n installations
- Uses environment variables for configuration (clean separation of credentials)

---

## Step 4: Configure Claude Desktop

### File Location:
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

### Configuration:

```json
{
  "mcpServers": {
    "n8n": {
      "command": "npx",
      "args": [
        "-y",
        "n8n-mcp"
      ],
      "env": {
        "MCP_MODE": "stdio",
        "LOG_LEVEL": "error",
        "DISABLE_CONSOLE_OUTPUT": "true",
        "N8N_API_URL": "http://localhost:5678",
        "N8N_API_KEY": "YOUR_API_KEY_HERE"
      }
    }
  }
}
```

**For cloud/remote n8n instances**, change the URL:
```json
"N8N_API_URL": "https://your-n8n-domain.com"
```

### Configuration Explained:

| Setting | Value | Why |
|---------|-------|-----|
| `"n8n"` | Server identifier | Any name you want; this is how Claude identifies your n8n instance |
| `"command": "npx"` | Package runner | npx downloads and runs npm packages on-demand without global installation |
| `"-y"` | Auto-confirm | Automatically confirms npx prompts (non-interactive mode) |
| `"n8n-mcp"` | Package name | The actual npm package to run |
| `"MCP_MODE": "stdio"` | **REQUIRED** | Claude Desktop communicates via stdio (standard in/out), not HTTP |
| `"LOG_LEVEL": "error"` | Reduce noise | Only show errors, not debug/info logs |
| `"DISABLE_CONSOLE_OUTPUT": "true"` | Clean output | Prevents JSON parsing errors in Claude Desktop |
| `"N8N_API_URL"` | Your n8n URL | Use `localhost:5678` because MCP runs on host, not in Docker |
| `"N8N_API_KEY"` | Your API key | Authentication token from Step 1 |

### Choosing the Right N8N_API_URL:

**For local n8n (Docker or npm):**
```json
"N8N_API_URL": "http://localhost:5678"
```
- MCP server runs on your computer (via npx)
- Docker exposes n8n's port to localhost
- Local n8n installations also use localhost

**For cloud/remote n8n:**
```json
"N8N_API_URL": "https://your-n8n-instance.com"
```
- Use your n8n cloud URL
- Include `https://` if using SSL/TLS

**Common mistakes:**
- ❌ Using Docker container names (e.g., `http://n8n-recon:5678`) - only works inside Docker network
- ❌ Using `http://host.docker.internal:5678` - only needed if MCP was running IN a container (it's not)
- ❌ Forgetting the port number (`:5678`)
- ❌ Using `http://` for cloud instances that require `https://`

---

## Step 5: Restart Claude Desktop

### Why:
Claude Desktop only loads MCP server configurations at startup. Changes to `claude_desktop_config.json` require a full restart.

### How:

1. **Quit Claude Desktop completely:**
   - Press `Cmd+Q`
   - Or right-click dock icon → Quit
   - **Don't just close the window** - must fully quit the app

2. **Reopen Claude Desktop**

3. **Wait 10-15 seconds** for MCP initialization
   - npx downloads the `n8n-mcp` package (first time only)
   - MCP server starts and connects to n8n

---

## Step 6: Verify Connection

### In Claude Desktop Settings:

1. Open **Settings** → **Developer** → **Local MCP servers**
2. Look for your MCP server (name from config, e.g., `n8n`)
3. Status should show: **Connected** ✅

**If it shows "failed":**
- Check the error message
- See Troubleshooting section below

### In Chat Interface:

Look for the **MCP icon** (🔌 or hammer) in the chat input area. This indicates MCP tools are available.

### Test it:

Ask Claude:
```
"List my n8n workflows"
```

If working, Claude will query your n8n instance and show your workflows.

---

## Troubleshooting

### Error: "Server disconnected"

**Cause:** Wrong package name or connection issue

**Fix:**
1. Verify package name is `n8n-mcp` (not `@n8n/mcp-server`)
2. Check n8n is running: `docker ps | grep n8n_recon_hub`
3. Test API manually: `curl http://localhost:5678/healthz`

### Error: "API authentication failed"

**Cause:** Invalid or expired API key

**Fix:**
1. Test API key: `curl -H "X-N8N-API-KEY: YOUR_KEY" http://localhost:5678/api/v1/workflows`
2. Generate new API key in n8n Settings → API
3. Update `claude_desktop_config.json`
4. Restart Claude Desktop

### Error: "Cannot connect to localhost:5678"

**Cause:** n8n not running, wrong URL, or port not accessible

**Fix:**

**For Docker n8n:**
```bash
# Check if n8n is running
docker ps | grep n8n

# Check port mapping (should show 5678)
docker port <your-n8n-container-name>

# Restart if needed
docker compose restart <your-n8n-service-name>
```

**For all setups:**
```bash
# Test if n8n is accessible
curl http://localhost:5678/healthz

# Should return: {"status":"ok"}
```

**For cloud/remote n8n:**
- Verify the URL is correct and accessible from your computer
- Check firewall rules allow API access
- Ensure API authentication is enabled

### Check MCP Logs:

**macOS log location:**
```bash
tail -f ~/Library/Logs/Claude/mcp*.log
```

### Manual MCP Server Test:

Run the MCP server manually to see detailed errors:
```bash
N8N_API_URL=http://localhost:5678 \
N8N_API_KEY=your_key_here \
npx -y n8n-mcp
```

---

## Security Notes

### ⚠️ API Key Security:

1. **Never commit** `claude_desktop_config.json` to version control
2. **API keys grant full access** to your n8n instance
3. **Rotate keys periodically** in n8n Settings → API
4. **Backup `.env` and `CREDENTIALS.txt`** - they contain your encryption keys

### Port Exposure:

Your current setup exposes ports to `0.0.0.0` (all interfaces):
```yaml
ports:
  - "0.0.0.0:5678:5678"
```

**For production/external networks:**
Consider restricting to localhost only:
```yaml
ports:
  - "127.0.0.1:5678:5678"
```

---

## What You Can Do Now

Once connected, you can ask Claude to:

✅ **List workflows:**
```
"Show me all my n8n workflows"
```

✅ **Execute workflows:**
```
"Run the 'Advanced Attack Surface Scanner' workflow"
```

✅ **Check executions:**
```
"Show me recent workflow executions"
```

✅ **Debug workflows:**
```
"Why is my subdomain enumeration workflow failing?"
```

✅ **Build workflows:**
```
"Create a workflow that monitors SSL certificate expiration"
```

---

## References

- **n8n-mcp GitHub:** https://github.com/czlonkowski/n8n-mcp
- **n8n API Documentation:** https://docs.n8n.io/api/
- **Model Context Protocol:** https://modelcontextprotocol.io
- **Claude Desktop MCP Guide:** https://docs.anthropic.com/claude/docs/mcp

---

## Configuration Summary Template

Fill this out for your specific setup:

| Component | Your Value | Example |
|-----------|------------|---------|
| **n8n URL** | _______________ | `http://localhost:5678` or `https://n8n.yourdomain.com` |
| **n8n API Key** | _______________ | `eyJhbGciOiJIUzI1NiIs...` |
| **MCP Package** | `n8n-mcp` | Installed via npx (auto-downloads) |
| **MCP Server Name** | _______________ | `n8n` (can be any name you choose) |
| **Config File Path** | See below | Depends on your OS |

**Config file locations:**
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

---

## Next Steps After Connection

1. **Import your workflows** to n8n (if not already done)
2. **Ask Claude to analyze** your existing workflows for optimization
3. **Build new workflows** with Claude's assistance
4. **Automate testing** of your recon workflows

---

*Last updated: 2025-12-13*
