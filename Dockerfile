FROM n8nio/n8n:latest

USER root

# Set environment variables
ENV GOPATH=/root/go \
    PATH=$PATH:/root/go/bin \
    GOPROXY=https://proxy.golang.org,direct \
    GOSUMDB=sum.golang.org \
    GOTIMEOUT=300

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
    fping \
    # SSH and tunnel tools (for pivot capability)
    openssh-client \
    sshpass \
    proxychains-ng \
    netcat-openbsd \
    # Python for future tool installs
    python3 \
    py3-pip \
    # Go language (for installing tools on demand)
    go \
    # PDF Generation dependencies (WeasyPrint)
    cairo \
    pango \
    gdk-pixbuf \
    libffi-dev \
    harfbuzz \
    freetype \
    fontconfig \
    # Fonts for professional PDF rendering
    ttf-dejavu \
    ttf-liberation \
    ttf-freefont \
    font-noto \
    font-noto-cjk \
    font-noto-emoji \
    # Utilities
    jq \
    ncurses

# Configure default proxychains settings
RUN mkdir -p /etc/proxychains && \
    echo "strict_chain" > /etc/proxychains/proxychains.conf && \
    echo "proxy_dns" >> /etc/proxychains/proxychains.conf && \
    echo "tcp_read_time_out 15000" >> /etc/proxychains/proxychains.conf && \
    echo "tcp_connect_time_out 8000" >> /etc/proxychains/proxychains.conf && \
    echo "[ProxyList]" >> /etc/proxychains/proxychains.conf && \
    echo "# Dynamic proxies added at runtime" >> /etc/proxychains/proxychains.conf

# Install pipx for isolated Python tools
RUN pip3 install --no-cache-dir --break-system-packages pipx && \
    pipx ensurepath

# Install Azure CLI
RUN apk add --no-cache --virtual .build-deps gcc musl-dev python3-dev libffi-dev openssl-dev cargo && \
    pip3 install --no-cache-dir --break-system-packages azure-cli && \
    apk del .build-deps

# Install Python cloud security tools
RUN apk add --no-cache --virtual .cloud-deps gcc g++ musl-dev python3-dev libffi-dev pkgconf && \
    pip3 install --no-cache-dir --break-system-packages \
    ScoutSuite \
    roadlib \
    roadrecon && \
    apk del .cloud-deps

# Install WeasyPrint for PDF generation from HTML
RUN pip3 install --no-cache-dir --break-system-packages weasyprint

# Refresh font cache for proper rendering
RUN fc-cache -f -v

# Create html2pdf helper script for easy PDF generation in n8n workflows
RUN cat > /usr/local/bin/html2pdf << 'EOF'
#!/usr/bin/env python3
"""
HTML to PDF Converter using WeasyPrint
Usage:
  html2pdf <input.html> <output.pdf>
  echo "<html>...</html>" | html2pdf output.pdf
  html2pdf output.pdf  (reads HTML from stdin)
"""
import sys
from weasyprint import HTML, CSS

