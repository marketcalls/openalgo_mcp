# OpenAlgo MCP - VPS Deployment Guide

Complete guide to deploy OpenAlgo MCP on any VPS (Vultr, DigitalOcean, AWS EC2, etc.) with HTTPS.

## Server Details

- **Domain:** mcp.openalgo.in
- **IP Address:** 65.20.70.245
- **DNS:** Cloudflare (A record pointing to server)
- **SSL:** Let's Encrypt certificate
- **OS:** Ubuntu 22.04 LTS (recommended)

---

## Prerequisites

1. ✅ VPS running Ubuntu 22.04+ or Debian 11+
2. ✅ SSH access to the server (root or sudo user)
3. ✅ Domain pointing to your server IP (A record)
4. ✅ DNS configured (optional: Cloudflare)
5. ✅ OpenAlgo instance running (locally or on another server)

---

## Step 1: Initial Server Setup

### Connect to your server:
```bash
ssh root@65.20.70.245
```

### Create a non-root user (recommended):
```bash
adduser openalgo
usermod -aG sudo openalgo
su - openalgo
```

---

## Step 2: Upload Deployment Files

From your local machine, upload the files to the server:

```bash
# Create deployment directory locally
cd D:\openalgo_mcp\openalgo_mcp

# Upload to server
scp -r deploy root@65.20.70.245:/tmp/
scp -r src root@65.20.70.245:/tmp/
scp pyproject.toml requirements.txt root@65.20.70.245:/tmp/
```

---

## Step 3: Run Installation Script

On the server:

```bash
# Make script executable
chmod +x /tmp/deploy/install.sh

# Run installation (it will ask for your domain name)
/tmp/deploy/install.sh

# When prompted, enter your domain name:
# Examples:
#   - mcp.openalgo.in
#   - api.trading.io
#   - openalgo.example.com
#   - trade.yourdomain.com
```

**The script will:**
- Ask for your domain name
- Install all dependencies
- Create configuration files with your domain
- Set up the application directory

---

## Step 4: Configure Environment Variables

Edit the environment file:

```bash
sudo nano /opt/openalgo-mcp/.env
```

Update with your credentials:
```bash
OPENALGO_API_KEY=your-actual-api-key-here
OPENALGO_HOST=https://your-openalgo-instance.com
HTTP_HOST=127.0.0.1
HTTP_PORT=8000
```

Save and exit (Ctrl+X, Y, Enter)

---

## Step 5: Copy Application Files

```bash
# Copy source files
sudo cp -r /tmp/src/* /opt/openalgo-mcp/
sudo cp /tmp/pyproject.toml /opt/openalgo-mcp/
sudo cp /tmp/requirements.txt /opt/openalgo-mcp/

# Set permissions
sudo chown -R www-data:www-data /opt/openalgo-mcp
```

---

## Step 6: Install Python Dependencies

```bash
cd /opt/openalgo-mcp
source venv/bin/activate
pip install -e .
```

---

## Step 7: Setup Systemd Service

```bash
# Copy service file
sudo cp /tmp/deploy/openalgo-mcp.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable openalgo-mcp

# Start service
sudo systemctl start openalgo-mcp

# Check status
sudo systemctl status openalgo-mcp
```

Expected output:
```
● openalgo-mcp.service - OpenAlgo MCP Server
     Loaded: loaded (/etc/systemd/system/openalgo-mcp.service; enabled)
     Active: active (running)
```

---

## Step 8: Configure Nginx

The installation created a setup script that automatically configures Nginx with your domain:

```bash
# Make setup script executable
chmod +x /tmp/deploy/setup-nginx.sh

# Run Nginx setup (uses domain from installation)
sudo /tmp/deploy/setup-nginx.sh
```

**The script will:**
- Read your domain from the installation config
- Create Nginx configuration for your specific domain
- Enable the site
- Test and reload Nginx

**Manual setup (alternative):**
```bash
# Read your domain
DOMAIN=$(cat /opt/openalgo-mcp/.domain)

# Copy and configure
sudo cp /tmp/deploy/nginx-mcp.conf /etc/nginx/sites-available/$DOMAIN
sudo sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" /etc/nginx/sites-available/$DOMAIN
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## Step 9: Cloudflare DNS Configuration

In your Cloudflare dashboard (cloudflare.com):

1. Go to your domain's DNS settings
2. Verify the A record exists:
   - **Type:** A
   - **Name:** mcp
   - **IPv4 address:** 65.20.70.245
   - **Proxy status:** DNS only (click the cloud to make it grey)
   - **TTL:** Auto

**Important:** Set proxy to "DNS only" (grey cloud) initially for Let's Encrypt to work.

---

## Step 10: Setup Let's Encrypt SSL

### Option A: Using Certbot (Recommended)

```bash
# Install certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d mcp.openalgo.in

