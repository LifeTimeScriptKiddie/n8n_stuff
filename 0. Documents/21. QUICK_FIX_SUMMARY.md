# Demo Workflow - Final Fix Summary

## What Was Wrong & How It's Fixed

### Version History

**Version 1 (Broken):**
```javascript
command: "subfinder -d {{ $('Extract & Validate Target').item.json.target }} ..."
```
❌ Problem: Expressions not evaluated, passed literally to shell

**Version 2 (Broken):**
```javascript
command: "=`subfinder -d ${$json.target} ...`"
```
❌ Problem: Shell syntax error - /bin/sh doesn't support this syntax

**Version 3 (WORKING):**
```javascript
command: "='subfinder -d ' + $json.target + ' -silent ...'"
```
✅ Fixed: Uses n8n string concatenation, works with /bin/sh

## Current Command Syntax

### Create Output Directory
```javascript
='mkdir -p ' + $json.output_dir
```

### Subfinder Node
```javascript
='subfinder -d ' + $json.target + ' -silent -all -o ' + $json.output_dir + '/subfinder.txt && cat ' + $json.output_dir + '/subfinder.txt'
```

### Amass Node
```javascript
='amass enum -passive -d ' + $json.target + ' -silent -timeout 3 -o ' + $json.output_dir + '/amass.txt && cat ' + $json.output_dir + '/amass.txt || echo'
```

## Re-import Steps (Manual)

### 1. Delete Old Workflow
1. Go to http://127.0.0.1:5678/workflows
2. Find "Demo: Standalone Recon (No DB)"
3. Click ⋮ (three dots) → Delete
4. Confirm

### 2. Import Fixed Workflow
1. Click "Import from File"
2. Select: `/Users/tester/Documents/n8n_stuff/workflows/demo_standalone_recon.json`
3. Click Import

### 3. Activate
1. Toggle "Active" (top-right)
2. Should turn GREEN

### 4. Verify (IMPORTANT!)
Click on "Create Output Directory" node:
- Command field should have **fx icon** (expression mode)
- Should show: `='mkdir -p ' + $json.output_dir`
- Should NOT have backticks or `${}`

### 5. Test
```bash
curl -X POST http://127.0.0.1:5678/webhook/demo-recon \
  -H "Content-Type: application/json" \
  -d '{"target":"scanme.nmap.org"}'
```

Expected response:
```json
{"status":"scan_complete","message":"Demo scan completed","timestamp":"..."}
```

## n8n Expression Syntax Reference

### ✅ CORRECT - String Concatenation
```javascript
='command ' + $json.variable + ' more text'
```

### ✅ ALSO CORRECT - Template in Expression
```javascript
=`command ${$json.variable} more text`
```
(But this caused issues with /bin/sh in our case)

### ❌ WRONG - No = prefix
```javascript
command {{ $json.variable }}
```

### ❌ WRONG - Shell variable syntax
```javascript
command $variable
```

## Execution Flow

```
Web Interface (http://localhost/)
    ↓
POST /webhook/demo-recon
    ↓
Nginx Proxy (port 80)
    ↓
n8n (http://n8n-recon:5678)
    ↓
Webhook Node: Receives {"target":"example.com"}
    ↓
Extract & Validate: Creates session_id, output_dir
    ↓
Create Directory: mkdir -p /tmp/recon/20251118-...
    ↓
[Subfinder + Amass] Run in parallel
    ↓
Merge Results
    ↓
Respond: {"status":"scan_complete",...}
    ↓
Browser receives success message
```

## Verification Checklist

After re-import:

- [ ] Old workflow deleted from n8n
- [ ] New workflow imported successfully
- [ ] Workflow shows as Active (green toggle)
- [ ] Execute Command nodes use string concatenation syntax
- [ ] No backticks or `${}` in command fields
- [ ] Direct curl test returns 200 OK
- [ ] Web interface submits successfully
- [ ] Results appear in /tmp/recon/

## Troubleshooting

### Still getting "syntax error: bad substitution"
→ You're still using the old workflow. Delete and re-import.

### Webhook returns 404
→ Workflow not activated. Toggle Active switch in n8n.

### Browser shows "The string did not match the expected pattern"
→ Clear browser cache (Cmd+Shift+R) or use incognito mode.

### No response from webhook
→ Check n8n logs: `docker logs n8n_recon_hub --tail=50`

## Files

- `workflows/demo_standalone_recon.json` - Fixed workflow
- `FINAL_REIMPORT.sh` - Interactive re-import script
- `QUICK_FIX_SUMMARY.md` - This file

## Success Indicators

✅ Workflow executes without errors
✅ Creates directory in /tmp/recon/
✅ Subfinder and Amass run successfully
✅ Returns JSON response
✅ Web interface shows success message

## Example Successful Execution

```bash
$ curl -X POST http://localhost/webhook/demo-recon \
  -H "Content-Type: application/json" \
  -d '{"target":"scanme.nmap.org"}'

{"status":"scan_complete","message":"Demo scan completed","timestamp":"2025-11-18T20:00:00.000Z"}

$ ls /tmp/recon/
20251118-200000-scanme-nmap-org/

$ ls /tmp/recon/20251118-200000-scanme-nmap-org/
amass.txt  subfinder.txt

$ wc -l /tmp/recon/20251118-200000-scanme-nmap-org/*.txt
   0 amass.txt
   1 subfinder.txt
   1 total
```

---

**Ready to proceed?** Run `./FINAL_REIMPORT.sh` for step-by-step guidance!
