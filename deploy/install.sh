#!/bin/bash
#
# OpenAlgo MCP Server - Complete VPS Installation Script
# This script performs end-to-end setup including:
# - Domain configuration
# - GitHub repository clone
# - System dependencies installation
# - Python environment setup
# - Systemd service configuration
# - Nginx setup with SSL support
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 OpenAlgo MCP Server - Complete Installation"
echo "==============================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root or with sudo${NC}"
    exit 1
fi

# Get domain name from user
echo -e "${YELLOW}📝 Domain Configuration${NC}"
read -p "Enter your domain name (e.g., mcp.openalgo.in or api.yourdomain.com): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    echo -e "${RED}❌ Domain name is required!${NC}"
    exit 1
fi

# Get OpenAlgo credentials
echo ""
echo -e "${YELLOW}🔐 OpenAlgo Configuration${NC}"
read -p "Enter your OpenAlgo API Key: " OPENALGO_API_KEY
if [ -z "$OPENALGO_API_KEY" ]; then
    echo -e "${RED}❌ OpenAlgo API Key is required!${NC}"
    exit 1
fi

read -p "Enter your OpenAlgo Host URL (e.g., http://127.0.0.1:5000): " OPENALGO_HOST
if [ -z "$OPENALGO_HOST" ]; then
    echo -e "${RED}❌ OpenAlgo Host URL is required!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}📋 Installation Summary:${NC}"
echo "   Domain: $DOMAIN_NAME"
echo "   OpenAlgo Host: $OPENALGO_HOST"
echo "   Installation Path: /opt/openalgo-mcp"
echo "   Repository: https://github.com/marketcalls/openalgo_mcp"
echo ""
read -p "Continue with installation? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

echo ""
echo -e "${GREEN}Starting complete installation...${NC}"
echo ""

# Update system
echo -e "${YELLOW}📦 Step 1/9: Updating system packages...${NC}"
apt update
apt upgrade -y

# Install Python 3.12+
echo ""
echo -e "${YELLOW}🐍 Step 2/9: Installing Python 3.12...${NC}"
apt install -y software-properties-common
add-apt-repository ppa:deadsnakes/ppa -y
apt update
apt install -y python3.12 python3.12-venv python3.12-dev python3-pip

# Install system dependencies
echo ""
echo -e "${YELLOW}📦 Step 3/9: Installing system dependencies...${NC}"
apt install -y build-essential git curl nginx certbot python3-certbot-nginx

# Clone repository
echo ""
echo -e "${YELLOW}📥 Step 4/9: Cloning OpenAlgo MCP repository...${NC}"
cd /tmp
if [ -d "openalgo_mcp" ]; then
    rm -rf openalgo_mcp
fi
git clone https://github.com/marketcalls/openalgo_mcp.git
cd openalgo_mcp

# Create application directory
echo ""
echo -e "${YELLOW}📁 Step 5/9: Setting up application directory...${NC}"
mkdir -p /opt/openalgo-mcp
cd /opt/openalgo-mcp

# Create virtual environment and install dependencies
echo ""
echo -e "${YELLOW}🔧 Step 6/9: Creating Python environment and installing dependencies...${NC}"
python3.12 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install fastmcp httpx[http2] mcp nest-asyncio uvicorn

