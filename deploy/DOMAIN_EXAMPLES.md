# Domain Configuration Examples

OpenAlgo MCP supports **any domain or subdomain** configuration. Here are common examples:

## ✅ Supported Domain Formats

### Subdomains (Recommended)

```
✅ mcp.openalgo.in
✅ api.trading.io
✅ openalgo.example.com
✅ trade.yourdomain.com
✅ mcp.api.example.com (multi-level subdomain)
```

### Primary Domains (Without www)

```
✅ openalgo.com
✅ tradingapi.io
✅ myalgo.net
```

### With www (Not Recommended)

```
⚠️ www.openalgo.com (works, but use primary domain instead)
```

---

## 📋 DNS Configuration Examples

### Example 1: Subdomain (Most Common)

**Domain:** `mcp.openalgo.in`
**Server IP:** `65.20.70.245`

**DNS Records:**
```
Type: A
Name: mcp
Value: 65.20.70.245
TTL: Auto/3600
Proxy: DNS only (grey cloud) initially
```

### Example 2: Primary Domain

**Domain:** `tradingapi.io`
**Server IP:** `123.45.67.89`

**DNS Records:**
```
Type: A
Name: @
Value: 123.45.67.89
TTL: Auto/3600
Proxy: DNS only (grey cloud) initially
```

### Example 3: Multi-level Subdomain

**Domain:** `mcp.api.example.com`
**Server IP:** `203.0.113.10`

**DNS Records:**
```
Type: A
Name: mcp.api
Value: 203.0.113.10
TTL: Auto/3600
Proxy: DNS only (grey cloud) initially
```

---

## 🌐 DNS Provider Specific Instructions

### Cloudflare

1. Go to DNS settings
2. Click "Add record"
3. Select type: **A**
4. Name: `mcp` (or `@` for primary domain)
5. IPv4 address: Your server IP
6. Proxy status: **DNS only** (grey cloud) during SSL setup
7. TTL: Auto
8. Click Save

**After SSL is installed:**
- Enable proxy (orange cloud) for CDN & DDoS protection
- Set SSL/TLS mode to "Full (strict)"

### Route 53 (AWS)

1. Go to your hosted zone
2. Create record
3. Record name: `mcp` (or leave empty for primary domain)
4. Record type: **A**
5. Value: Your server IP
6. TTL: 300
7. Routing policy: Simple
8. Create record

### Namecheap

1. Go to Advanced DNS
2. Add New Record
3. Type: **A Record**
4. Host: `mcp` (or `@` for primary domain)
5. Value: Your server IP
6. TTL: Automatic
7. Save

### GoDaddy

1. DNS Management
2. Add Record
3. Type: **A**
4. Name: `mcp` (or `@` for primary domain)
5. Points to: Your server IP
6. TTL: 1 hour
7. Save

---

## 🚀 Installation Examples

### Example 1: Subdomain

```bash
./install.sh
# When prompted: mcp.openalgo.in

# Later, for SSL:
sudo certbot --nginx -d mcp.openalgo.in
```

### Example 2: Primary Domain

```bash
./install.sh
# When prompted: tradingapi.io

# Later, for SSL:
sudo certbot --nginx -d tradingapi.io
```

### Example 3: Different Subdomain

```bash
./install.sh
# When prompted: api.mytrading.com

# Later, for SSL:
sudo certbot --nginx -d api.mytrading.com
```

---

## ✅ Verification Checklist

Before running installation:

- [ ] DNS A record created
- [ ] A record points to correct server IP
- [ ] DNS propagated (check with `nslookup your-domain.com`)
- [ ] Server accessible via SSH
- [ ] If using Cloudflare, proxy is **DNS only** (grey cloud)

**Verify DNS propagation:**
```bash
# On your local machine
nslookup mcp.openalgo.in
# Should show your server IP

# Alternative
dig mcp.openalgo.in +short
# Should output your server IP
```

---

## 🔧 Common DNS Issues

### Issue: Domain doesn't resolve

**Solution:**
```bash
# Check DNS propagation
nslookup your-domain.com

# Wait 5-10 minutes for DNS propagation
# Some providers take up to 24 hours
```

### Issue: SSL certificate fails

**Problem:** Domain not resolving or Cloudflare proxy enabled

**Solution:**
1. Verify DNS points to server: `nslookup your-domain.com`
2. If using Cloudflare, disable proxy (grey cloud)
3. Wait 5 minutes
4. Try `certbot` again
5. After SSL works, re-enable Cloudflare proxy

### Issue: "Address already in use"

**Problem:** Another service using port 80/443

**Solution:**
```bash
# Check what's using port 80
sudo netstat -tulpn | grep :80

# Stop conflicting service
sudo systemctl stop apache2  # if Apache is running
```

---

## 📖 Quick Reference

| Scenario | DNS Name | DNS Value | Installation Input |
|----------|----------|-----------|-------------------|
| Subdomain | `mcp` | Server IP | `mcp.openalgo.in` |
| Primary domain | `@` | Server IP | `openalgo.in` |
| Multi-level | `mcp.api` | Server IP | `mcp.api.example.com` |
| Different subdomain | `trade` | Server IP | `trade.domain.com` |

---

## 🎯 Best Practices

1. **Use subdomains** - Easier to manage, can point to different servers
2. **Set DNS before installation** - Ensure propagation before running scripts
3. **Use Cloudflare DNS only** initially - Enable proxy after SSL is working
4. **Choose meaningful names** - `mcp`, `api`, `trade`, `openalgo`
5. **Document your setup** - Keep track of domain, IP, and credentials

---

## 🔐 Security Recommendations

1. **Always use HTTPS** - The scripts handle this automatically
2. **Enable Cloudflare proxy** after SSL - Adds DDoS protection
3. **Use strong API keys** - Never commit to git
4. **Regular updates** - Keep server and packages updated
5. **Monitor logs** - Check for unusual activity

---

Your domain is now ready for OpenAlgo MCP deployment! 🚀
