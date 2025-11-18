#!/bin/bash

# ============================================================================
# n8n Reconnaissance Hub - Automated Setup Script
# ============================================================================
# This script automates the deployment of a complete offensive security
# automation platform using n8n with integrated pentesting tools.
#
# Usage: ./setup.sh
# ============================================================================

set -e  # Exit on any error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ============================================================================
# Helper Functions
# ============================================================================

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                        ║"
    echo "║              n8n RECONNAISSANCE HUB - AUTOMATED SETUP                  ║"
    echo "║                                                                        ║"
    echo "║           Offensive Security Automation Platform Installer            ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

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

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

generate_password() {
    local length=$1
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-${length}
}

generate_hex_key() {
    local length=$1
    openssl rand -hex ${length}
}

# ============================================================================
# Prerequisites Check
# ============================================================================

check_prerequisites() {
    print_header "Checking Prerequisites"

    local all_good=true

    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker installed: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    else
        print_error "Docker is not installed"
        echo "         Install from: https://docs.docker.com/get-docker/"
        all_good=false
    fi

    # Check Docker Compose
    if docker compose version &> /dev/null; then
        print_success "Docker Compose installed: $(docker compose version | cut -d' ' -f4)"
    else
        print_error "Docker Compose is not installed"
        all_good=false
    fi

    # Check OpenSSL
    if command -v openssl &> /dev/null; then
        print_success "OpenSSL installed: $(openssl version | cut -d' ' -f2)"
    else
        print_error "OpenSSL is not installed"
        all_good=false
    fi

    # Check Docker daemon
    if docker info &> /dev/null; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
        all_good=false
    fi

    # Check disk space (need at least 5GB)
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -gt 5 ]; then
        print_success "Sufficient disk space available: ${available_space}GB"
    else
        print_warning "Low disk space: ${available_space}GB (5GB+ recommended)"
    fi

    if [ "$all_good" = false ]; then
        echo ""
        print_error "Please install missing prerequisites before continuing"
        exit 1
    fi

    echo ""
}

# ============================================================================
# Environment Configuration
# ============================================================================

create_env_file() {
    print_header "Generating Environment Configuration"

    if [ -f .env ]; then
        print_warning ".env file already exists"
        read -p "$(echo -e ${YELLOW}Do you want to overwrite it? This will generate new passwords! ${NC}[y/N]: )" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing .env file"
            echo ""
            return
        fi
        print_info "Backing up existing .env to .env.backup.$(date +%s)"
        cp .env ".env.backup.$(date +%s)"
    fi

    print_info "Generating secure random credentials..."

    # Generate credentials
    POSTGRES_PASSWORD=$(generate_password 32)
    N8N_PASSWORD=$(generate_password 24)
    ENCRYPTION_KEY=$(generate_hex_key 32)

    # Export for use in create_credentials_file()
    export POSTGRES_PASSWORD
    export N8N_PASSWORD
    export ENCRYPTION_KEY

    # Create .env file
    cat > .env << EOF
# ============================================================================
# n8n Reconnaissance Hub - Environment Configuration
# ============================================================================
# Auto-generated on $(date)
# DO NOT COMMIT THIS FILE TO VERSION CONTROL
# ============================================================================

# PostgreSQL Database
POSTGRES_USER=recon_user
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=recon_hub

# n8n Authentication
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}

# n8n Encryption Key (BACKUP THIS!)
N8N_ENCRYPTION_KEY=${ENCRYPTION_KEY}

# n8n Webhook Configuration
# WEBHOOK_URL is the base URL where n8n is accessible
# n8n automatically appends /webhook/[path] to this
WEBHOOK_URL=http://localhost

# Timezone
TIMEZONE=UTC
EOF

    print_success ".env file created successfully"
    echo ""
}

# ============================================================================
# Create Credentials File
# ============================================================================

