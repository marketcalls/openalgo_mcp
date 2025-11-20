#!/bin/bash
#
# OpenAlgo MCP Server - VPS Installation Script
# Compatible with: Ubuntu 22.04+, Debian 11+
#

set -e

echo "🚀 OpenAlgo MCP Server - Installation"
echo "======================================"
echo ""

# Get domain name from user
read -p "Enter your domain name (e.g., mcp.openalgo.in or trading.example.com): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Domain name is required!"
    exit 1
fi

echo ""
echo "📋 Installation Summary:"
echo "   Domain: $DOMAIN_NAME"
echo "   Installation Path: /opt/openalgo-mcp"
echo ""
read -p "Continue with installation? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

echo ""
echo "Starting installation..."
echo ""

# Update system
echo "📦 Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install Python 3.12+
echo "🐍 Installing Python 3.12..."
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.12 python3.12-venv python3.12-dev python3-pip

# Install system dependencies
echo "📦 Installing system dependencies..."
sudo apt install -y build-essential git curl nginx certbot python3-certbot-nginx

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/openalgo-mcp
sudo chown $USER:$USER /opt/openalgo-mcp
cd /opt/openalgo-mcp

# Clone repository (or copy files)
echo "📥 Setting up application..."
# If using git:
# git clone https://github.com/marketcalls/openalgo_mcp.git .
# Or copy files manually

# Create virtual environment
echo "🔧 Creating Python virtual environment..."
python3.12 -m venv venv
source venv/bin/activate

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install fastmcp httpx[http2] mcp nest-asyncio uvicorn

# Create environment file
echo "⚙️  Creating environment configuration..."
cat > /opt/openalgo-mcp/.env << EOF
OPENALGO_API_KEY=your-api-key-here
OPENALGO_HOST=http://127.0.0.1:5000
HTTP_HOST=127.0.0.1
HTTP_PORT=8000
DOMAIN_NAME=$DOMAIN_NAME
EOF

# Save domain for nginx configuration
echo "$DOMAIN_NAME" > /opt/openalgo-mcp/.domain

echo ""
echo "✅ Base installation complete!"
echo ""
echo "📝 Configuration saved:"
echo "   Domain: $DOMAIN_NAME"
echo "   Environment file: /opt/openalgo-mcp/.env"
echo ""
echo "Next steps:"
echo "1. Update /opt/openalgo-mcp/.env with your OpenAlgo credentials"
echo "2. Copy your OpenAlgo MCP files to /opt/openalgo-mcp"
echo "3. Setup systemd service and Nginx"
echo "4. Run: sudo certbot --nginx -d $DOMAIN_NAME"
