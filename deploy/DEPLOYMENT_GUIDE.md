# OpenAlgo MCP - VPS Deployment Guide

Complete guide to deploy OpenAlgo MCP on any VPS (Vultr, DigitalOcean, AWS EC2, etc.) with HTTPS.

---

## Prerequisites

1. ✅ VPS running Ubuntu 22.04+ or Debian 11+
2. ✅ Root or sudo access to the server
3. ✅ Domain pointing to your server IP (A record)
4. ✅ OpenAlgo instance running (locally or on another server)

---

## One-Command Installation ⚡

### Method 1: Direct Curl Installation (Recommended)

```bash
# Connect to your server
ssh root@your-server-ip

# Run the installation script
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/marketcalls/openalgo_mcp/main/deploy/install.sh)"
```

### Method 2: Download and Run

```bash
# Connect to your server
ssh root@your-server-ip

# Download installation script
wget https://raw.githubusercontent.com/marketcalls/openalgo_mcp/main/deploy/install.sh

# Make executable
chmod +x install.sh

# Run installation
sudo ./install.sh
```

---

## Installation Process

The installation script will:

### 1. **Prompt for Configuration**

You'll be asked to provide:

```
Enter your domain name: mcp.yourdomain.com
Enter your OpenAlgo API Key: your-api-key-here
Enter your OpenAlgo Host URL: http://127.0.0.1:5000
```

### 2. **Automatic Setup (9 Steps)**

The script automatically performs:

- ✅ **Step 1/9:** Updates system packages
- ✅ **Step 2/9:** Installs Python 3.12
- ✅ **Step 3/9:** Installs system dependencies (git, nginx, certbot)
- ✅ **Step 4/9:** Clones OpenAlgo MCP repository from GitHub
- ✅ **Step 5/9:** Creates application directory
- ✅ **Step 6/9:** Sets up Python virtual environment
- ✅ **Step 7/9:** Copies application files
- ✅ **Step 8/9:** Creates environment configuration
- ✅ **Step 9/9:** Configures and starts systemd service

### 3. **Automatic Nginx Configuration**

- Creates Nginx configuration with your domain
- Sets up reverse proxy to port 8000
- Configures for SSL certificate setup
- Removes default Nginx site

### 4. **Service Verification**

- Starts OpenAlgo MCP service
- Verifies service is running
- Provides status feedback

---

## Post-Installation: SSL Certificate

After installation completes successfully, run this command to get a free SSL certificate:

```bash
sudo certbot --nginx -d your-domain.com
```

**Certbot will:**
- Obtain a Let's Encrypt SSL certificate
- Automatically configure Nginx for HTTPS
- Set up auto-renewal

**Example:**
```bash
sudo certbot --nginx -d mcp.openalgo.in
```

Follow the prompts:
1. Enter your email address
2. Agree to terms of service
3. Choose whether to redirect HTTP to HTTPS (recommended: yes)

---

## DNS Configuration

Before installation, ensure your DNS is configured correctly:

### Cloudflare Example

```
Type: A
Name: mcp (or @ for root domain)
IPv4 address: your-server-ip
Proxy status: DNS only (grey cloud) - Important for SSL setup!
TTL: Auto
```

### After SSL is Working

1. Enable Cloudflare proxy (orange cloud) for DDoS protection
2. Set SSL/TLS mode to **"Full (strict)"**

### Verify DNS Propagation

```bash
# Check if domain resolves
nslookup your-domain.com

# Alternative
dig your-domain.com +short
```

---

## Verification

After installation, test your deployment:

### 1. Test Local Connection

```bash
curl http://localhost:8000
```

### 2. Test Domain (HTTP)

```bash
curl http://your-domain.com
```

### 3. Test Domain (HTTPS - after certbot)

```bash
curl https://your-domain.com
curl https://your-domain.com/health
```

### 4. Check Service Status

```bash
sudo systemctl status openalgo-mcp
```

Expected output:
```
● openalgo-mcp.service - OpenAlgo MCP Server
     Loaded: loaded (/etc/systemd/system/openalgo-mcp.service; enabled)
     Active: active (running)
```

---

## Configuration Files

The installation creates these files:

| File | Location | Purpose |
|------|----------|---------|
| Environment | `/opt/openalgo-mcp/.env` | API keys and configuration |
| Domain | `/opt/openalgo-mcp/.domain` | Saved domain name |
| Service | `/etc/systemd/system/openalgo-mcp.service` | Systemd service config |
| Nginx | `/etc/nginx/sites-available/your-domain.com` | Nginx configuration |
| Application | `/opt/openalgo-mcp/` | Application files |

---

## Management Commands

### Service Management

```bash
# Check status
sudo systemctl status openalgo-mcp

# Restart service
sudo systemctl restart openalgo-mcp

# Stop service
sudo systemctl stop openalgo-mcp

# Start service
sudo systemctl start openalgo-mcp

# View logs
sudo journalctl -u openalgo-mcp -f

# View last 50 lines
sudo journalctl -u openalgo-mcp -n 50 --no-pager
```

### Nginx Management

```bash
# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Restart Nginx
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx
```

### SSL Certificate Management

```bash
# List certificates
sudo certbot certificates

# Renew certificates (manually)
sudo certbot renew

# Test auto-renewal
sudo certbot renew --dry-run
```

---

## MCP Client Configuration

