#!/bin/bash

# ============================================================================
# n8n Recon Hub - Automated Backup Script
# ============================================================================
# Backs up:
# - PostgreSQL database (users, workflows, credentials, recon data)
# - n8n encryption key
# - Environment file
# - Metadata and checksums
#
# Usage: ./backup.sh [backup_directory]
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BACKUP_BASE_DIR="${1:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_BASE_DIR}/backup_${TIMESTAMP}"
RETENTION_DAYS=30

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
echo "║                n8n RECON HUB - BACKUP UTILITY                          ║"
echo "║                                                                        ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running!"
    exit 1
fi

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    print_warning "Some containers may not be running"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Backup cancelled"
        exit 0
    fi
fi

# Create backup directory
print_header "Initializing Backup"
print_info "Creating backup directory: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

if [ $? -eq 0 ]; then
    print_success "Backup directory created"
else
    print_error "Failed to create backup directory"
    exit 1
fi

echo ""

# ============================================================================
# 1. Backup PostgreSQL Database
# ============================================================================

print_header "Backing Up PostgreSQL Database"
print_info "This includes: users, passwords, workflows, credentials, recon data"

DB_BACKUP_FILE="${BACKUP_DIR}/database.sql"

if docker compose exec -T postgres pg_dump -U recon_user recon_hub > "${DB_BACKUP_FILE}" 2>/dev/null; then
    DB_SIZE=$(du -h "${DB_BACKUP_FILE}" | cut -f1)
    print_success "Database backup completed (${DB_SIZE})"

    # Calculate checksum
    DB_CHECKSUM=$(md5sum "${DB_BACKUP_FILE}" | cut -d' ' -f1)
    print_info "Checksum: ${DB_CHECKSUM}"
else
    print_error "Database backup failed!"
    exit 1
fi

echo ""

# ============================================================================
# 2. Backup n8n Encryption Key
# ============================================================================

print_header "Backing Up n8n Encryption Key"
print_warning "This is CRITICAL - without this key, all credentials are lost!"

if [ -f .env ]; then
    ENCRYPTION_KEY=$(grep "^N8N_ENCRYPTION_KEY=" .env | cut -d'=' -f2)

    if [ -n "${ENCRYPTION_KEY}" ]; then
        echo "${ENCRYPTION_KEY}" > "${BACKUP_DIR}/encryption_key.txt"
        chmod 600 "${BACKUP_DIR}/encryption_key.txt"
        print_success "Encryption key backed up"
        print_warning "Store this key in a password manager!"
    else
        print_error "Encryption key not found in .env!"
    fi
else
    print_error ".env file not found!"
fi

echo ""

# ============================================================================
# 3. Backup Environment File
# ============================================================================

print_header "Backing Up Environment Configuration"

if [ -f .env ]; then
    cp .env "${BACKUP_DIR}/.env"
    chmod 600 "${BACKUP_DIR}/.env"
    print_success "Environment file backed up"
else
    print_error ".env file not found!"
fi

echo ""

# ============================================================================
# 4. Create Backup Metadata
# ============================================================================

print_header "Creating Backup Metadata"

cat > "${BACKUP_DIR}/metadata.txt" << EOF
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║              n8n RECON HUB - BACKUP METADATA                           ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝

Backup Information:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Timestamp:        $(date)
  Backup Directory: ${BACKUP_DIR}
  Database Size:    ${DB_SIZE}
  Database Checksum: ${DB_CHECKSUM}

Container Status:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$(docker compose ps)

Backup Contents:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✓ database.sql           - PostgreSQL full dump
  ✓ encryption_key.txt     - n8n encryption key (CRITICAL!)
  ✓ .env                   - Environment configuration
  ✓ metadata.txt           - This file

Restore Instructions:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

To restore from this backup:

  1. Stop n8n container:
     docker compose stop n8n-recon

  2. Restore encryption key to .env:
     N8N_ENCRYPTION_KEY=\$(cat ${BACKUP_DIR}/encryption_key.txt)

  3. Restore database:
     docker compose exec -T postgres psql -U recon_user -d recon_hub < ${BACKUP_DIR}/database.sql

  4. Restart n8n:
     docker compose start n8n-recon

  5. Verify at http://localhost:5678

For detailed instructions, see: BACKUP_GUIDE.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

print_success "Metadata file created"
echo ""

# ============================================================================
# 5. Optional: Compress Backup
# ============================================================================

print_header "Finalizing Backup"

# Create symlink to latest backup
LATEST_LINK="${BACKUP_BASE_DIR}/latest"
if [ -L "${LATEST_LINK}" ]; then
    rm "${LATEST_LINK}"
fi
ln -s "backup_${TIMESTAMP}" "${LATEST_LINK}"
print_success "Created symlink: ${LATEST_LINK}"

# Calculate total backup size
TOTAL_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
print_success "Total backup size: ${TOTAL_SIZE}"

echo ""

# ============================================================================
# 6. Cleanup Old Backups
# ============================================================================

print_header "Cleaning Up Old Backups"
print_info "Removing backups older than ${RETENTION_DAYS} days..."

OLD_BACKUP_COUNT=$(find "${BACKUP_BASE_DIR}" -maxdepth 1 -name "backup_*" -type d -mtime +${RETENTION_DAYS} | wc -l)

if [ "${OLD_BACKUP_COUNT}" -gt 0 ]; then
    find "${BACKUP_BASE_DIR}" -maxdepth 1 -name "backup_*" -type d -mtime +${RETENTION_DAYS} -exec rm -rf {} \;
    print_success "Removed ${OLD_BACKUP_COUNT} old backup(s)"
else
    print_info "No old backups to remove"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================

print_header "Backup Complete! 🎉"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                        ║${NC}"
echo -e "${GREEN}║                     BACKUP COMPLETED SUCCESSFULLY                      ║${NC}"
echo -e "${GREEN}║                                                                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Backup Location:${NC}"
echo -e "  ${GREEN}${BACKUP_DIR}${NC}"
echo ""

echo -e "${CYAN}Backup Contents:${NC}"
echo -e "  ✓ PostgreSQL database (${DB_SIZE})"
echo -e "  ✓ n8n encryption key"
echo -e "  ✓ Environment configuration"
echo -e "  ✓ Metadata and checksums"
echo ""

echo -e "${CYAN}Quick Access:${NC}"
echo -e "  Latest backup: ${GREEN}${BACKUP_BASE_DIR}/latest${NC}"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  ⚠️  IMPORTANT REMINDERS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${RED}1.${NC} Store the encryption key in a ${YELLOW}password manager${NC}"
echo -e "  ${RED}2.${NC} Keep backups in ${YELLOW}multiple locations${NC} (3-2-1 rule)"
echo -e "  ${RED}3.${NC} Test restores ${YELLOW}regularly${NC} to verify backups work"
echo -e "  ${RED}4.${NC} Secure backup files with ${YELLOW}proper permissions${NC}"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  NEXT STEPS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${YELLOW}Verify backup integrity:${NC}"
echo -e "    cat ${BACKUP_DIR}/metadata.txt"
echo ""
echo -e "  ${YELLOW}Copy to remote location:${NC}"
echo -e "    rsync -avz ${BACKUP_DIR}/ user@remote:/backups/"
echo ""
echo -e "  ${YELLOW}Test restore (dry run):${NC}"
echo -e "    ./restore.sh ${BACKUP_DIR} --dry-run"
echo ""

echo -e "${GREEN}Backup completed at: $(date)${NC}"
echo ""
