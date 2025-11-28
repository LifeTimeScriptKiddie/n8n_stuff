#!/bin/bash

# ============================================================================
# Ollama Model Management Script
# ============================================================================
# This script helps manage LLM models for the n8n reconnaissance hub
#
# Usage:
#   ./manage-models.sh list                    # List installed models
#   ./manage-models.sh pull <model>            # Pull a specific model
#   ./manage-models.sh pull-profile <profile>  # Pull all models for a profile
#   ./manage-models.sh remove <model>          # Remove a model
#   ./manage-models.sh info                    # Show model information
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

# Container name
CONTAINER="recon_ollama"

# ============================================================================
# Helper Functions
# ============================================================================

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

check_ollama() {
    if ! docker ps | grep -q "$CONTAINER"; then
        print_error "Ollama container is not running!"
        echo "         Start with: docker compose up -d ollama"
        exit 1
    fi
}

# ============================================================================
# Commands
# ============================================================================

cmd_list() {
    print_header "Installed Models"
    echo ""
    docker exec "$CONTAINER" ollama list
    echo ""
}

cmd_pull() {
    local model=$1
    if [ -z "$model" ]; then
        print_error "Please specify a model name"
        echo "         Example: ./manage-models.sh pull llama3.2:1b"
        exit 1
    fi

    print_header "Pulling Model: $model"
    echo ""
    docker exec "$CONTAINER" ollama pull "$model"
    echo ""
    print_success "Model pulled successfully!"
}

cmd_pull_profile() {
    local profile=$1
    if [ -z "$profile" ]; then
        print_error "Please specify a profile: minimal, efficient, standard, or full"
        exit 1
    fi

    print_header "Pulling Model Profile: $profile"
    echo ""

    case $profile in
        minimal)
            print_info "Minimal profile: Ultra-lightweight models (~3GB total)"
            models=("llama3.2:1b" "phi3:mini" "nomic-embed-text")
            ;;
        efficient)
            print_info "Efficient profile: Auto-quantized models (~8GB total)"
            models=("llama3.2:1b" "llama2:7b" "mistral:7b-instruct" "nomic-embed-text")
            ;;
        standard)
            print_info "Standard profile: Balanced models (~13GB total)"
            models=("llama3.2:1b" "llama3.2" "llama3:8b" "mistral:7b-instruct" "nomic-embed-text")
            ;;
        full)
            print_info "Full profile: Complete suite (~25GB total)"
            models=("llama3.2:1b" "llama3.2:3b" "llama2:7b" "llama3:8b" "mistral:7b-instruct" "phi3:mini" "gemma:2b" "codellama:7b" "deepseek-coder:6.7b" "nomic-embed-text")
            ;;
        *)
            print_error "Unknown profile: $profile"
            echo "         Valid profiles: minimal, efficient, standard, full"
            exit 1
            ;;
    esac

    echo ""
    for model in "${models[@]}"; do
        echo ""
        print_info "Pulling: ${CYAN}$model${NC}"
        echo ""
        if docker exec "$CONTAINER" ollama pull "$model"; then
            print_success "$model pulled successfully"
        else
            print_warning "Failed to pull $model"
        fi
    done

    echo ""
    print_success "Profile pull complete!"
}

cmd_remove() {
    local model=$1
    if [ -z "$model" ]; then
        print_error "Please specify a model name"
        echo "         Example: ./manage-models.sh remove llama3.2:1b"
        exit 1
    fi

    print_header "Removing Model: $model"
    echo ""

    read -p "$(echo -e ${YELLOW}Are you sure you want to remove $model? ${NC}[y/N]: )" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cancelled"
        exit 0
    fi

    docker exec "$CONTAINER" ollama rm "$model"
    echo ""
    print_success "Model removed successfully!"
}

