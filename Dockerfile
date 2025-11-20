FROM n8nio/n8n:latest

USER root

# Set environment variables
ENV GOPATH=/root/go \
    PATH=$PATH:/root/go/bin \
    GOPROXY=https://proxy.golang.org,direct

# Install minimal system dependencies
RUN apk update && apk add --no-cache \
    # Build essentials for Go
    build-base \
    git \
    curl \
    wget \
    bash \
    # Core network tools
    nmap \
    nmap-scripts \
    bind-tools \
    # Python for future tool installs
    python3 \
    py3-pip \
    # Go language (for installing tools on demand)
    go \
    # Utilities
    jq

# Install pipx for isolated Python tools
RUN pip3 install --no-cache-dir --break-system-packages pipx && \
    pipx ensurepath

# Create tool installer script (LLM can use this to install tools on demand)
RUN echo '#!/bin/sh' > /usr/local/bin/install-tool && \
    echo 'TOOL=$1' >> /usr/local/bin/install-tool && \
    echo 'case "$TOOL" in' >> /usr/local/bin/install-tool && \
    echo '  subfinder) go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest ;;' >> /usr/local/bin/install-tool && \
    echo '  httpx) go install github.com/projectdiscovery/httpx/cmd/httpx@latest ;;' >> /usr/local/bin/install-tool && \
    echo '  nuclei) go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest ;;' >> /usr/local/bin/install-tool && \
    echo '  amass) go install github.com/owasp-amass/amass/v4/...@master ;;' >> /usr/local/bin/install-tool && \
    echo '  ffuf) go install github.com/ffuf/ffuf/v2@latest ;;' >> /usr/local/bin/install-tool && \
    echo '  katana) go install github.com/projectdiscovery/katana/cmd/katana@latest ;;' >> /usr/local/bin/install-tool && \
    echo '  naabu) go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest ;;' >> /usr/local/bin/install-tool && \
    echo '  waybackurls) go install github.com/tomnomnom/waybackurls@latest ;;' >> /usr/local/bin/install-tool && \
    echo '  gau) go install github.com/lc/gau/v2/cmd/gau@latest ;;' >> /usr/local/bin/install-tool && \
    echo '  *) echo "Unknown tool: $TOOL" && exit 1 ;;' >> /usr/local/bin/install-tool && \
    echo 'esac' >> /usr/local/bin/install-tool && \
    echo 'cp /root/go/bin/* /usr/local/bin/ 2>/dev/null || true' >> /usr/local/bin/install-tool && \
    chmod +x /usr/local/bin/install-tool

# Install only essential Go tools for basic recon
RUN go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && \
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest && \
    go install github.com/owasp-amass/amass/v4/...@master

# Copy Go binaries to /usr/local/bin for global access
RUN cp /root/go/bin/* /usr/local/bin/

# Update nuclei templates
RUN nuclei -update-templates

# Create workspace directories
RUN mkdir -p /opt/recon-workspace /opt/loot && \
    chmod -R 777 /opt/recon-workspace /opt/loot

# Set working directory back to n8n
WORKDIR /home/node/.n8n

# Switch back to node user for n8n
USER node

# Expose n8n port
EXPOSE 5678

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --spider -q http://localhost:5678/healthz || exit 1