After deployment with SSL, configure your MCP client:

### For Claude Desktop

```json
{
  "mcpServers": {
    "openalgo": {
      "url": "https://your-domain.com",
      "transport": {
        "type": "sse"
      }
    }
  }
}
```

### For Cline / VSCode

```json
{
  "openalgo": {
    "disabled": false,
    "timeout": 60,
    "type": "http",
    "url": "https://your-domain.com"
  }
}
```

---

## Updating the Application

To update OpenAlgo MCP to the latest version:

```bash
# Pull latest code
cd /tmp
rm -rf openalgo_mcp
git clone https://github.com/marketcalls/openalgo_mcp.git

# Copy updated files
sudo cp -r openalgo_mcp/src/* /opt/openalgo-mcp/
sudo cp openalgo_mcp/pyproject.toml /opt/openalgo-mcp/
sudo cp openalgo_mcp/requirements.txt /opt/openalgo-mcp/

# Reinstall
cd /opt/openalgo-mcp
source venv/bin/activate
pip install -e .

# Restart service
sudo systemctl restart openalgo-mcp
```

---

## Troubleshooting

### Service won't start

```bash
# Check logs
sudo journalctl -u openalgo-mcp -n 50 --no-pager

# Check if port is in use
sudo netstat -tulpn | grep 8000

# Verify environment variables
cat /opt/openalgo-mcp/.env
```

### SSL certificate fails

**Problem:** Certbot cannot verify domain

**Solution:**
```bash
# 1. Verify DNS points to server
nslookup your-domain.com

# 2. If using Cloudflare, disable proxy (grey cloud)

# 3. Wait 5 minutes for DNS propagation

# 4. Try certbot again
sudo certbot --nginx -d your-domain.com

# 5. After SSL works, re-enable Cloudflare proxy
```

### Connection refused

```bash
# Check if service is running
sudo systemctl status openalgo-mcp

# Check nginx
sudo systemctl status nginx

# Test local connection
curl http://localhost:8000

# Check firewall
sudo ufw status
```

### Domain doesn't resolve

```bash
# Check DNS propagation
nslookup your-domain.com

# Check from different DNS
dig @8.8.8.8 your-domain.com

# Wait for DNS propagation (5-30 minutes)
```

---

## Firewall Configuration

```bash
# Install UFW
sudo apt install -y ufw

# Allow SSH (important - do this first!)
sudo ufw allow 22/tcp

# Allow HTTP & HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

---

## Security Best Practices

1. ✅ Use strong API keys
2. ✅ Enable UFW firewall
3. ✅ Keep system updated: `sudo apt update && sudo apt upgrade`
4. ✅ Use SSH key authentication
5. ✅ Disable root SSH login (after setting up sudo user)
6. ✅ Monitor logs regularly
7. ✅ Enable Cloudflare proxy after SSL setup
8. ✅ Rotate API keys periodically

---

## Backup & Recovery

### Backup Important Files

```bash
# Create backup directory
mkdir -p ~/backups

# Backup application
sudo tar -czf ~/backups/openalgo-mcp-$(date +%Y%m%d).tar.gz /opt/openalgo-mcp

# Backup Nginx config
DOMAIN=$(cat /opt/openalgo-mcp/.domain)
sudo tar -czf ~/backups/nginx-config-$(date +%Y%m%d).tar.gz /etc/nginx/sites-available/$DOMAIN

# Backup SSL certificates
sudo tar -czf ~/backups/ssl-certs-$(date +%Y%m%d).tar.gz /etc/letsencrypt
```

---

## Installation Time

Expected installation time on a standard VPS:
- **System updates:** 2-5 minutes
- **Dependency installation:** 3-5 minutes
- **Application setup:** 2-3 minutes
- **Total:** ~10-15 minutes

---

## Success Checklist

After installation, verify:

- ✅ Server accessible via SSH
- ✅ Service running: `systemctl status openalgo-mcp`
- ✅ Nginx configured and running
- ✅ Domain resolves to server IP
- ✅ HTTP working: `curl http://your-domain.com`
- ✅ SSL certificate installed (after certbot)
- ✅ HTTPS working: `curl https://your-domain.com`
- ✅ Logs showing no errors
- ✅ MCP client can connect

---

## Support

If you encounter issues:

1. **Check logs:** `sudo journalctl -u openalgo-mcp -f`
2. **Verify DNS:** `nslookup your-domain.com`
3. **Test locally:** `curl http://localhost:8000`
4. **Check firewall:** `sudo ufw status`
5. **Review configuration:** `cat /opt/openalgo-mcp/.env`

---

## Complete Installation Example

Here's what a successful installation looks like:

```bash
# 1. Connect to server
ssh root@65.20.70.245

# 2. Run installation
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/marketcalls/openalgo_mcp/main/deploy/install.sh)"

# Enter domain: mcp.openalgo.in
# Enter API key: your-api-key
# Enter host: http://127.0.0.1:5000
# Confirm: y

# ... installation runs automatically ...

# ✅ Installation Complete!
# Service is running on http://mcp.openalgo.in

# 3. Setup SSL
sudo certbot --nginx -d mcp.openalgo.in

# ✅ SSL certificate obtained!
# Now available at: https://mcp.openalgo.in
```

---

**Your OpenAlgo MCP Server is now production-ready!** 🎉
