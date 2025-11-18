FROM n8nio/n8n:latest

USER root

# Set environment variables
ENV GOPATH=/root/go \
    PATH=$PATH:/root/go/bin:/opt/sqlmap:/usr/share/exploitdb:/opt/testssl.sh \
    SECLISTS_PATH=/opt/SecLists \
    WEBANALYZE_DB=/opt/webanalyze/technologies.json \
    CHROMIUM_PATH=/usr/bin/chromium-browser \
    GOPROXY=https://proxy.golang.org,direct \
    GOSUMDB=sum.golang.org \
    GOTIMEOUT=5m

# Install system dependencies and security tools (Alpine-based)
RUN apk update && apk add --no-cache \
    # Build essentials
    build-base \
    git \
    curl \
    wget \
    unzip \
    bash \
    # Network tools
    nmap \
    nmap-scripts \
    bind-tools \
    netcat-openbsd \
    # Python and pip
    python3 \
    py3-pip \
    python3-dev \
    # Go language
    go \
    # Other utilities
    jq \
    vim \
    net-tools \
    iputils \
    # Libraries needed for Python tools and Go compilation
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    libpcap-dev \
    cargo \
    # Chromium for gowitness
    chromium \
    chromium-chromedriver

# Install pipx for isolated Python tools
RUN pip3 install --no-cache-dir --break-system-packages pipx && \
    pipx ensurepath

# Install Python security tools
RUN pip3 install --no-cache-dir --break-system-packages \
    impacket \
    shodan \
    censys \
    requests \
    dnspython \
    sqlparse

# Install NetExec via pipx - install globally to /usr/local
RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install git+https://github.com/Pennyw0rth/NetExec.git && \
    chmod 755 /root && \
    chmod -R 755 /root/.local || \
    echo "NetExec installation failed, will be available manually"

# Create retry function for resilient downloads with DNS fallback
RUN echo '#!/bin/sh' > /usr/local/bin/retry_install && \
    echo 'MAX_ATTEMPTS=5' >> /usr/local/bin/retry_install && \
    echo 'for i in $(seq 1 $MAX_ATTEMPTS); do' >> /usr/local/bin/retry_install && \
    echo '  echo "=========================================="' >> /usr/local/bin/retry_install && \
    echo '  echo "Go install attempt $i/$MAX_ATTEMPTS: $@"' >> /usr/local/bin/retry_install && \
    echo '  echo "=========================================="' >> /usr/local/bin/retry_install && \
    echo '  if GOPROXY=https://proxy.golang.org,https://goproxy.io,direct go install -v "$@" 2>&1; then' >> /usr/local/bin/retry_install && \
    echo '    echo "✓ Installation successful!"' >> /usr/local/bin/retry_install && \
    echo '    exit 0' >> /usr/local/bin/retry_install && \
    echo '  fi' >> /usr/local/bin/retry_install && \
    echo '  WAIT_TIME=$((i * 10))' >> /usr/local/bin/retry_install && \
    echo '  if [ $i -lt $MAX_ATTEMPTS ]; then' >> /usr/local/bin/retry_install && \
    echo '    echo "✗ Attempt $i failed. Waiting ${WAIT_TIME} seconds..."' >> /usr/local/bin/retry_install && \
    echo '    sleep $WAIT_TIME' >> /usr/local/bin/retry_install && \
    echo '  fi' >> /usr/local/bin/retry_install && \
    echo 'done' >> /usr/local/bin/retry_install && \
    echo 'echo "✗ Failed after $MAX_ATTEMPTS attempts: $@"' >> /usr/local/bin/retry_install && \
    echo 'echo "Attempting direct install without proxy as last resort..."' >> /usr/local/bin/retry_install && \
    echo 'GOPROXY=direct go install -v "$@" 2>&1 || exit 1' >> /usr/local/bin/retry_install && \
    chmod +x /usr/local/bin/retry_install

# Install Go-based security tools (split into groups for better caching and error isolation)
# ProjectDiscovery tools
RUN retry_install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
RUN retry_install github.com/projectdiscovery/httpx/cmd/httpx@latest
RUN retry_install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
RUN retry_install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
RUN retry_install github.com/projectdiscovery/tlsx/cmd/tlsx@latest
RUN retry_install github.com/projectdiscovery/katana/cmd/katana@latest
RUN retry_install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest

# Other reconnaissance tools
RUN retry_install github.com/owasp-amass/amass/v4/...@master
RUN retry_install github.com/sensepost/gowitness@latest || echo "gowitness failed, continuing..."
RUN retry_install github.com/rverton/webanalyze/cmd/webanalyze@latest || echo "webanalyze failed, continuing..."
RUN retry_install github.com/haccer/subjack@latest || echo "subjack failed, continuing..."

# Tomnomnom tools
RUN retry_install github.com/tomnomnom/gf@latest
RUN retry_install github.com/tomnomnom/waybackurls@latest
RUN retry_install github.com/tomnomnom/assetfinder@latest
RUN retry_install github.com/tomnomnom/httprobe@latest

# Other tools
RUN retry_install github.com/ffuf/ffuf/v2@latest
RUN retry_install github.com/lc/gau/v2/cmd/gau@latest
RUN retry_install github.com/hakluke/hakrawler@latest

# Clone security repositories
WORKDIR /opt

# Create resilient git clone function for large repositories
RUN echo '#!/bin/sh' > /usr/local/bin/retry_git_clone && \
    echo 'REPO_URL=$1' >> /usr/local/bin/retry_git_clone && \
    echo 'TARGET_PATH=$2' >> /usr/local/bin/retry_git_clone && \
    echo 'MAX_ATTEMPTS=5' >> /usr/local/bin/retry_git_clone && \
    echo 'for i in $(seq 1 $MAX_ATTEMPTS); do' >> /usr/local/bin/retry_git_clone && \
    echo '  echo "=========================================="' >> /usr/local/bin/retry_git_clone && \
    echo '  echo "Git clone attempt $i/$MAX_ATTEMPTS"' >> /usr/local/bin/retry_git_clone && \
    echo '  echo "Repository: $REPO_URL"' >> /usr/local/bin/retry_git_clone && \
    echo '  echo "Target: $TARGET_PATH"' >> /usr/local/bin/retry_git_clone && \
    echo '  echo "=========================================="' >> /usr/local/bin/retry_git_clone && \
    echo '  rm -rf "$TARGET_PATH" 2>/dev/null || true' >> /usr/local/bin/retry_git_clone && \
    echo '  if git -c http.postBuffer=1048576000 \' >> /usr/local/bin/retry_git_clone && \
    echo '         -c http.lowSpeedLimit=100 \' >> /usr/local/bin/retry_git_clone && \
    echo '         -c http.lowSpeedTime=60 \' >> /usr/local/bin/retry_git_clone && \
    echo '         -c http.version=HTTP/1.1 \' >> /usr/local/bin/retry_git_clone && \
    echo '         -c core.compression=0 \' >> /usr/local/bin/retry_git_clone && \
    echo '         -c pack.windowMemory=100m \' >> /usr/local/bin/retry_git_clone && \
    echo '         -c pack.packSizeLimit=100m \' >> /usr/local/bin/retry_git_clone && \
    echo '         -c pack.threads=1 \' >> /usr/local/bin/retry_git_clone && \
    echo '         clone --depth 1 --progress "$REPO_URL" "$TARGET_PATH"; then' >> /usr/local/bin/retry_git_clone && \
    echo '    echo ""' >> /usr/local/bin/retry_git_clone && \
    echo '    echo "✓ Clone successful!"' >> /usr/local/bin/retry_git_clone && \
    echo '    exit 0' >> /usr/local/bin/retry_git_clone && \
    echo '  fi' >> /usr/local/bin/retry_git_clone && \
    echo '  WAIT_TIME=$((i * 10))' >> /usr/local/bin/retry_git_clone && \
    echo '  if [ $i -lt $MAX_ATTEMPTS ]; then' >> /usr/local/bin/retry_git_clone && \
    echo '    echo ""' >> /usr/local/bin/retry_git_clone && \
    echo '    echo "✗ Attempt $i failed. Waiting ${WAIT_TIME} seconds before retry..."' >> /usr/local/bin/retry_git_clone && \
    echo '    sleep $WAIT_TIME' >> /usr/local/bin/retry_git_clone && \
    echo '  fi' >> /usr/local/bin/retry_git_clone && \
    echo 'done' >> /usr/local/bin/retry_git_clone && \
    echo 'echo ""' >> /usr/local/bin/retry_git_clone && \
    echo 'echo "✗ Failed to clone after $MAX_ATTEMPTS attempts: $REPO_URL"' >> /usr/local/bin/retry_git_clone && \
    echo 'exit 1' >> /usr/local/bin/retry_git_clone && \
    chmod +x /usr/local/bin/retry_git_clone

