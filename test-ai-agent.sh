#!/bin/bash

# ============================================================================
# AI Agent Test Script
# ============================================================================
# This script tests the AI Agent interface with various scenarios
#
# Usage: ./test-ai-agent.sh
# ============================================================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
WEBHOOK_URL="http://localhost/webhook/ai-agent"
SESSION_ID="test_session_$(date +%s)"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

send_message() {
    local message=$1
    local use_session=${2:-true}

    echo ""
    echo -e "${MAGENTA}User:${NC} $message"
    echo ""

    local payload
    if [ "$use_session" = "true" ]; then
        payload="{\"message\": \"$message\", \"session_id\": \"$SESSION_ID\"}"
    else
        payload="{\"message\": \"$message\"}"
    fi

    response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H 'Content-Type: application/json' \
        -d "$payload")

    success=$(echo "$response" | jq -r '.success // false')
    agent_response=$(echo "$response" | jq -r '.response // "No response"')
    action=$(echo "$response" | jq -r '.agent_response.action // "unknown"')
    confidence=$(echo "$response" | jq -r '.agent_response.confidence // 0')

    echo -e "${CYAN}Agent Response:${NC}"
    echo "$agent_response"
    echo ""
    echo -e "${YELLOW}Action:${NC} $action | ${YELLOW}Confidence:${NC} $confidence | ${YELLOW}Success:${NC} $success"
    echo ""

    if [ "$success" = "false" ]; then
        print_error "Request failed"
        return 1
    else
        print_success "Request succeeded"
        return 0
    fi
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

preflight_checks() {
    print_header "Pre-flight Checks"

    # Check if n8n is running
    if curl -s http://localhost:5678/healthz > /dev/null 2>&1; then
        print_success "n8n is running"
    else
        print_error "n8n is not running. Start with: docker compose up -d"
        exit 1
    fi

    # Check if Ollama is running
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        print_success "Ollama is running"
    else
        print_error "Ollama is not running"
        exit 1
    fi

    # Check if llama3.2:1b model exists
    if docker exec recon_ollama ollama list | grep -q "llama3.2:1b"; then
        print_success "llama3.2:1b model is available"
    else
        print_error "llama3.2:1b model not found"
        echo "         Pull it with: docker exec recon_ollama ollama pull llama3.2:1b"
        exit 1
    fi

    # Check if Redis is running
    if docker ps | grep -q recon_redis; then
        print_success "Redis is running"
    else
        print_error "Redis is not running"
        exit 1
    fi

    # Check if Chroma is running
    if docker ps | grep -q recon_chroma; then
        print_success "Chroma vector DB is running"
    else
        print_error "Chroma is not running (optional for RAG)"
    fi

    echo ""
}

# ============================================================================
# Test Cases
# ============================================================================

test_basic_scan() {
    print_header "Test 1: Basic Scan Request"
    send_message "Scan scanme.nmap.org" true
    sleep 2
}

test_planning() {
    print_header "Test 2: Planning Request"
    send_message "Create a plan for testing api.example.com" true
    sleep 2
}

test_multi_turn() {
    print_header "Test 3: Multi-turn Conversation"

    print_info "Message 1: Initial request"
    send_message "I need to test a web application" true
    sleep 2

    print_info "Message 2: Follow-up (same session)"
    send_message "It's a WordPress site at blog.example.com" true
    sleep 2
}

test_status_query() {
    print_header "Test 4: Status Query"
    send_message "What's the status of recent scans?" true
    sleep 2
}

test_tool_recommendation() {
    print_header "Test 5: Tool Recommendation"
    send_message "What tools should I use for subdomain enumeration?" true
    sleep 2
}

test_ip_target() {
    print_header "Test 6: IP Address Target"
    send_message "Scan 192.168.1.1" true
    sleep 2
}

test_help() {
    print_header "Test 7: Help Request"
    send_message "What can you do?" true
    sleep 2
}

test_complex_scenario() {
    print_header "Test 8: Complex Scenario"
    send_message "I found a login page with potential SQL injection. The URL is https://vulnerable.example.com/login.php and it uses MySQL. What should I do?" true
    sleep 2
}