# Copy application files
echo ""
echo -e "${YELLOW}📄 Step 7/9: Copying application files...${NC}"
cp -r /tmp/openalgo_mcp/src/* /opt/openalgo-mcp/
cp /tmp/openalgo_mcp/pyproject.toml /opt/openalgo-mcp/
cp /tmp/openalgo_mcp/requirements.txt /opt/openalgo-mcp/

# Install the package
pip install -e .

# Create environment file
echo ""
echo -e "${YELLOW}⚙️  Step 8/9: Creating environment configuration...${NC}"
cat > /opt/openalgo-mcp/.env << EOF
OPENALGO_API_KEY=$OPENALGO_API_KEY
OPENALGO_HOST=$OPENALGO_HOST
HTTP_HOST=127.0.0.1
HTTP_PORT=8000
DOMAIN_NAME=$DOMAIN_NAME
EOF

# Save domain for reference
echo "$DOMAIN_NAME" > /opt/openalgo-mcp/.domain

# Set permissions
chown -R www-data:www-data /opt/openalgo-mcp

# Setup systemd service
echo ""
echo -e "${YELLOW}🔄 Step 9/9: Setting up systemd service...${NC}"
cat > /etc/systemd/system/openalgo-mcp.service << 'EOF'
[Unit]
Description=OpenAlgo MCP Server
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/openalgo-mcp
Environment="PATH=/opt/openalgo-mcp/venv/bin"
EnvironmentFile=/opt/openalgo-mcp/.env
ExecStart=/opt/openalgo-mcp/venv/bin/python -m openalgo_mcp.mcpserver ${OPENALGO_API_KEY} ${OPENALGO_HOST} --transport streamable-http --http-host ${HTTP_HOST} --http-port ${HTTP_PORT}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable openalgo-mcp
systemctl start openalgo-mcp

# Wait a moment for service to start
sleep 2

# Check service status
if systemctl is-active --quiet openalgo-mcp; then
    echo -e "${GREEN}✅ OpenAlgo MCP service started successfully${NC}"
else
    echo -e "${RED}❌ Service failed to start. Check logs with: journalctl -u openalgo-mcp -n 50${NC}"
    exit 1
fi

# Configure Nginx
echo ""
echo -e "${YELLOW}🌐 Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/$DOMAIN_NAME << 'NGINX_EOF'
# OpenAlgo MCP - Nginx Configuration
# Domain: DOMAIN_PLACEHOLDER

# HTTP - Redirect to HTTPS (or serve initially)
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;

    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # Initially proxy to backend (before SSL)
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

# Replace domain placeholder
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN_NAME/g" /etc/nginx/sites-available/$DOMAIN_NAME

# Enable site
ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/

# Remove default site if exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
fi

# Test configuration
nginx -t

# Reload Nginx
systemctl reload nginx

echo ""
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 OpenAlgo MCP Server is now running!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Installation Details:"
echo "   • Domain: $DOMAIN_NAME"
echo "   • Service: openalgo-mcp (running)"
echo "   • HTTP: http://$DOMAIN_NAME"
echo "   • Application Path: /opt/openalgo-mcp"
echo ""
echo "🔐 Next Step - SSL Certificate:"
echo "   Run the following command to enable HTTPS:"
echo ""
echo -e "   ${YELLOW}sudo certbot --nginx -d $DOMAIN_NAME${NC}"
echo ""
echo "   This will:"
echo "   • Obtain a free Let's Encrypt SSL certificate"
echo "   • Automatically configure HTTPS"
echo "   • Set up auto-renewal"
echo ""
echo "📖 Useful Commands:"
echo "   • Check service status: systemctl status openalgo-mcp"
echo "   • View logs: journalctl -u openalgo-mcp -f"
echo "   • Restart service: systemctl restart openalgo-mcp"
echo "   • Test API: curl http://localhost:8000"
echo ""
echo "🌐 DNS Configuration:"
echo "   Make sure your DNS A record points to this server:"
echo "   Type: A"
echo "   Name: ${DOMAIN_NAME%%.*} (or @ for root domain)"
echo "   Value: $(curl -s ifconfig.me)"
echo "   TTL: Auto"
echo ""
echo "☁️  If using Cloudflare:"
echo "   • Set proxy to 'DNS only' (grey cloud) before running certbot"
echo "   • After SSL is working, you can enable proxy (orange cloud)"
echo "   • Set SSL/TLS mode to 'Full (strict)'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}Installation script completed successfully!${NC}"
echo -e "Ready to obtain SSL certificate with: ${YELLOW}sudo certbot --nginx -d $DOMAIN_NAME${NC}"
echo ""
