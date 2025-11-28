# Demo Standalone Recon Workflow (Simplified)

## Overview

This is a **PostgreSQL-free minimal demo workflow** for quick reconnaissance testing. No database, no complexity - just core scanning.

## What It Does

```
Webhook Input → Validate Target → Create Output Dir → [Subfinder + Amass] → Merge → Response
```

**Current Features:**
- ✅ Takes target domain as input
- ✅ Runs Subfinder + Amass in parallel
- ✅ Merges results
- ✅ Saves output to `/tmp/recon/{timestamp}-{target}/`
- ✅ Returns completion status

**Tools Included:**
- **Subfinder** - Subdomain enumeration
- **Amass** - Passive DNS enumeration

## Quick Start

### 1. Import Workflow

```bash
# In n8n UI:
# Workflows → Import from File → Select demo_standalone_recon.json
```

### 2. Activate Workflow

Click the "Active" toggle in top-right corner of n8n

### 3. Test It

```bash
curl -X POST http://localhost:5678/webhook/demo-recon \
  -H "Content-Type: application/json" \
  -d '{"target": "scanme.nmap.org"}'
```

### Expected Response

```json
{
  "status": "scan_complete",
  "message": "Demo scan completed",
  "timestamp": "2025-11-18T12:00:00.000Z"
}
```

### Check Results

```bash
# Find latest scan directory
ls -lt /tmp/recon/ | head -5

# View subfinder results
cat /tmp/recon/20251118-120000-scanme-nmap-org/subfinder.txt

# View amass results
cat /tmp/recon/20251118-120000-scanme-nmap-org/amass.txt
```

## Output Files

After scan completes, check `/tmp/recon/{timestamp}-{target}/`:

```
/tmp/recon/20251118-120000-example-com/
├── subfinder.txt    # Subfinder subdomain list
└── amass.txt        # Amass subdomain list
```

## Adding More Features

This is a minimal workflow. You can easily add more nodes:

### Add httpx Probing

1. Add "Execute Command" node after "Merge Subdomain Sources"
2. Command: `httpx -l /tmp/recon/.../all_subdomains.txt -silent -json`
3. Connect to response node

### Add Nuclei Scanning

1. Add "Execute Command" node after httpx
2. Command: `nuclei -l /tmp/recon/.../live_urls.txt -silent -json`
3. Parse results

### Add Code Nodes for Processing

1. Add "Code" node to parse and deduplicate
2. Add "Code" node to write formatted reports
3. Add "Code" node to generate summaries

## Example: Adding Deduplication

Add a Code node between Merge and Response:

```javascript
// Deduplicate subdomains
const subdomains = new Set();

const subfinderOutput = $('Subfinder: Subdomain Enumeration').first().json.stdout || '';
subfinderOutput.split('\n').forEach(line => {
  if (line.trim()) subdomains.add(line.trim().toLowerCase());
});

const amassOutput = $('Amass: Passive DNS').first().json.stdout || '';
amassOutput.split('\n').forEach(line => {
  if (line.trim()) subdomains.add(line.trim().toLowerCase());
});

const uniqueList = Array.from(subdomains).sort();

return [{
  json: {
    subdomains: uniqueList,
    count: uniqueList.length
  }
}];
```

## Troubleshooting

### "Workflow could not be activated"

- Check that webhook path is unique
- Ensure n8n has permission to create webhooks

### "Tools not found" errors

Ensure tools are installed in your Docker container:
```bash
docker exec -it n8n-recon which subfinder
docker exec -it n8n-recon which amass
```

### Permission denied on /tmp/recon

```bash
# Fix permissions
docker exec -it n8n-recon mkdir -p /tmp/recon
docker exec -it n8n-recon chmod 777 /tmp/recon
```

## Differences from Full Workflow

| Feature | Full Workflow | This Demo |
|---------|--------------|-----------|
| Nodes | 30-40 per phase | 7 total |
| Database | PostgreSQL required | None |
| Processing | Full parsing & analysis | Basic execution only |
| Output | DB + Files + Reports | Files only |
| Duration | 10-30 minutes | 1-2 minutes |

## Next Steps

1. **Test the basic workflow** - Make sure it runs
2. **Add deduplication** - Code node to merge results
3. **Add httpx** - Probe live hosts
4. **Add nuclei** - Scan for vulnerabilities
5. **Add report generation** - Format and save results
6. **Add PostgreSQL** - For persistence (optional)

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Subfinder](https://github.com/projectdiscovery/subfinder)
- [Amass](https://github.com/owasp-amass/amass)
- [httpx](https://github.com/projectdiscovery/httpx)
- [Nuclei](https://github.com/projectdiscovery/nuclei)

## License

For educational and authorized testing only.

**⚠️ WARNING**: Only scan targets you own or have explicit permission to test!
