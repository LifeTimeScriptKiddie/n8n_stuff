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
    MINIO_PASSWORD=$(generate_password 24)
    CREDENTIAL_KEY=$(generate_hex_key 16)

    # Export for use in create_credentials_file()
    export POSTGRES_PASSWORD
    export N8N_PASSWORD
    export ENCRYPTION_KEY
    export MINIO_PASSWORD
    export CREDENTIAL_KEY

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

# MinIO Object Storage
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=${MINIO_PASSWORD}

# Credential Encryption Key (for secure credential storage)
CREDENTIAL_ENCRYPTION_KEY=${CREDENTIAL_KEY}

# ============================================================================
# LLM Configuration
# ============================================================================

# Model Profile Selection
# Options: minimal, efficient, standard, full, custom
# - minimal:   Ultra-lightweight (~3GB) - llama3.2:1b, phi3:mini, nomic-embed-text
# - efficient: Auto-quantized (~8GB) - llama3.2:1b, llama2:7b, mistral:7b-instruct, nomic-embed-text
# - standard:  Balanced (~13GB) - Multiple small + 7-8B models
# - full:      Complete suite (~25GB) - All models including code analysis (10 models)
# - custom:    Define your own via LLM_CUSTOM_MODELS
LLM_MODEL_PROFILE=efficient

# Custom Models (only used when LLM_MODEL_PROFILE=custom)
# Comma-separated list of model names
# Example: LLM_CUSTOM_MODELS=llama3.2:1b,mistral:7b-instruct-q4_0,nomic-embed-text
# LLM_CUSTOM_MODELS=

# Optional: Slack Webhook for Notifications
# SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxx/xxx/xxx
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

📦 MinIO Object Storage
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Console:  http://localhost:9001
   API:      http://localhost:9000
   Username: minioadmin
   Password: ${MINIO_PASSWORD}

   Buckets:  raw-evidence, reports

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 Redis Cache
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Host:     localhost:6379
   Purpose:  Job queues, ephemeral credential storage

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
# Apply Database Migrations
# ============================================================================

setup_ollama() {
    print_header "Setting Up Ollama LLM"

    # Check if Ollama container is running
    if ! docker compose ps | grep -q "recon_ollama.*Up"; then
        print_warning "Ollama container is not running"
        return
    fi

    # Wait for Ollama to be ready
    print_info "Waiting for Ollama to be ready..."
    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            print_success "Ollama is ready"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    echo ""

    if [ $attempt -eq $max_attempts ]; then
        print_warning "Ollama health check timeout"
        return
    fi

    # Get model profile from environment (default: standard)
    MODEL_PROFILE=${LLM_MODEL_PROFILE:-standard}

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  MODEL PROFILE: ${YELLOW}${MODEL_PROFILE}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Define models based on profile
    case $MODEL_PROFILE in
        minimal)
            print_info "Minimal profile: Ultra-lightweight models only (~3GB total)"
            echo ""
            MODELS=(
                "llama3.2:1b:~1GB - Ultra-fast reasoning (1B params)"
                "phi3:mini:~2.3GB - Microsoft Phi-3 Mini (3.8B params)"
                "nomic-embed-text:~274MB - Embeddings for RAG"
            )
            ;;
        efficient)
            print_info "Efficient profile: Quantized models for low memory (~8GB total)"
            echo ""
            MODELS=(
                "llama3.2:1b:~1GB - Ultra-fast reasoning"
                "llama2:7b:~3.8GB - Llama-2 7B (auto-quantized)"
                "mistral:7b-instruct:~4GB - Mistral 7B instruction tuned"
                "nomic-embed-text:~274MB - Embeddings for RAG"
            )
            ;;
        standard)
            print_info "Standard profile: Balanced models (~13GB total)"
            echo ""
            MODELS=(
                "llama3.2:1b:~1GB - Ultra-fast lightweight"
                "llama3.2:~2GB - Main reasoning model"
                "llama3:8b:~4.7GB - Llama-3 8B (auto-quantized)"
                "mistral:7b-instruct:~4GB - Mistral 7B instruction tuned"
                "nomic-embed-text:~274MB - Embeddings for RAG"
            )
            ;;
        full)
            print_info "Full profile: Complete model suite (~25GB total)"
            echo ""
            MODELS=(
                "llama3.2:1b:~1GB - Ultra-fast lightweight (1B params)"
                "llama3.2:3b:~2GB - Standard reasoning (3B params)"
                "llama2:7b:~3.8GB - Llama-2 7B (auto-quantized)"
                "llama3:8b:~4.7GB - Llama-3 8B (auto-quantized)"
                "mistral:7b-instruct:~4GB - Mistral 7B instruction tuned"
                "phi3:mini:~2.3GB - Microsoft Phi-3 Mini (3.8B)"
                "gemma:2b:~1.6GB - Google Gemma 2B"
                "codellama:7b:~4GB - Code analysis model"
                "deepseek-coder:6.7b:~3.8GB - Code-specialized model"
                "nomic-embed-text:~274MB - Embeddings for RAG"
            )
            ;;
        custom)
            print_info "Custom profile: Using models from LLM_CUSTOM_MODELS env var"
            echo ""
            if [ -z "$LLM_CUSTOM_MODELS" ]; then
                print_error "LLM_CUSTOM_MODELS environment variable not set!"
                return
            fi
            IFS=',' read -ra MODELS <<< "$LLM_CUSTOM_MODELS"
            ;;
        *)
            print_warning "Unknown profile '$MODEL_PROFILE', using 'standard'"
            MODEL_PROFILE="standard"
            MODELS=(
                "llama3.2:~2GB - Main reasoning model"
                "mistral:7b-instruct:~4GB - Fast instruction following"
                "nomic-embed-text:~274MB - Embeddings for RAG"
            )
            ;;
    esac

    # Pull each model
    for model_spec in "${MODELS[@]}"; do
        # Extract model name and description
        model_name=$(echo "$model_spec" | cut -d':' -f1-2)
        model_desc=$(echo "$model_spec" | cut -d':' -f3-)

        echo ""
        print_info "Pulling ${CYAN}${model_name}${NC} ${model_desc}"
        echo ""

        if docker exec recon_ollama ollama pull "$model_name"; then
            print_success "${model_name} pulled successfully"
        else
            print_warning "Failed to pull ${model_name}"
            print_info "You can pull it manually later with:"
            echo "         docker exec recon_ollama ollama pull ${model_name}"
        fi
    done

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    print_success "Ollama model setup complete!"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