cmd_info() {
    print_header "Model Information & Recommendations"
    echo ""

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  PROFILE COMPARISON${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${MAGENTA}Minimal Profile (~3GB)${NC}"
    echo "  └─ llama3.2:1b        - Ultra-fast 1B parameter model"
    echo "  └─ phi3:mini          - Microsoft Phi-3 Mini (3.8B params)"
    echo "  └─ nomic-embed-text   - Embeddings for RAG"
    echo "  ${GREEN}Best for: Low memory systems, quick testing${NC}"
    echo ""

    echo -e "${MAGENTA}Efficient Profile (~8GB) ⭐ Recommended${NC}"
    echo "  └─ llama3.2:1b        - Ultra-fast reasoning (1B)"
    echo "  └─ llama2:7b          - Llama-2 7B (auto-quantized)"
    echo "  └─ mistral:7b-instruct - Mistral 7B instruction tuned"
    echo "  └─ nomic-embed-text   - Embeddings for RAG"
    echo "  ${GREEN}Best for: Production use with resource constraints${NC}"
    echo ""

    echo -e "${MAGENTA}Standard Profile (~13GB)${NC}"
    echo "  └─ llama3.2:1b        - Ultra-fast lightweight (1B)"
    echo "  └─ llama3.2           - Main reasoning (3B)"
    echo "  └─ llama3:8b          - Llama-3 8B (auto-quantized)"
    echo "  └─ mistral:7b-instruct - Mistral 7B instruction tuned"
    echo "  └─ nomic-embed-text   - Embeddings for RAG"
    echo "  ${GREEN}Best for: Balanced performance and quality${NC}"
    echo ""

    echo -e "${MAGENTA}Full Profile (~25GB)${NC}"
    echo "  └─ llama3.2:1b        - Ultra-fast lightweight (1B)"
    echo "  └─ llama3.2:3b        - Standard reasoning (3B)"
    echo "  └─ llama2:7b          - Llama-2 7B (auto-quantized)"
    echo "  └─ llama3:8b          - Llama-3 8B (auto-quantized)"
    echo "  └─ mistral:7b-instruct - Mistral 7B instruction tuned"
    echo "  └─ phi3:mini          - Microsoft Phi-3 Mini (3.8B)"
    echo "  └─ gemma:2b           - Google Gemma 2B"
    echo "  └─ codellama:7b       - Code analysis model"
    echo "  └─ deepseek-coder:6.7b - Code-specialized model"
    echo "  └─ nomic-embed-text   - Embeddings for RAG"
    echo "  ${GREEN}Best for: Maximum capability and versatility${NC}"
    echo ""

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  POPULAR ADDITIONAL MODELS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${YELLOW}Small & Fast:${NC}"
    echo "  • llama3.2:1b           - 1B params, ultra-fast, low memory"
    echo "  • phi3:mini             - Microsoft's 3.8B param model"
    echo "  • gemma:2b              - Google's 2B param model"
    echo ""

    echo -e "${YELLOW}Medium (Auto-quantized):${NC}"
    echo "  • llama3:8b             - Llama-3 8B (Ollama auto-quantizes)"
    echo "  • mistral:7b-instruct   - Mistral 7B instruction tuned"
    echo "  • llama2:7b             - Llama-2 7B (Ollama auto-quantizes)"
    echo ""

    echo -e "${YELLOW}Code Analysis:${NC}"
    echo "  • codellama:7b          - Code-specialized model"
    echo "  • deepseek-coder:6.7b   - Excellent at code understanding"
    echo "  • codellama:13b         - Larger code model (if you have RAM)"
    echo ""

    echo -e "${YELLOW}Embeddings:${NC}"
    echo "  • nomic-embed-text      - Best for RAG applications"
    echo "  • mxbai-embed-large     - Alternative embedding model"
    echo ""

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  QUANTIZATION GUIDE${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo "  Quantization reduces model size with minimal quality loss:"
    echo ""
    echo "  • q4_0   - 4-bit quantization (50% size reduction, ~5% quality loss)"
    echo "  • q5_0   - 5-bit quantization (40% size reduction, ~3% quality loss)"
    echo "  • q8_0   - 8-bit quantization (25% size reduction, <1% quality loss)"
    echo ""
    echo "  Example: mistral:7b (4.1GB) vs mistral:7b-q4_0 (2.2GB)"
    echo ""
}

cmd_usage() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                        ║${NC}"
    echo -e "${CYAN}║                    OLLAMA MODEL MANAGEMENT                             ║${NC}"
    echo -e "${CYAN}║                                                                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  list                       List all installed models"
    echo "  pull <model>               Pull a specific model"
    echo "  pull-profile <profile>     Pull all models for a profile"
    echo "                             Profiles: minimal, efficient, standard, full"
    echo "  remove <model>             Remove a model"
    echo "  info                       Show detailed model information"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 pull llama3.2:1b"
    echo "  $0 pull-profile efficient"
    echo "  $0 remove mistral:7b-instruct"
    echo "  $0 info"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

check_ollama

case "${1:-}" in
    list)
        cmd_list
        ;;
    pull)
        cmd_pull "$2"
        ;;
    pull-profile)
        cmd_pull_profile "$2"
        ;;
    remove|rm)
        cmd_remove "$2"
        ;;
    info)
        cmd_info
        ;;
    help|--help|-h|"")
        cmd_usage
        ;;
    *)
        print_error "Unknown command: $1"
        cmd_usage
        exit 1
        ;;
esac
