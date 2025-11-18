#!/bin/bash

# ============================================================================
# n8n Recon Hub - Automated Restore Script
# ============================================================================
# Restores:
# - PostgreSQL database (users, workflows, credentials, recon data)
# - n8n encryption key
# - Environment configuration
#
# Usage: ./restore.sh <backup_directory> [--dry-run]
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper functions
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

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Banner
clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                        ║"
echo "║                n8n RECON HUB - RESTORE UTILITY                         ║"
echo "║                                                                        ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check arguments
if [ $# -eq 0 ]; then
    print_error "Usage: ./restore.sh <backup_directory> [--dry-run]"
    echo ""
    echo "Examples:"
    echo "  ./restore.sh backups/backup_20251028_143022"
    echo "  ./restore.sh backups/latest"
    echo "  ./restore.sh backups/backup_20251028_143022 --dry-run"
    echo ""
    exit 1
fi

BACKUP_DIR="$1"
DRY_RUN=false

if [ "$2" == "--dry-run" ]; then
    DRY_RUN=true
    print_warning "DRY RUN MODE - No changes will be made"
    echo ""
fi

# Verify backup directory exists
if [ ! -d "${BACKUP_DIR}" ]; then
    print_error "Backup directory not found: ${BACKUP_DIR}"
    exit 1
fi

print_success "Backup directory found: ${BACKUP_DIR}"
echo ""

# ============================================================================
# Verify Backup Contents
# ============================================================================

print_header "Verifying Backup Contents"

REQUIRED_FILES=("database.sql" "encryption_key.txt" ".env")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "${BACKUP_DIR}/${file}" ]; then
        FILE_SIZE=$(du -h "${BACKUP_DIR}/${file}" | cut -f1)
        print_success "${file} found (${FILE_SIZE})"
    else
        print_error "${file} missing!"
        MISSING_FILES+=("${file}")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo ""
    print_error "Backup is incomplete. Missing files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - ${file}"
    done
    exit 1
fi

echo ""

# Show backup metadata if available
if [ -f "${BACKUP_DIR}/metadata.txt" ]; then
    print_info "Backup metadata:"
    cat "${BACKUP_DIR}/metadata.txt" | head -20
    echo ""
fi

# ============================================================================
# Pre-Restore Checks
# ============================================================================

print_header "Pre-Restore Checks"

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running!"
    exit 1
fi
print_success "Docker is running"

# Check if containers are running
if docker compose ps | grep -q "Up"; then
    print_success "Containers are running"
else
    print_warning "Some containers are not running"
    print_info "Starting containers..."
    if [ "${DRY_RUN}" = false ]; then
        docker compose up -d
        sleep 10
    fi
fi

# Check PostgreSQL connectivity
if docker compose exec -T postgres pg_isready -U recon_user -d recon_hub &> /dev/null; then
    print_success "PostgreSQL is ready"
else
    print_error "Cannot connect to PostgreSQL!"
    exit 1
fi

echo ""

# ============================================================================
# Warning & Confirmation
# ============================================================================

print_header "⚠️  WARNING ⚠️"
echo ""
echo -e "${RED}This will OVERWRITE your current database!${NC}"
echo ""
echo -e "${YELLOW}Current data will be LOST, including:${NC}"
echo -e "  • All current users and passwords"
echo -e "  • All current workflows"
echo -e "  • All current credentials"
echo -e "  • All current execution history"
echo -e "  • All current recon data"
echo ""
echo -e "${YELLOW}They will be replaced with data from:${NC}"
echo -e "  ${CYAN}${BACKUP_DIR}${NC}"
echo ""

if [ "${DRY_RUN}" = false ]; then
    read -p "$(echo -e ${RED}Are you ABSOLUTELY sure? Type 'RESTORE' to continue: ${NC})" -r
    echo
    if [ "$REPLY" != "RESTORE" ]; then
        print_info "Restore cancelled"
        exit 0
    fi
fi

echo ""

# ============================================================================
# Create Pre-Restore Backup
# ============================================================================

if [ "${DRY_RUN}" = false ]; then
    print_header "Creating Safety Backup"
    print_info "Backing up current database before restore..."

    SAFETY_BACKUP_DIR="./backups/pre_restore_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${SAFETY_BACKUP_DIR}"

    if docker compose exec -T postgres pg_dump -U recon_user recon_hub > "${SAFETY_BACKUP_DIR}/database.sql" 2>/dev/null; then
        print_success "Safety backup created at: ${SAFETY_BACKUP_DIR}"
    else
        print_warning "Could not create safety backup (database may be empty)"
    fi

    echo ""