# Follow the prompts:
# - Enter email address
# - Agree to terms
# - Choose to redirect HTTP to HTTPS (option 2)
```

### Test auto-renewal:
```bash
sudo certbot renew --dry-run
```

---

## Step 11: Enable Cloudflare Proxy (Optional)

After SSL is working:

1. Go to Cloudflare DNS
2. Click the cloud next to your A record to enable proxy (orange cloud)
3. This enables Cloudflare's CDN and DDoS protection

### Configure Cloudflare SSL Mode:

1. Go to SSL/TLS settings in Cloudflare
2. Set to **"Full (strict)"** mode
3. This ensures end-to-end encryption

---

## Step 12: Test Deployment

### Test locally on server:
```bash
curl http://localhost:8000
curl http://127.0.0.1:8000
```

### Test via domain:
```bash
curl https://mcp.openalgo.in
curl https://mcp.openalgo.in/health
```

### Test MCP endpoints:
```bash
# SSE endpoint
curl https://mcp.openalgo.in/sse

# Ping
curl -X POST https://mcp.openalgo.in/messages \
  -H "Content-Type: application/json" \
  -d '{"method": "ping_api"}'
```

---

## Step 13: Configure MCP Client

Update your MCP client configuration:

### For Claude Desktop:
```json
{
  "mcpServers": {
    "openalgo": {
      "url": "https://mcp.openalgo.in",
      "transport": {
        "type": "sse"
      }
    }
  }
}
```

### For Cline / VSCode:
```json
{
  "openalgo": {
    "disabled": false,
    "timeout": 60,
    "type": "http",
    "url": "https://mcp.openalgo.in"
  }
}
```

---

## Monitoring & Maintenance

### View logs:
```bash
# Application logs
sudo journalctl -u openalgo-mcp -f

# Nginx access logs
sudo tail -f /var/log/nginx/mcp.openalgo.in-access.log

# Nginx error logs
sudo tail -f /var/log/nginx/mcp.openalgo.in-error.log
```

### Service management:
```bash
# Restart service
sudo systemctl restart openalgo-mcp

# Stop service
sudo systemctl stop openalgo-mcp

# Check status
sudo systemctl status openalgo-mcp
```

### Update application:
```bash
cd /opt/openalgo-mcp
git pull  # if using git
source venv/bin/activate
pip install -e .
sudo systemctl restart openalgo-mcp
```

---

## Firewall Configuration

```bash
# Install UFW
sudo apt install -y ufw

# Allow SSH
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

## Troubleshooting

### Service won't start:
```bash
# Check logs
sudo journalctl -u openalgo-mcp -n 50 --no-pager

# Check if port is in use
sudo netstat -tulpn | grep 8000

# Verify environment variables
cat /opt/openalgo-mcp/.env
```

### SSL certificate issues:
```bash
# Test certificate
sudo certbot certificates

# Renew manually
sudo certbot renew

# Check nginx config
sudo nginx -t
```

### Connection refused:
```bash
# Check if service is running
sudo systemctl status openalgo-mcp

# Check nginx
sudo systemctl status nginx

# Test local connection
curl http://localhost:8000
```

---

## Security Best Practices

1. ✅ Keep system updated: `sudo apt update && sudo apt upgrade`
2. ✅ Use strong passwords
3. ✅ Enable SSH key authentication
4. ✅ Disable root SSH login
5. ✅ Enable UFW firewall
6. ✅ Regular backups
7. ✅ Monitor logs for suspicious activity
8. ✅ Rotate API keys periodically

---

## Backup & Recovery

### Backup important files:
```bash
# Create backup directory
mkdir -p ~/backups

# Backup application
sudo tar -czf ~/backups/openalgo-mcp-$(date +%Y%m%d).tar.gz /opt/openalgo-mcp

# Backup nginx config
sudo tar -czf ~/backups/nginx-config-$(date +%Y%m%d).tar.gz /etc/nginx/sites-available/mcp.openalgo.in

# Backup SSL certificates
sudo tar -czf ~/backups/ssl-certs-$(date +%Y%m%d).tar.gz /etc/letsencrypt
```

---

## Performance Tuning

### For high-traffic deployments:

1. **Increase worker processes:**
   Edit `/opt/openalgo-mcp/deploy/openalgo-mcp.service`:
   ```ini
   ExecStart=/opt/openalgo-mcp/venv/bin/uvicorn openalgo_mcp.mcpserver:app --host 127.0.0.1 --port 8000 --workers 4
   ```

2. **Enable Nginx caching**
3. **Use Cloudflare caching rules**
4. **Monitor with tools like Prometheus + Grafana**

---

## Success Checklist

- ✅ Server accessible via SSH
- ✅ Python 3.12 installed
- ✅ Application running (`systemctl status openalgo-mcp`)
- ✅ Nginx configured and running
- ✅ SSL certificate installed
- ✅ Domain resolves to server IP
- ✅ HTTPS working (https://mcp.openalgo.in)
- ✅ MCP endpoints responding
- ✅ Cloudflare proxy enabled (optional)
- ✅ Logs showing no errors

---

## Support

If you encounter issues:

1. Check logs: `sudo journalctl -u openalgo-mcp -f`
2. Verify configuration files
3. Test each component individually
4. Check Cloudflare DNS settings
5. Verify firewall rules

**Your OpenAlgo MCP Server is now production-ready!** 🎉