apply_migrations() {
    print_header "Applying Database Migrations"

    # Check if migrations directory exists
    if [ ! -d "migrations" ]; then
        print_info "No migrations directory found - skipping migrations"
        echo ""
        return
    fi

    # Count migration files
    migration_count=$(find migrations -name "*.sql" -type f | wc -l | tr -d ' ')

    if [ "$migration_count" -eq 0 ]; then
        print_info "No migration files found - skipping migrations"
        echo ""
        return
    fi

    print_info "Found $migration_count migration file(s)"
    echo ""

    # Apply each migration in order
    for migration in migrations/*.sql; do
        if [ -f "$migration" ]; then
            migration_name=$(basename "$migration")
            print_info "Applying migration: $migration_name"

            if docker compose exec -T postgres psql -U recon_user -d recon_hub < "$migration" 2>&1 | grep -q "ERROR"; then
                print_warning "Migration $migration_name had errors (may be already applied)"
            else
                print_success "Migration $migration_name applied successfully"
            fi
        fi
    done

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

    if docker compose ps | grep -q "n8n_nginx_proxy.*Up"; then
        print_success "Nginx proxy container is running"
    else
        print_warning "Nginx proxy container is NOT running"
    fi

    if docker compose ps | grep -q "recon_ollama.*Up"; then
        print_success "Ollama LLM container is running"
    else
        print_warning "Ollama LLM container is NOT running"
    fi

    if docker compose ps | grep -q "recon_redis.*Up"; then
        print_success "Redis container is running"
    else
        print_warning "Redis container is NOT running"
    fi

    if docker compose ps | grep -q "recon_minio.*Up"; then
        print_success "MinIO container is running"
    else
        print_warning "MinIO container is NOT running"
    fi

    if docker compose ps | grep -q "recon_chroma.*Up"; then
        print_success "Chroma vector DB container is running"
    else
        print_warning "Chroma vector DB container is NOT running"
    fi

    # Check network
    if docker network ls | grep -q "recon_network"; then
        print_success "Recon network created"
    fi

    # Check volumes
    for vol in recon_postgres_data recon_n8n_data recon_workspace recon_loot recon_redis_data recon_minio_data recon_ollama_data recon_chroma_data; do
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
    echo -e "${CYAN}Pivot Tools (v3):${NC}"
    docker compose exec -T n8n-recon bash -c "which proxychains 2>/dev/null || which proxychains4 2>/dev/null" > /dev/null && print_success "proxychains"
    docker compose exec -T n8n-recon bash -c "which sshpass" > /dev/null && print_success "sshpass"
    docker compose exec -T n8n-recon bash -c "which nc" > /dev/null && print_success "netcat"
    docker compose exec -T n8n-recon bash -c "which ssh" > /dev/null && print_success "ssh client"

    echo ""
    echo -e "${CYAN}Cloud Tools (v4):${NC}"
    docker compose exec -T n8n-recon bash -c "az --version 2>&1 | head -1" && print_success "Azure CLI"
    docker compose exec -T n8n-recon bash -c "scout --version 2>&1 | head -1" && print_success "ScoutSuite"
    docker compose exec -T n8n-recon bash -c "roadrecon --help 2>&1 | head -1" && print_success "ROADrecon"

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
    echo -e "  ${MAGENTA}Core (Phase A):${NC}"
    echo -e "  ✓ projects              ✓ hosts                 ✓ ports"
    echo -e "  ✓ evidence              ✓ scan_jobs             ✓ rate_limits"
    echo -e "  ✓ audit_log             ✓ system_config"
    echo ""
    echo -e "  ${MAGENTA}Credentials (Phase B):${NC}"
    echo -e "  ✓ secure_credentials    ✓ credential_usage      ✓ relationships"
    echo -e "  ✓ credential_test_queue"
    echo ""
    echo -e "  ${MAGENTA}Findings (Phase C):${NC}"
    echo -e "  ✓ findings              ✓ loot                  ✓ enrichment"
    echo -e "  ✓ notifications         ✓ approval_queue"
    echo ""
    echo -e "  ${MAGENTA}Pivoting (Phase D):${NC}"
    echo -e "  ✓ ssh_tunnels           ✓ pivot_queue           ✓ internal_networks"
    echo -e "  ✓ proxy_chains"
    echo ""
    echo -e "  ${MAGENTA}Cloud (Phase E):${NC}"
    echo -e "  ✓ azure_tenants         ✓ azure_subscriptions   ✓ azure_resources"
    echo -e "  ✓ azure_ad_objects      ✓ azure_role_assignments"
    echo -e "  ✓ cloud_findings        ✓ cloud_credential_cache"
    echo ""
    echo -e "  ${MAGENTA}RAG & Learning (Phase F):${NC}"
    echo -e "  ✓ knowledge_vectors     ✓ tool_success_metrics  ✓ attack_patterns"
    echo -e "  ✓ agent_decisions       ✓ learning_feedback"
    echo ""
    echo -e "  ${MAGENTA}Legacy:${NC}"
    echo -e "  ✓ subdomain_intel       ✓ network_scans         ✓ recon_sessions"
    echo ""
    echo -e "  ${MAGENTA}Note:${NC} Database migrations from migrations/ automatically applied"
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
    echo -e "${CYAN}  NEXT STEPS - AUTONOMOUS AGENT SYSTEM${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${YELLOW}Step 1: LLM Models Configuration${NC}"
    echo ""
    echo -e "  Current profile: ${GREEN}${LLM_MODEL_PROFILE:-efficient}${NC}"
    echo -e "  Models already pulled during setup (if Ollama was running)"
    echo ""
    echo -e "  ${CYAN}To manage models:${NC}"
    echo -e "  ${GREEN}./manage-models.sh list${NC}                  # List installed models"
    echo -e "  ${GREEN}./manage-models.sh pull-profile minimal${NC}  # Pull minimal set (~2GB)"
    echo -e "  ${GREEN}./manage-models.sh pull-profile efficient${NC} # Pull efficient set (~5GB)"
    echo -e "  ${GREEN}./manage-models.sh pull-profile standard${NC} # Pull standard set (~10GB)"
    echo -e "  ${GREEN}./manage-models.sh pull-profile full${NC}     # Pull full set (~20GB)"
    echo -e "  ${GREEN}./manage-models.sh info${NC}                  # Show model info & recommendations"
    echo ""
    echo -e "  ${CYAN}Or pull models manually:${NC}"
    echo -e "  ${GREEN}docker exec recon_ollama ollama pull llama3.2:1b${NC}           # Ultra-fast 1B model"
    echo -e "  ${GREEN}docker exec recon_ollama ollama pull mistral:7b-instruct-q4_0${NC} # Quantized Mistral"
    echo -e "  ${GREEN}docker exec recon_ollama ollama pull llama3:7b-q4_0${NC}       # Quantized Llama-3"
    echo ""
    echo -e "  ${YELLOW}Step 2: Import Workflows (IN ORDER - Critical!)${NC}"
    echo -e "  1. Open ${GREEN}http://localhost:5678${NC} and login"
    echo -e "  2. Import workflows from ${YELLOW}workflows/${NC} directory IN THIS ORDER:"
    echo -e "     ${MAGENTA}Foundation (1-6):${NC}"
    echo -e "     01_rag_query_helper.json → 02_knowledge_embedder.json → 03_learning_extractor.json"
    echo -e "     04_tool_analyzer.json → 05_feedback_processor.json → 06_feed_ingestor.json"
    echo -e "     ${MAGENTA}Agents (7-12):${NC}"
    echo -e "     07_agent_orchestrator.json → 08_agent_recon.json → 09_agent_web.json"
    echo -e "     10_agent_network.json → 11_agent_cloud.json → 12_agent_api.json"
    echo -e "     ${MAGENTA}Exploitation (13-14):${NC}"
    echo -e "     13_approval_handler.json → 14_exploit_runner.json"
    echo ""
    echo -e "  ${YELLOW}Step 3: Create Test Project${NC}"
    echo -e "  ${GREEN}docker exec -it recon_postgres psql -U recon_user -d recon_hub -c \"INSERT INTO projects (name, scope) VALUES ('Test', '[\\\"scanme.nmap.org\\\"]') RETURNING id;\"${NC}"
    echo ""
    echo -e "  ${YELLOW}Step 4: Test Autonomous System${NC}"
    echo -e "  ${GREEN}curl -X POST http://localhost:5678/webhook/agent/orchestrate \\${NC}"
    echo -e "  ${GREEN}  -H 'Content-Type: application/json' \\${NC}"
    echo -e "  ${GREEN}  -d '{\"target\": \"scanme.nmap.org\", \"project_id\": \"YOUR_UUID\", \"scan_mode\": \"quick\"}'${NC}"
    echo ""
    echo -e "  ${YELLOW}Pivot Capability (v3):${NC}"
    echo -e "  - Auto-pivots on SSH credential success"
    echo -e "  - Max 4 hops, tunnels last until project ends"
    echo -e "  - Full internal recon through SOCKS proxies"
    echo -e "  - View active tunnels: ${GREEN}SELECT * FROM active_tunnels;${NC}"
    echo ""
    echo -e "  ${YELLOW}Cloud Scanning (v4):${NC}"
    echo -e "  1. Import ${YELLOW}workflows/pentest_v4_cloud.json${NC}"
    echo -e "  2. Add Azure credential to secure_credentials (type: azure_service_principal)"
    echo -e "  3. Test: ${GREEN}curl -X POST http://localhost/webhook/pentest/v4/cloud -H 'Content-Type: application/json' -d '{\"project_id\": \"UUID\", \"tenant_id\": \"TENANT\", \"credential_id\": \"CRED_UUID\", \"scan_mode\": \"full-cloud\"}'${NC}"
    echo -e "  - Scan modes: aad-enum, resource-discovery, blob-scan, privilege-audit, keyvault-access, api-abuse, full-cloud"
    echo -e "  - Uses Azure CLI + ScoutSuite + ROADrecon"
    echo -e "  - Findings saved to cloud_findings table"
    echo ""
    echo -e "  ${YELLOW}Legacy Web Interface:${NC}"
    echo -e "  1. Import workflow from ${YELLOW}web-interface/n8n-recon-workflow.json${NC}"
    echo -e "  2. Open ${GREEN}http://localhost:8080${NC} to submit targets"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  OPTIONAL: CLAUDE DESKTOP INTEGRATION${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Connect Claude Desktop to n8n for AI-assisted workflow management!"
    echo ""
    echo -e "  ${YELLOW}Quick Setup (Optional):${NC}"
    echo -e "  1. Generate n8n API Key: ${GREEN}http://localhost:5678${NC} → Settings → API"
    echo -e "  2. Add to Claude Desktop config (see below for path)"
    echo -e "  3. Restart Claude Desktop"
    echo ""
    echo -e "  ${YELLOW}Config file location:${NC}"
    echo -e "  • macOS:   ${GREEN}~/Library/Application Support/Claude/claude_desktop_config.json${NC}"
    echo -e "  • Windows: ${GREEN}%APPDATA%\\Claude\\claude_desktop_config.json${NC}"
    echo -e "  • Linux:   ${GREEN}~/.config/Claude/claude_desktop_config.json${NC}"
    echo ""
    echo -e "  ${YELLOW}What you'll be able to do:${NC}"
    echo -e "  • Ask Claude: \"List my n8n workflows\""
    echo -e "  • \"Debug the agent orchestrator\""
    echo -e "  • \"Create a workflow to monitor SSL certificates\""
    echo -e "  • \"Show recent executions\""
    echo ""
    echo -e "  📖 Full guide: ${GREEN}cat CLAUDE_DESKTOP_N8N_MCP_SETUP.md${NC}"
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
    setup_ollama
    apply_migrations
    verify_installation
    verify_tools
    print_final_info
}

# Run the setup
main