fi

# ============================================================================
# 1. Stop n8n Container
# ============================================================================

print_header "Stopping n8n Container"

if [ "${DRY_RUN}" = false ]; then
    docker compose stop n8n-recon
    print_success "n8n container stopped"
else
    print_info "[DRY RUN] Would stop n8n container"
fi

echo ""

# ============================================================================
# 2. Restore Encryption Key
# ============================================================================

print_header "Restoring n8n Encryption Key"

BACKUP_ENCRYPTION_KEY=$(cat "${BACKUP_DIR}/encryption_key.txt")
CURRENT_ENCRYPTION_KEY=$(grep "^N8N_ENCRYPTION_KEY=" .env 2>/dev/null | cut -d'=' -f2 || echo "")

if [ "${CURRENT_ENCRYPTION_KEY}" == "${BACKUP_ENCRYPTION_KEY}" ]; then
    print_success "Encryption key already matches backup"
else
    print_warning "Encryption keys differ!"
    echo "  Current:  ${CURRENT_ENCRYPTION_KEY}"
    echo "  Backup:   ${BACKUP_ENCRYPTION_KEY}"

    if [ "${DRY_RUN}" = false ]; then
        # Backup current .env
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

        # Update encryption key in .env
        if grep -q "^N8N_ENCRYPTION_KEY=" .env; then
            sed -i.bak "s/^N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=${BACKUP_ENCRYPTION_KEY}/" .env
        else
            echo "N8N_ENCRYPTION_KEY=${BACKUP_ENCRYPTION_KEY}" >> .env
        fi

        print_success "Encryption key updated in .env"
    else
        print_info "[DRY RUN] Would update encryption key in .env"
    fi
fi

echo ""

# ============================================================================
# 3. Check and Fix PostgreSQL Password Mismatch
# ============================================================================

print_header "Checking PostgreSQL Password Compatibility"

BACKUP_POSTGRES_PASSWORD=$(grep "^POSTGRES_PASSWORD=" "${BACKUP_DIR}/.env" | cut -d'=' -f2)
CURRENT_POSTGRES_PASSWORD=$(grep "^POSTGRES_PASSWORD=" .env | cut -d'=' -f2)

if [ "${CURRENT_POSTGRES_PASSWORD}" != "${BACKUP_POSTGRES_PASSWORD}" ]; then
    print_warning "PostgreSQL passwords don't match!"
    echo "  Current:  ${CURRENT_POSTGRES_PASSWORD}"
    echo "  Backup:   ${BACKUP_POSTGRES_PASSWORD}"
    echo ""
    print_info "The PostgreSQL container needs to be recreated with the backup's password"

    if [ "${DRY_RUN}" = false ]; then
        print_info "Stopping all containers..."
        docker compose down

        print_info "Updating .env with backup's database password..."
        sed -i.bak "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${BACKUP_POSTGRES_PASSWORD}/" .env

        print_info "Recreating containers with correct password..."
        docker compose up -d

        print_info "Waiting for PostgreSQL to be ready..."
        sleep 15

        # Wait for postgres to be ready
        max_attempts=30
        attempt=0
        while [ $attempt -lt $max_attempts ]; do
            if docker compose exec -T postgres pg_isready -U recon_user -d recon_hub &> /dev/null; then
                print_success "PostgreSQL is ready with correct password"
                break
            fi
            attempt=$((attempt + 1))
            sleep 2
        done

        if [ $attempt -eq $max_attempts ]; then
            print_error "PostgreSQL failed to start with new password"
            exit 1
        fi
    else
        print_info "[DRY RUN] Would recreate postgres container with backup password"
    fi
else
    print_success "PostgreSQL password matches backup"
fi

echo ""

# ============================================================================
# 4. Restore Database
# ============================================================================

print_header "Restoring PostgreSQL Database"

DB_SIZE=$(du -h "${BACKUP_DIR}/database.sql" | cut -f1)
print_info "Database backup size: ${DB_SIZE}"