test_new_session() {
    print_header "Test 9: New Session (No Session ID)"
    send_message "Quick test of new session" false
    sleep 2
}

# ============================================================================
# Performance Test
# ============================================================================

test_performance() {
    print_header "Performance Test"

    print_info "Sending 5 requests to measure response time..."
    echo ""

    total_time=0
    count=0

    for i in {1..5}; do
        start=$(date +%s%N)

        curl -s -X POST "$WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d "{\"message\": \"Test $i\", \"session_id\": \"perf_test_$i\"}" > /dev/null

        end=$(date +%s%N)
        elapsed=$((($end - $start) / 1000000)) # Convert to milliseconds

        echo -e "  Request $i: ${elapsed}ms"
        total_time=$(($total_time + $elapsed))
        count=$(($count + 1))
    done

    avg_time=$(($total_time / $count))
    echo ""
    echo -e "${CYAN}Average Response Time:${NC} ${avg_time}ms"
    echo ""

    if [ $avg_time -lt 5000 ]; then
        print_success "Performance is excellent (<5s)"
    elif [ $avg_time -lt 10000 ]; then
        print_success "Performance is good (<10s)"
    else
        print_error "Performance is slow (>10s) - consider optimizing"
    fi

    echo ""
}

# ============================================================================
# Analytics
# ============================================================================

show_analytics() {
    print_header "Agent Decision Analytics"

    print_info "Querying agent_decisions table..."
    echo ""

    # Check if table exists and has data
    decision_count=$(docker exec -it recon_postgres psql -U recon_user -d recon_hub -t -c "SELECT COUNT(*) FROM agent_decisions WHERE session_id LIKE 'test_session_%'" 2>/dev/null | tr -d '[:space:]' || echo "0")

    if [ "$decision_count" -gt 0 ]; then
        echo -e "${CYAN}Decisions logged during this test session:${NC} $decision_count"
        echo ""

        # Show action distribution
        echo -e "${CYAN}Action Distribution:${NC}"
        docker exec -it recon_postgres psql -U recon_user -d recon_hub -c "SELECT action_taken, COUNT(*) as count FROM agent_decisions WHERE session_id LIKE 'test_session_%' GROUP BY action_taken ORDER BY count DESC"

        echo ""

        # Show average confidence
        echo -e "${CYAN}Average Confidence:${NC}"
        docker exec -it recon_postgres psql -U recon_user -d recon_hub -c "SELECT ROUND(AVG(confidence)::numeric, 2) as avg_confidence FROM agent_decisions WHERE session_id LIKE 'test_session_%'"

    else
        print_info "No decisions logged yet (table may not exist or workflow not imported)"
    fi

    echo ""
}

# ============================================================================
# Cleanup
# ============================================================================

cleanup() {
    print_header "Cleanup"

    print_info "Removing test session from Redis..."
    # Note: Redis HTTP interface may vary, this is a placeholder
    # curl -X DELETE "http://localhost:6379/DEL/ai_session:$SESSION_ID" > /dev/null 2>&1 || true

    print_info "Test session ID was: $SESSION_ID"
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    clear

    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                        ║"
    echo "║                     AI AGENT INTERFACE TESTER                          ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    preflight_checks

    echo -e "${YELLOW}Starting tests with session: ${SESSION_ID}${NC}"
    echo ""
    sleep 2

    # Run all tests
    test_basic_scan
    test_planning
    test_multi_turn
    test_status_query
    test_tool_recommendation
    test_ip_target
    test_help
    test_complex_scenario
    test_new_session

    # Performance test
    test_performance

    # Show analytics
    show_analytics

    # Cleanup
    cleanup

    print_header "All Tests Complete!"
    echo -e "${GREEN}Test session completed successfully!${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Review agent responses above"
    echo "  2. Check n8n execution logs for workflow details"
    echo "  3. Query agent_decisions table for detailed analytics"
    echo "  4. Try the web interface at http://localhost:8080 (if configured)"
    echo ""
}

# Run main
main