# Clone SecLists (large repository ~1.2GB - needs resilient handling)
RUN retry_git_clone https://github.com/danielmiessler/SecLists.git /opt/SecLists

# Clone and setup sqlmap
RUN retry_git_clone https://github.com/sqlmapproject/sqlmap.git /opt/sqlmap && \
    chmod +x /opt/sqlmap/sqlmap.py && \
    ln -s /opt/sqlmap/sqlmap.py /usr/local/bin/sqlmap

# Clone exploitdb
RUN retry_git_clone https://github.com/offensive-security/exploitdb.git /usr/share/exploitdb && \
    ln -s /usr/share/exploitdb/searchsploit /usr/local/bin/searchsploit

# Clone testssl.sh
RUN retry_git_clone https://github.com/drwetter/testssl.sh.git /opt/testssl.sh && \
    ln -s /opt/testssl.sh/testssl.sh /usr/local/bin/testssl.sh && \
    chmod +x /opt/testssl.sh/testssl.sh

# Install gf patterns for grep-friendly output parsing
RUN mkdir -p /root/.gf && \
    retry_git_clone https://github.com/tomnomnom/gf.git /tmp/gf && \
    cp -r /tmp/gf/examples/*.json /root/.gf/ && \
    rm -rf /tmp/gf && \
    retry_git_clone https://github.com/1ndianl33t/Gf-Patterns.git /tmp/gf-patterns && \
    cp /tmp/gf-patterns/*.json /root/.gf/ 2>/dev/null || true && \
    rm -rf /tmp/gf-patterns

# Configure gowitness to use system chromium
RUN mkdir -p /root/.config/gowitness && \
    echo '{"chrome": {"path": "/usr/bin/chromium-browser"}}' > /root/.config/gowitness/config.json

# Download webanalyze technologies database
RUN mkdir -p /opt/webanalyze && \
    wget -O /opt/webanalyze/technologies.json https://raw.githubusercontent.com/AliasIO/wappalyzer/master/src/technologies.json || \
    echo "Failed to download webanalyze database, will update later"

# Install nmap vulners script
RUN cd /usr/share/nmap/scripts/ && \
    retry_git_clone https://github.com/vulnersCom/nmap-vulners.git /usr/share/nmap/scripts/nmap-vulners && \
    cp nmap-vulners/vulners.nse ./ && \
    rm -rf nmap-vulners

# Install nmap vulscan script
RUN cd /usr/share/nmap/scripts/ && \
    retry_git_clone https://github.com/scipag/vulscan.git /usr/share/nmap/scripts/vulscan && \
    ln -s /usr/share/nmap/scripts/vulscan/vulscan.nse /usr/share/nmap/scripts/vulscan.nse

# Update nmap script database
RUN nmap --script-updatedb

# Download common wordlists to /opt/wordlists
RUN mkdir -p /opt/wordlists && \
    cp /opt/SecLists/Discovery/DNS/subdomains-top1million-110000.txt /opt/wordlists/ && \
    cp /opt/SecLists/Discovery/Web-Content/common.txt /opt/wordlists/ && \
    cp /opt/SecLists/Discovery/Web-Content/raft-large-directories.txt /opt/wordlists/ && \
    cp /opt/SecLists/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt /opt/wordlists/ 2>/dev/null || true

# Create workspace directories
RUN mkdir -p /opt/recon-workspace /opt/loot && \
    chmod -R 777 /opt/recon-workspace /opt/loot

# Update nuclei templates
RUN /root/go/bin/nuclei -update-templates

# Copy Go binaries to /usr/local/bin for global access
RUN cp /root/go/bin/* /usr/local/bin/

# Set working directory back to n8n
WORKDIR /home/node/.n8n

# Switch back to node user for n8n
USER node

# Expose n8n port
EXPOSE 5678

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --spider -q http://localhost:5678/healthz || exit 1

# Use the default CMD from the base n8n image (don't override it)