if [ "${DRY_RUN}" = false ]; then
    print_info "Restoring database... (this may take a few minutes)"

    # Drop all tables and restore
    if docker compose exec -T postgres psql -U recon_user -d recon_hub < "${BACKUP_DIR}/database.sql" &> /dev/null; then
        print_success "Database restored successfully"

        # Count restored users
        USER_COUNT=$(docker compose exec -T postgres psql -U recon_user -d recon_hub -t -c "SELECT COUNT(*) FROM \"user\";" 2>/dev/null | tr -d ' ')
        print_info "Restored ${USER_COUNT} user(s)"

        # Count restored workflows
        WORKFLOW_COUNT=$(docker compose exec -T postgres psql -U recon_user -d recon_hub -t -c "SELECT COUNT(*) FROM workflow_entity;" 2>/dev/null | tr -d ' ')
        print_info "Restored ${WORKFLOW_COUNT} workflow(s)"
    else
        print_error "Database restore failed!"
        print_error "Check logs and try manual restore"
        exit 1
    fi
else
    print_info "[DRY RUN] Would restore database from ${BACKUP_DIR}/database.sql"
fi

echo ""

# ============================================================================
# 5. Restart n8n Container
# ============================================================================

print_header "Restarting n8n Container"

if [ "${DRY_RUN}" = false ]; then
    docker compose start n8n-recon

    print_info "Waiting for n8n to start..."
    sleep 10

    # Check if n8n is healthy
    if curl -s http://localhost:5678/healthz &> /dev/null; then
        print_success "n8n is running and healthy"
    else
        print_warning "n8n may still be starting up"
        print_info "Check status: docker compose logs -f n8n-recon"
    fi
else
    print_info "[DRY RUN] Would restart n8n container"
fi

echo ""

# ============================================================================
# 6. Verification
# ============================================================================

print_header "Verifying Restore"

if [ "${DRY_RUN}" = false ]; then
    # Check containers
    if docker compose ps | grep -q "n8n_recon_hub.*Up"; then
        print_success "n8n container is running"
    else
        print_error "n8n container is not running!"
    fi

    # Check database
    if docker compose exec -T postgres pg_isready -U recon_user -d recon_hub &> /dev/null; then
        print_success "PostgreSQL is healthy"
    else
        print_error "PostgreSQL is not responding!"
    fi

    # Check users
    USER_COUNT=$(docker compose exec -T postgres psql -U recon_user -d recon_hub -t -c "SELECT COUNT(*) FROM \"user\";" 2>/dev/null | tr -d ' ')
    if [ "${USER_COUNT}" -gt 0 ]; then
        print_success "${USER_COUNT} user(s) found in database"
    else
        print_warning "No users found in database"
    fi
else
    print_info "[DRY RUN] Would verify containers and database"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================

if [ "${DRY_RUN}" = true ]; then
    print_header "Dry Run Complete"
    echo ""
    echo -e "${CYAN}No changes were made.${NC}"
    echo ""
    echo -e "${YELLOW}To perform actual restore, run:${NC}"
    echo -e "  ./restore.sh ${BACKUP_DIR}"
    echo ""
else
    print_header "Restore Complete! 🎉"
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                        ║${NC}"
    echo -e "${GREEN}║                    RESTORE COMPLETED SUCCESSFULLY                      ║${NC}"
    echo -e "${GREEN}║                                                                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${CYAN}Restored From:${NC}"
    echo -e "  ${GREEN}${BACKUP_DIR}${NC}"
    echo ""

    echo -e "${CYAN}What Was Restored:${NC}"
    echo -e "  ✓ PostgreSQL database (${DB_SIZE})"
    echo -e "  ✓ ${USER_COUNT} user(s)"
    echo -e "  ✓ ${WORKFLOW_COUNT} workflow(s)"
    echo -e "  ✓ n8n encryption key"
    echo ""

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  NEXT STEPS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${YELLOW}1. Verify n8n is accessible:${NC}"
    echo -e "     open http://localhost:5678"
    echo ""
    echo -e "  ${YELLOW}2. Login with restored user credentials${NC}"
    echo ""
    echo -e "  ${YELLOW}3. Verify workflows are present:${NC}"
    echo -e "     Check workflows list in n8n UI"
    echo ""
    echo -e "  ${YELLOW}4. Test credentials work:${NC}"
    echo -e "     Open a workflow and test connections"
    echo ""
    echo -e "  ${YELLOW}5. If issues occur, check logs:${NC}"
    echo -e "     docker compose logs -f n8n-recon"
    echo ""

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  ℹ️  SAFETY BACKUP${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Your previous database was backed up to:"
    echo -e "  ${CYAN}${SAFETY_BACKUP_DIR}${NC}"
    echo ""
    echo -e "  To rollback if needed:"
    echo -e "  ./restore.sh ${SAFETY_BACKUP_DIR}"
    echo ""

    echo -e "${GREEN}Restore completed at: $(date)${NC}"
    echo ""
fi
