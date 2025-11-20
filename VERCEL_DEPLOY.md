# Deploying OpenAlgo MCP to Vercel

This guide will walk you through deploying the OpenAlgo MCP Server to Vercel.

## Prerequisites

1. **Vercel Account** - Sign up at [vercel.com](https://vercel.com)
2. **Vercel CLI** (optional, but recommended)
   ```bash
   npm install -g vercel
   ```
3. **OpenAlgo Instance** - Must be publicly accessible (not localhost)

## Important: OpenAlgo Host Requirement

⚠️ **Your OpenAlgo instance must be accessible from the internet** since Vercel serverless functions cannot access localhost.

### Options:
1. **Deploy OpenAlgo on a public server** (VPS, cloud instance)
2. **Use a tunnel service** like:
   - [Ngrok](https://ngrok.com) - `ngrok http 5000`
   - [Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/)
   - [LocalTunnel](https://localtunnel.github.io/www/)

## Deployment Steps

### Option 1: Deploy via Vercel CLI (Recommended)

1. **Install Vercel CLI:**
   ```bash
   npm install -g vercel
   ```

2. **Login to Vercel:**
   ```bash
   vercel login
   ```

3. **Navigate to project directory:**
   ```bash
   cd openalgo_mcp
   ```

4. **Set environment variables:**
   ```bash
   vercel env add OPENALGO_API_KEY
   # Enter your OpenAlgo API key when prompted

   vercel env add OPENALGO_HOST
   # Enter your public OpenAlgo URL (e.g., https://your-openalgo.com or https://abc123.ngrok.io)
   ```

5. **Deploy:**
   ```bash
   vercel
   ```

6. **Follow the prompts:**
   - Set up and deploy? `Y`
   - Which scope? Select your account
   - Link to existing project? `N`
   - Project name? `openalgo-mcp` (or your choice)
   - Directory? `./` (press Enter)
   - Override settings? `N`

### Option 2: Deploy via Vercel Dashboard

1. **Push code to GitHub:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/openalgo-mcp.git
   git push -u origin main
   ```

2. **Import on Vercel:**
   - Go to [vercel.com/new](https://vercel.com/new)
   - Import your GitHub repository
   - Click "Import"

3. **Configure Environment Variables:**
   - In project settings, add:
     - `OPENALGO_API_KEY`: Your OpenAlgo API key
     - `OPENALGO_HOST`: Your public OpenAlgo URL

4. **Deploy:**
   - Click "Deploy"
   - Wait for deployment to complete

## Configuration

### Environment Variables

Set these in your Vercel project:

| Variable | Description | Example |
|----------|-------------|---------|
| `OPENALGO_API_KEY` | Your OpenAlgo API key | `abc123def456...` |
| `OPENALGO_HOST` | Public OpenAlgo URL | `https://openalgo.example.com` |

### vercel.json Configuration

The project includes a `vercel.json` file with:
- Python runtime configuration
- Route handling
- Function settings (60s timeout, 1GB memory)

```json
{
  "version": 2,
  "builds": [{ "src": "api/mcp.py", "use": "@vercel/python" }],
  "routes": [{ "src": "/(.*)", "dest": "api/mcp.py" }]
}
```

## Using the Deployed MCP Server

Once deployed, you'll get a URL like: `https://openalgo-mcp.vercel.app`

### Configure MCP Client

Update your MCP client configuration:

```json
{
  "openalgo": {
    "disabled": false,
    "timeout": 60,
    "type": "http",
    "url": "https://openalgo-mcp.vercel.app"
  }
}
```

### Test the Deployment

```bash
# Using curl
curl https://your-deployment.vercel.app/health

# Or visit in browser
https://your-deployment.vercel.app
```

## Troubleshooting

### Common Issues

#### 1. "Cannot connect to localhost"
**Problem:** OpenAlgo is running on localhost
**Solution:** Use a tunnel service (Ngrok, Cloudflare Tunnel) or deploy OpenAlgo publicly

#### 2. "Function timeout"
**Problem:** Request takes longer than 60 seconds
**Solution:**
- Optimize queries
- Upgrade to Vercel Pro (300s timeout)
- Consider alternative hosting (Railway, Fly.io)

#### 3. "Module not found"
**Problem:** Missing dependencies
**Solution:** Ensure `requirements.txt` is in the root directory

#### 4. "Environment variable not set"
**Problem:** Missing API key or host
**Solution:**
```bash
vercel env add OPENALGO_API_KEY
vercel env add OPENALGO_HOST
vercel --prod  # Redeploy
```

### View Logs

```bash
# Real-time logs
vercel logs

# Production logs
vercel logs --prod

# Follow logs
vercel logs --follow
```

## Limitations

### Vercel Serverless Constraints

- **Execution Time:** 60 seconds (Hobby), 300 seconds (Pro)
- **Memory:** 1024 MB (configurable)
- **Stateless:** Each request starts fresh
- **Cold Starts:** First request may be slower

### Recommendations

For production trading systems, consider:
- **Railway** - Better for persistent services
- **Fly.io** - Global edge deployment
- **Render** - Predictable pricing
- **VPS** - Full control

## Updating Your Deployment

```bash
# Update code
git add .
git commit -m "Update"
git push

# Or with Vercel CLI
vercel --prod
```

## Monitoring

### Vercel Dashboard
- View deployments: `vercel ls`
- Check logs: `vercel logs`
- Monitor metrics in [Vercel Dashboard](https://vercel.com/dashboard)

### Add Custom Domain (Optional)

```bash
vercel domains add yourdomain.com
```

Then update DNS:
```
Type: CNAME
Name: @
Value: cname.vercel-dns.com
```

## Security Considerations

1. **API Key Protection:**
   - Never commit API keys to Git
   - Use Vercel environment variables
   - Rotate keys regularly

2. **Access Control:**
   - Consider adding authentication
   - Use Vercel's edge middleware for protection
   - Implement rate limiting

3. **OpenAlgo Security:**
   - Use HTTPS for OpenAlgo host
   - Implement API authentication
   - Regular security updates

## Support

- **Vercel Docs:** https://vercel.com/docs
- **OpenAlgo Issues:** https://github.com/marketcalls/openalgo/issues
- **MCP Docs:** https://vercel.com/docs/mcp/deploy-mcp-servers-to-vercel

## Next Steps

1. ✅ Deploy to Vercel
2. ✅ Configure environment variables
3. ✅ Test with MCP client
4. 📊 Monitor performance
5. 🔒 Implement security measures
6. 📈 Scale as needed

---

**Happy Trading! 🚀**
