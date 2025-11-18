#!/bin/bash

# =============================================================================
# n8n Red Team Hub - Database Migration Runner
# =============================================================================
# This script applies database migrations to the running PostgreSQL container
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================${NC}"
    echo ""
}

# Check if .env exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo "Please create .env file with database credentials"
    exit 1
fi

# Load environment variables
source .env

# Check if postgres container is running
if ! docker compose ps postgres | grep -q "Up"; then
    print_error "PostgreSQL container is not running!"
    echo "Start the containers with: docker compose up -d"
    exit 1
fi

print_header "Database Migration Runner"

# Get migration file
MIGRATION_FILE="${1:-migrations/001_red_team_enhancements.sql}"

if [ ! -f "$MIGRATION_FILE" ]; then
    print_error "Migration file not found: $MIGRATION_FILE"
    echo "Usage: $0 [migration_file.sql]"
    exit 1
fi

print_info "Migration file: $MIGRATION_FILE"
print_info "Database: ${POSTGRES_DB:-recon_hub}"
print_info "User: ${POSTGRES_USER:-recon_user}"

# Confirm before proceeding
echo ""
read -p "Apply this migration? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Migration cancelled"
    exit 0
fi

print_info "Applying migration..."

# Apply migration
if docker compose exec -T postgres psql -U "${POSTGRES_USER:-recon_user}" -d "${POSTGRES_DB:-recon_hub}" < "$MIGRATION_FILE"; then
    print_success "Migration applied successfully!"

    # Show migration status
    print_info "Checking migration status..."
    docker compose exec -T postgres psql -U "${POSTGRES_USER:-recon_user}" -d "${POSTGRES_DB:-recon_hub}" -c "SELECT version, applied_at, description FROM schema_migrations ORDER BY version DESC LIMIT 5;"

    # Show table count
    echo ""
    print_info "Database tables:"
    docker compose exec -T postgres psql -U "${POSTGRES_USER:-recon_user}" -d "${POSTGRES_DB:-recon_hub}" -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;"

    print_success "Database is ready for Red Team operations!"
else
    print_error "Migration failed!"
    echo "Check the error messages above for details"
    exit 1
fi
