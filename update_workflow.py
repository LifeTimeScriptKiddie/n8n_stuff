#!/usr/bin/env python3
import json
import requests
from requests.auth import HTTPBasicAuth

# n8n API configuration
N8N_URL = "http://localhost:5678"
USERNAME = "tester@tester.com"
PASSWORD = "6o9p1WW5q7LnzRGk0uKPEb7u"
WORKFLOW_ID = "bKzuKozzRoGa5zgW"

# Get current workflow
response = requests.get(
    f"{N8N_URL}/api/v1/workflows/{WORKFLOW_ID}",
    auth=HTTPBasicAuth(USERNAME, PASSWORD),
    headers={"Accept": "application/json"}
)

if response.status_code != 200:
    print(f"Error fetching workflow: {response.status_code}")
    print(response.text)
    exit(1)

workflow = response.json()

# Find and update the Run Scope Validator node
updated = False
for node in workflow.get('nodes', []):
    if node.get('name') == 'Run Scope Validator':
        old_cmd = node['parameters']['command']
        if not old_cmd.startswith('='):
            new_cmd = '=' + old_cmd
            node['parameters']['command'] = new_cmd
            print(f"Updated command from: {old_cmd}")
            print(f"Updated command to: {new_cmd}")
            updated = True
            break

if not updated:
    print("Could not find 'Run Scope Validator' node or command already updated")
    exit(0)

# Update workflow via API
response = requests.put(
    f"{N8N_URL}/api/v1/workflows/{WORKFLOW_ID}",
    auth=HTTPBasicAuth(USERNAME, PASSWORD),
    headers={"Content-Type": "application/json", "Accept": "application/json"},
    json=workflow
)

if response.status_code == 200:
    print("✓ Workflow updated successfully!")
else:
    print(f"Error updating workflow: {response.status_code}")
    print(response.text)
    exit(1)