create_credentials_file() {
    print_header "Creating Credentials File"

    # Create credentials file
    cat > CREDENTIALS.txt << EOF
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║          n8n RECONNAISSANCE HUB - ACCESS CREDENTIALS                   ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝

Generated: $(date)

⚠️  CRITICAL SECURITY NOTICE:
    • Keep this file EXTREMELY secure
    • NEVER commit to version control
    • Store in encrypted vault or password manager
    • Losing the encryption key = losing all n8n credentials

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 n8n Web Interface
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   URL:      http://localhost:5678
   Username: admin
   Password: ${N8N_PASSWORD}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Target Submission Web Form
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   URL:      http://localhost:8080
   Auth:     None (single-user interface)
   Purpose:  Submit targets for automated reconnaissance

   Setup:    Import web-interface/n8n-recon-workflow.json to n8n first!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🗄️  PostgreSQL Database
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Host:     localhost:5432
   Database: recon_hub
   Username: recon_user
   Password: ${POSTGRES_PASSWORD}

   Connection String:
   postgresql://recon_user:${POSTGRES_PASSWORD}@localhost:5432/recon_hub

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔐 Encryption Key (BACKUP THIS IMMEDIATELY!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ${ENCRYPTION_KEY}

   ⚠️  IF YOU LOSE THIS KEY, ALL ENCRYPTED CREDENTIALS IN n8n WILL BE
      PERMANENTLY LOST! Store it in a password manager NOW!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

    chmod 600 CREDENTIALS.txt
    print_success "CREDENTIALS.txt created with access information"
    echo ""
}

# ============================================================================
# Docker Build and Deploy
# ============================================================================

build_containers() {
    print_header "Building Docker Containers"

    print_info "This may take 10-20 minutes on first run..."
    print_info "Installing: n8n + 20+ security tools + SecLists + exploitdb"
    echo ""

    if docker compose build; then
        print_success "Docker containers built successfully"
    else
        print_error "Failed to build Docker containers"
        exit 1
    fi

    echo ""
}

deploy_containers() {
    print_header "Deploying Reconnaissance Hub"

    # Stop any existing containers
    if docker compose ps | grep -q "Up"; then
        print_info "Stopping existing containers..."
        docker compose down
    fi

    print_info "Starting all services..."
    docker compose up -d

    echo ""
    print_info "Waiting for services to initialize..."
    sleep 10

    # Wait for PostgreSQL
    print_info "Checking PostgreSQL database..."
    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if docker compose exec -T postgres pg_isready -U recon_user -d recon_hub &> /dev/null; then
            print_success "PostgreSQL is ready and healthy"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    echo ""

    if [ $attempt -eq $max_attempts ]; then
        print_error "PostgreSQL failed to start"
        exit 1
    fi

    # Wait for n8n
    print_info "Checking n8n web interface..."
    attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:5678/healthz &> /dev/null; then
            print_success "n8n is ready and healthy"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 3
    done
    echo ""

    if [ $attempt -eq $max_attempts ]; then
        print_warning "n8n health check timeout (may still be initializing)"
    fi

    echo ""
}

# ============================================================================
# Verification
# ============================================================================

verify_installation() {
    print_header "Verifying Installation"

    # Check containers
    if docker compose ps | grep -q "n8n_recon_hub.*Up"; then
        print_success "n8n recon hub container is running"
    else
        print_error "n8n recon hub container is NOT running"
    fi

    if docker compose ps | grep -q "recon_postgres.*Up"; then
        print_success "PostgreSQL container is running"
    else
        print_error "PostgreSQL container is NOT running"
    fi

    if docker compose ps | grep -q "n8n_web_interface.*Up"; then
        print_success "Web interface container is running"
    else
        print_warning "Web interface container is NOT running"
    fi

    # Check network
    if docker network ls | grep -q "recon_network"; then
        print_success "Recon network created"
    fi

    # Check volumes
    for vol in recon_postgres_data recon_n8n_data recon_workspace recon_loot; do
        if docker volume ls | grep -q "$vol"; then
            print_success "Volume '$vol' created"
        fi
    done

    echo ""
}

verify_tools() {
    print_header "Verifying Security Tools Installation"

    print_info "Testing installed tools..."
    echo ""

    # Test critical tools
    echo -e "${CYAN}Core Tools:${NC}"
    docker compose exec -T n8n-recon bash -c "nmap --version | head -1" && print_success "nmap"
    docker compose exec -T n8n-recon bash -c "nxc --version 2>&1 | head -1" && print_success "NetExec (nxc)"
    docker compose exec -T n8n-recon bash -c "sqlmap --version 2>&1 | head -1" && print_success "sqlmap"
    docker compose exec -T n8n-recon bash -c "hydra -h 2>&1 | head -1" && print_success "hydra"

    echo ""
    echo -e "${CYAN}Go-Based Tools:${NC}"
    docker compose exec -T n8n-recon bash -c "subfinder -version 2>&1 | head -1" && print_success "subfinder"
    docker compose exec -T n8n-recon bash -c "nuclei -version 2>&1 | head -1" && print_success "nuclei"
    docker compose exec -T n8n-recon bash -c "httpx -version 2>&1 | head -1" && print_success "httpx"
    docker compose exec -T n8n-recon bash -c "ffuf -V 2>&1 | head -1" && print_success "ffuf"
    docker compose exec -T n8n-recon bash -c "katana -version 2>&1 | head -1" && print_success "katana"
    docker compose exec -T n8n-recon bash -c "naabu -version 2>&1 | head -1" && print_success "naabu"

    echo ""
    echo -e "${CYAN}Wordlists & Scripts:${NC}"
    docker compose exec -T n8n-recon bash -c "ls /opt/SecLists/Discovery/DNS/ | head -3 | wc -l" > /dev/null && print_success "SecLists installed"
    docker compose exec -T n8n-recon bash -c "searchsploit -h | head -1" && print_success "searchsploit (exploitdb)"
    docker compose exec -T n8n-recon bash -c "ls /usr/share/nmap/scripts/vulners.nse" > /dev/null && print_success "nmap vulners script"
    docker compose exec -T n8n-recon bash -c "ls /usr/share/nmap/scripts/vulscan/" > /dev/null && print_success "nmap vulscan script"

    echo ""
}

# ============================================================================
# Final Information
# ============================================================================

print_final_info() {
    print_header "Setup Complete! 🎉"

    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                        ║"
    echo "║     🚀 n8n RECONNAISSANCE HUB IS READY FOR OFFENSIVE OPERATIONS! 🚀    ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  ACCESS INFORMATION${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  🌐 n8n Interface:  ${GREEN}http://localhost:5678${NC}"
    echo -e "  👤 Username:       ${GREEN}admin${NC}"
    echo -e "  🔑 Password:       ${YELLOW}See CREDENTIALS.txt${NC}"
    echo ""
    echo -e "  🎯 Web Form:       ${GREEN}http://localhost:8080${NC}"
    echo -e "  📝 Purpose:        Submit targets for automated scanning"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  INSTALLED TOOLS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${MAGENTA}Subdomain Enum:${NC}    subfinder, amass, assetfinder"
    echo -e "  ${MAGENTA}Network Scan:${NC}      nmap (+vulners/vulscan), naabu"
    echo -e "  ${MAGENTA}Web Fuzzing:${NC}       ffuf, katana, waybackurls, gau"
    echo -e "  ${MAGENTA}Cred Testing:${NC}      NetExec (nxc), hydra"
    echo -e "  ${MAGENTA}Vuln Scanning:${NC}     nuclei (auto-updated templates)"
    echo -e "  ${MAGENTA}Exploitation:${NC}      sqlmap, searchsploit"
    echo -e "  ${MAGENTA}Wordlists:${NC}         SecLists (complete collection)"
    echo ""

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  USEFUL COMMANDS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${YELLOW}Start services:${NC}          docker compose up -d"
    echo -e "  ${YELLOW}Stop services:${NC}           docker compose down"
    echo -e "  ${YELLOW}View logs:${NC}               docker compose logs -f n8n-recon"
    echo -e "  ${YELLOW}Access container:${NC}        docker compose exec n8n-recon bash"
    echo -e "  ${YELLOW}Check tool:${NC}              docker compose exec n8n-recon nuclei -version"
    echo -e "  ${YELLOW}Database access:${NC}         docker compose exec postgres psql -U recon_user -d recon_hub"
    echo ""

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  DATABASE TABLES${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ✓ subdomain_intel        ✓ network_scans"
    echo -e "  ✓ smb_enum              ✓ vulnerabilities"
    echo -e "  ✓ fuzzing_results       ✓ credentials"
    echo -e "  ✓ web_technologies      ✓ nuclei_results"
    echo -e "  ✓ sqli_results          ✓ recon_sessions"
    echo ""

    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ⚠️  CRITICAL SECURITY WARNINGS${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${RED}1.${NC} Backup ${YELLOW}N8N_ENCRYPTION_KEY${NC} from CREDENTIALS.txt ${RED}NOW!${NC}"
    echo -e "  ${RED}2.${NC} Never commit ${YELLOW}.env${NC} or ${YELLOW}CREDENTIALS.txt${NC} to version control"
    echo -e "  ${RED}3.${NC} Only use on ${YELLOW}authorized targets${NC} - unauthorized use is illegal"
    echo -e "  ${RED}4.${NC} This platform has ${YELLOW}NET_RAW${NC} capabilities - use responsibly"
    echo -e "  ${RED}5.${NC} Change default passwords before production use"
    echo ""

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  NEXT STEPS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${YELLOW}To use the Web Interface:${NC}"
    echo -e "  1. Open ${GREEN}http://localhost:5678${NC} and login"
    echo -e "  2. Import workflow from ${YELLOW}web-interface/n8n-recon-workflow.json${NC}"
    echo -e "  3. Configure PostgreSQL credential in the workflow"
    echo -e "  4. Activate the workflow"
    echo -e "  5. Open ${GREEN}http://localhost:8080${NC} to submit targets"
    echo ""
    echo -e "  ${YELLOW}To create custom workflows:${NC}"
    echo -e "  6. Use Execute Command nodes to run security tools"
    echo -e "  7. Use PostgreSQL nodes to store results in database"
    echo -e "  8. Check ${YELLOW}README.md${NC} for example workflow snippets"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Happy Hacking! 🎯 Use your powers responsibly! 🛡️${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================================================
# Main Execution Flow
# ============================================================================

main() {
    print_banner

    check_prerequisites
    create_env_file
    create_credentials_file
    build_containers
    deploy_containers
    verify_installation
    verify_tools
    print_final_info
}

# Run the setup
main
