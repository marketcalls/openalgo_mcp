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
echo -e "${YELLOW}📦 Step 1/10: Updating system packages...${NC}"
apt update
apt upgrade -y

# Install Python 3.12+
echo ""
echo -e "${YELLOW}🐍 Step 2/10: Installing Python 3.12+...${NC}"

# Check if Python 3.12+ is already installed
PYTHON_VERSION=$(python3 --version 2>/dev/null | grep -oP '(?<=Python )\d+\.\d+' || echo "0.0")
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

if [ "$PYTHON_MAJOR" -ge 3 ] && [ "$PYTHON_MINOR" -ge 12 ]; then
    echo -e "${GREEN}✅ Python $PYTHON_VERSION already installed${NC}"
    apt install -y python3-venv python3-dev python3-pip
    PYTHON_CMD=python3
else
    echo "Installing Python 3.12 from deadsnakes PPA..."
    apt install -y software-properties-common
    add-apt-repository ppa:deadsnakes/ppa -y
    apt update
    apt install -y python3.12 python3.12-venv python3.12-dev python3-pip
    PYTHON_CMD=python3.12
fi

# Install system dependencies
echo ""
echo -e "${YELLOW}📦 Step 3/10: Installing system dependencies...${NC}"
apt install -y build-essential git curl nginx certbot python3-certbot-nginx dnsutils

# Clone repository
echo ""
echo -e "${YELLOW}📥 Step 4/10: Cloning OpenAlgo MCP repository...${NC}"
cd /tmp
if [ -d "openalgo_mcp" ]; then
    rm -rf openalgo_mcp
fi
git clone https://github.com/marketcalls/openalgo_mcp.git
cd openalgo_mcp

# Create application directory
echo ""
echo -e "${YELLOW}📁 Step 5/10: Setting up application directory...${NC}"
mkdir -p /opt/openalgo-mcp
cd /opt/openalgo-mcp

# Create virtual environment and install dependencies
echo ""
echo -e "${YELLOW}🔧 Step 6/10: Creating Python environment and installing dependencies...${NC}"
$PYTHON_CMD -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install fastmcp httpx[http2] mcp nest-asyncio uvicorn

# Copy application files
echo ""
echo -e "${YELLOW}📄 Step 7/10: Copying application files...${NC}"

# Check if nested structure exists
if [ -d "/tmp/openalgo_mcp/openalgo_mcp" ]; then
    SRC_PATH="/tmp/openalgo_mcp/openalgo_mcp"
else
    SRC_PATH="/tmp/openalgo_mcp"
fi

echo "Copying from: $SRC_PATH"
cp -r $SRC_PATH/src /opt/openalgo-mcp/
cp $SRC_PATH/pyproject.toml /opt/openalgo-mcp/
cp $SRC_PATH/requirements.txt /opt/openalgo-mcp/
[ -f $SRC_PATH/README.md ] && cp $SRC_PATH/README.md /opt/openalgo-mcp/

# Verify files were copied
echo "Verifying copied files..."
ls -la /opt/openalgo-mcp/

# Install the package
pip install -e .

# Create environment file
echo ""
echo -e "${YELLOW}⚙️  Step 8/10: Creating environment configuration...${NC}"
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
echo -e "${YELLOW}🔄 Step 9/10: Setting up systemd service...${NC}"
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

# Configure Nginx (Initial HTTP-only config for certbot)
echo ""
echo -e "${YELLOW}🌐 Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/$DOMAIN_NAME << 'NGINX_EOF'
# OpenAlgo MCP - Nginx Configuration (Temporary HTTP-only)
# Domain: DOMAIN_PLACEHOLDER

server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;

    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # Proxy to backend
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

# Start or reload Nginx
if systemctl is-active --quiet nginx; then
    systemctl reload nginx
else
    systemctl start nginx
    systemctl enable nginx
fi

echo ""
echo -e "${GREEN}✅ Nginx configured successfully!${NC}"

# SSL Certificate Setup
echo ""
echo -e "${YELLOW}🔐 Step 10: SSL Certificate Setup${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check DNS resolution
echo "Checking DNS resolution for $DOMAIN_NAME..."
RESOLVED_IP=$(dig +short $DOMAIN_NAME @8.8.8.8 | tail -n1)
SERVER_IP=$(curl -s ifconfig.me)

if [ -z "$RESOLVED_IP" ]; then
    echo -e "${YELLOW}⚠️  DNS not configured yet${NC}"
    echo ""
    echo "Please configure your DNS A record:"
    echo "  Domain: $DOMAIN_NAME"
    echo "  Points to: $SERVER_IP"
    echo ""
    echo "After DNS is configured, run the SSL setup command shown at the end."
    SSL_SKIP=true
elif [ "$RESOLVED_IP" != "$SERVER_IP" ]; then
    echo -e "${YELLOW}⚠️  DNS points to different IP (likely Cloudflare proxy)${NC}"
    echo "  Domain resolves to: $RESOLVED_IP"
    echo "  This server IP: $SERVER_IP"
    echo ""
    echo "If using Cloudflare, temporarily disable proxy (grey cloud) for SSL setup."
    echo "Or run the SSL setup command shown at the end."
    SSL_SKIP=true