def main():
    if len(sys.argv) < 2:
        print("Usage: html2pdf <input.html> <output.pdf>", file=sys.stderr)
        print("   or: html2pdf <output.pdf>  (reads HTML from stdin)", file=sys.stderr)
        print("   or: echo '<html>...</html>' | html2pdf output.pdf", file=sys.stderr)
        sys.exit(1)

    # Determine input source and output file
    if len(sys.argv) == 3:
        # html2pdf input.html output.pdf
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        with open(input_file, 'r') as f:
            html_content = f.read()
    elif len(sys.argv) == 2:
        # html2pdf output.pdf (stdin)
        output_file = sys.argv[1]
        html_content = sys.stdin.read()
    else:
        print("Error: Invalid arguments", file=sys.stderr)
        sys.exit(1)

    # Optional CSS for better defaults
    default_css = CSS(string='''
        @page {
            size: A4;
            margin: 2cm;
        }
        body {
            font-family: 'DejaVu Sans', 'Liberation Sans', 'Noto Sans', sans-serif;
            font-size: 11pt;
            line-height: 1.6;
        }
        pre, code {
            font-family: 'DejaVu Sans Mono', 'Liberation Mono', monospace;
            background-color: #f4f4f4;
            padding: 0.2em 0.4em;
            border-radius: 3px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 1em 0;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
    ''')

    try:
        # Generate PDF
        HTML(string=html_content).write_pdf(
            output_file,
            stylesheets=[default_css]
        )
        print(f"PDF generated successfully: {output_file}", file=sys.stderr)
    except Exception as e:
        print(f"Error generating PDF: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
EOF

RUN chmod +x /usr/local/bin/html2pdf

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

# Install only essential Go tools for basic recon (split for reliability)
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
RUN go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
RUN go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
RUN go install -v github.com/owasp-amass/amass/v4/...@master

# ============================================
# TIER 1: Web Discovery & Crawling Tools
# ============================================
RUN echo "Installing Tier 1: Web Discovery Tools..."
RUN go install -v github.com/projectdiscovery/katana/cmd/katana@latest
RUN go install -v github.com/tomnomnom/waybackurls@latest
RUN go install -v github.com/lc/gau/v2/cmd/gau@latest
RUN go install -v github.com/jaeles-project/gospider@latest

# ============================================
# TIER 1: Enhanced DNS Tools
# ============================================
RUN echo "Installing Tier 1: DNS Tools..."
RUN go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
RUN go install -v github.com/d3mondev/puredns/v2@latest
RUN git clone --depth 1 https://github.com/blechschmidt/massdns.git /tmp/massdns && \
    cd /tmp/massdns && make && cp bin/massdns /usr/local/bin/ && \
    chmod +x /usr/local/bin/massdns && \
    cd / && rm -rf /tmp/massdns

# Create default DNS resolvers file for puredns/massdns
RUN echo "Installing DNS resolvers..." && \
    mkdir -p /usr/share/dns-resolvers && \
    printf "8.8.8.8\n8.8.4.4\n1.1.1.1\n1.0.0.1\n9.9.9.9\n149.112.112.112\n208.67.222.222\n208.67.220.220\n" > /usr/share/dns-resolvers/resolvers.txt && \
    ln -s /usr/share/dns-resolvers/resolvers.txt /tmp/resolvers.txt

# ============================================
# TIER 1: Technology Detection
# ============================================
RUN echo "Installing Tier 1: Technology Detection..." && \
    npm install -g wappalyzer retire && \
    apk add --no-cache ruby ruby-dev && \
    git clone --depth 1 https://github.com/urbanadventurer/WhatWeb.git /opt/WhatWeb && \
    ln -s /opt/WhatWeb/whatweb /usr/local/bin/whatweb && \
    chmod +x /opt/WhatWeb/whatweb

# ============================================
# TIER 1: Content Discovery
# ============================================
RUN echo "Installing Tier 1: Content Discovery..."
RUN go install -v github.com/ffuf/ffuf/v2@latest
RUN pip3 install --no-cache-dir --break-system-packages dirsearch

# ============================================
# TIER 2: API Discovery
# ============================================
RUN echo "Installing Tier 2: API Discovery..." && \
    pip3 install --no-cache-dir --break-system-packages arjun

# ============================================
# TIER 2: SSL/TLS Analysis
# ============================================
RUN echo "Installing Tier 2: SSL/TLS Analysis..."
RUN go install -v github.com/projectdiscovery/tlsx/cmd/tlsx@latest
RUN git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl && \
    ln -s /opt/testssl/testssl.sh /usr/local/bin/testssl && \
    chmod +x /opt/testssl/testssl.sh

# ============================================
# TIER 2: Visual Reconnaissance
# ============================================
# Note: gowitness requires Go 1.25+, skipping for now
# RUN echo "Installing Tier 2: Visual Recon..." && \
#     go install github.com/sensepost/gowitness@latest

# ============================================
# TIER 3: Cloud Discovery
# ============================================
RUN echo "Installing Tier 3: Cloud Discovery..." && \
    git clone --depth 1 https://github.com/initstring/cloud_enum.git /opt/cloud_enum && \
    ln -s /opt/cloud_enum/cloud_enum.py /usr/local/bin/cloud_enum && \
    chmod +x /opt/cloud_enum/cloud_enum.py && \
    pip3 install --no-cache-dir --break-system-packages -r /opt/cloud_enum/requirements.txt

# ============================================
# ADDITIONAL TOOLS: Port Scanning
# ============================================
RUN echo "Installing Additional Port Scanning Tools..."
RUN apk add --no-cache libpcap-dev
RUN go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest

# ============================================
# ADDITIONAL TOOLS: Directory Discovery
# ============================================
RUN echo "Installing Additional Directory Discovery Tools..."
RUN go install -v github.com/OJ/gobuster/v3@v3.6.0

# ============================================
# ADDITIONAL TOOLS: DNS Enumeration
# ============================================
RUN echo "Installing Additional DNS Tools..." && \
    pip3 install --no-cache-dir --break-system-packages dnsrecon

# ============================================
# ADDITIONAL TOOLS: OSINT
# ============================================
RUN echo "Installing Additional OSINT Tools..." && \
    pip3 install --no-cache-dir --break-system-packages theHarvester python-whois

# ============================================
# ADDITIONAL TOOLS: Secret Scanning
# ============================================
RUN echo "Installing TruffleHog..." && \
    pip3 install --no-cache-dir --break-system-packages truffleHog

# ============================================
# ADDITIONAL TOOLS: Shodan CLI
# ============================================
RUN echo "Installing Shodan CLI..." && \
    pip3 install --no-cache-dir --break-system-packages shodan && \
    ln -s /home/node/.local/bin/shodan /usr/local/bin/shodan || true

# Fix testssl.sh symlink
RUN ln -sf /opt/testssl/testssl.sh /usr/local/bin/testssl.sh

# Copy all Go binaries to /usr/local/bin for global access
RUN cp /root/go/bin/* /usr/local/bin/ 2>/dev/null || true

# Update nuclei templates
RUN nuclei -update-templates

# Install Exploit-DB (searchsploit)
RUN cd /opt && \
    git clone --depth 1 https://gitlab.com/exploit-database/exploitdb.git && \
    ln -sf /opt/exploitdb/searchsploit /usr/local/bin/searchsploit && \
    chmod +x /opt/exploitdb/searchsploit && \
    chown -R node:node /opt/exploitdb && \
    git config --global --add safe.directory /opt/exploitdb

# Create workspace directories with proper permissions
RUN mkdir -p /opt/recon-workspace /opt/loot && \
    chown -R node:node /opt/recon-workspace /opt/loot && \
    chmod -R 755 /opt/recon-workspace /opt/loot

# Set working directory back to n8n
WORKDIR /home/node/.n8n

# Switch back to node user for n8n
USER node

# Expose n8n port
EXPOSE 5678

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --spider -q http://localhost:5678/healthz || exit 1