else
    echo -e "${GREEN}✅ DNS correctly configured ($RESOLVED_IP)${NC}"
    echo ""

    # Ask for email for Let's Encrypt
    read -p "Enter your email for Let's Encrypt certificate notifications: " LETSENCRYPT_EMAIL

    if [ -z "$LETSENCRYPT_EMAIL" ]; then
        echo -e "${YELLOW}⚠️  Email required for SSL certificate${NC}"
        echo "Run the SSL setup command shown at the end."
        SSL_SKIP=true
    else
        echo ""
        echo "Obtaining SSL certificate from Let's Encrypt..."

        # Run certbot certonly (don't let it modify nginx config)
        if certbot certonly --webroot -w /var/www/html -d $DOMAIN_NAME --non-interactive --agree-tos --email $LETSENCRYPT_EMAIL; then
            echo -e "${GREEN}✅ SSL certificate obtained successfully!${NC}"
            SSL_SUCCESS=true
        else
            echo -e "${RED}❌ Failed to obtain SSL certificate${NC}"
            echo "You can try manually with the SSL setup command shown at the end."
            SSL_SKIP=true
        fi
    fi
fi

# Apply production Nginx config (regardless of certbot success, if cert exists)
if [ -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ]; then
    echo ""
    echo "Applying production Nginx configuration..."

    cat > /etc/nginx/sites-available/$DOMAIN_NAME << 'NGINX_PROD_EOF'
# OpenAlgo MCP - Nginx Production Configuration
# Domain: DOMAIN_PLACEHOLDER

# HTTP - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;

    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS - Main server block
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name DOMAIN_PLACEHOLDER;

    # SSL Certificate
    ssl_certificate /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;

    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
    ssl_ecdh_curve secp384r1;
    ssl_session_timeout 10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;

    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=63072000" always;

    # Proxy to OpenAlgo MCP Server
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;

        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;

        # Buffering
        proxy_buffering off;
    }
}
NGINX_PROD_EOF

    # Replace domain placeholder
    sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN_NAME/g" /etc/nginx/sites-available/$DOMAIN_NAME

    # Ensure symlink exists
    ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/

    # Test and reload
    if nginx -t; then
        systemctl reload nginx
        echo -e "${GREEN}✅ Production Nginx configuration applied${NC}"
        SSL_SUCCESS=true
    else
        echo -e "${RED}❌ Nginx config test failed${NC}"
        nginx -t
    fi
fi

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
if [ "$SSL_SUCCESS" = true ]; then
    echo "   • HTTPS: https://$DOMAIN_NAME (SSL enabled ✅)"
    echo "   • HTTP: Redirects to HTTPS"
else
    echo "   • HTTP: http://$DOMAIN_NAME"
fi
echo "   • Application Path: /opt/openalgo-mcp"
echo ""

if [ "$SSL_SKIP" = true ]; then
    echo "🔐 SSL Certificate Setup:"
    echo "   Run the following commands to enable HTTPS:"
    echo ""
    echo -e "   ${YELLOW}# Step 1: Get SSL certificate${NC}"
    echo -e "   ${YELLOW}sudo certbot certonly --webroot -w /var/www/html -d $DOMAIN_NAME${NC}"
    echo ""
    echo -e "   ${YELLOW}# Step 2: Apply production nginx config${NC}"
    cat << 'MANUAL_EOF'
   sudo cat > /etc/nginx/sites-available/$DOMAIN_NAME << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME;
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { return 301 https://$host$request_uri; }
}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN_NAME;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
    add_header Strict-Transport-Security "max-age=63072000" always;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_buffering off;
    }
}
EOF
MANUAL_EOF
    echo ""
    echo -e "   ${YELLOW}# Step 3: Reload nginx${NC}"
    echo -e "   ${YELLOW}sudo nginx -t && sudo systemctl reload nginx${NC}"
    echo ""
    echo "   Note: If using Cloudflare, temporarily set DNS to 'DNS only' (grey cloud)"
    echo "   before running certbot, then re-enable proxy after."
    echo ""
fi
echo "📖 Useful Commands:"
echo "   • Check service status: systemctl status openalgo-mcp"
echo "   • View logs: journalctl -u openalgo-mcp -f"
echo "   • Restart service: systemctl restart openalgo-mcp"
if [ "$SSL_SUCCESS" = true ]; then
    echo "   • Test API: curl https://localhost:8000"
else
    echo "   • Test API: curl http://localhost:8000"
fi
echo ""

if [ "$SSL_SKIP" = true ]; then
    echo "🌐 DNS Configuration:"
    echo "   Make sure your DNS A record points to this server:"
    echo "   Type: A"
    echo "   Name: ${DOMAIN_NAME%%.*} (or @ for root domain)"
    echo "   Value: $SERVER_IP"
    echo "   TTL: Auto"
    echo ""
fi

if [ "$SSL_SUCCESS" = true ]; then
    echo "☁️  Cloudflare (Optional):"
    echo "   • You can now enable Cloudflare proxy (orange cloud)"
    echo "   • Set SSL/TLS mode to 'Full (strict)'"
    echo ""
    echo "🔒 SSL Certificate:"
    echo "   • Auto-renewal configured ✅"
    echo "   • Certificate expires: $(date -d '+90 days' '+%Y-%m-%d')"
    echo "   • View certificates: sudo certbot certificates"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if [ "$SSL_SUCCESS" = true ]; then
    echo -e "${GREEN}✅ Installation completed successfully with HTTPS enabled!${NC}"
    echo -e "Your OpenAlgo MCP server is live at: ${GREEN}https://$DOMAIN_NAME${NC}"
else
    echo -e "${GREEN}Installation script completed successfully!${NC}"
    if [ "$SSL_SKIP" = true ]; then
        echo -e "After DNS is configured, enable HTTPS with: ${YELLOW}sudo certbot --nginx -d $DOMAIN_NAME${NC}"
    fi
fi
echo ""
