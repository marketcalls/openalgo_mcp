It has been repackaged for use as a module without necessity of cloning repos and installing python script.

Requirements:
- Local 3.12 or higher Python 
- uvx installed

How to Install uvx (uv)
-----------------------

- **Universal (Windows, Linux, Mac):**
  ```sh
  pip install uv
  ```
- **Mac (with Homebrew):**
  ```sh
  brew install uv
  ```
- **Prebuilt binaries:**  
  Download from [uv releases](https://github.com/astral-sh/uv/releases) for your platform.

After installation, the `uvx` command will be available in your terminal.

## Usage

### Option 1: stdio Transport (Default)

Add an entry similar to below on your favorite MCP Client. The below is tested with Cline plugin on VSCode:

```
 "openalgo": {
      "disabled": false,
      "timeout": 60,
      "type": "stdio",
      "command": "uvx",
      "args": [
        "openalgo-mcp@latest",
        "YOUR-OPENALGO-KEY",
        "http://127.0.0.1:5000"
      ]
    }
```

### Option 2: streamable-http Transport

For HTTP-based access (useful for web clients or remote access):

#### Start the server:
```bash
uvx openalgo-mcp@latest YOUR-OPENALGO-KEY http://127.0.0.1:5000 --transport streamable-http --http-host 0.0.0.0 --http-port 8000
```

#### MCP Client Configuration:
```json
{
  "openalgo": {
    "disabled": false,
    "timeout": 60,
    "type": "http",
    "url": "http://localhost:8000"
  }
}
```

#### Command-line Options:
- `--transport`: Choose between `stdio` (default) or `streamable-http`
- `--http-host`: HTTP server host (default: `0.0.0.0`)
- `--http-port`: HTTP server port (default: `8000`)

#### Examples:

**Run with default stdio transport:**
```bash
uvx openalgo-mcp@latest YOUR-API-KEY http://127.0.0.1:5000
```

**Run with streamable-http on default port (8000):**
```bash
uvx openalgo-mcp@latest YOUR-API-KEY http://127.0.0.1:5000 --transport streamable-http
```

**Run with custom HTTP host and port:**
```bash
uvx openalgo-mcp@latest YOUR-API-KEY http://127.0.0.1:5000 --transport streamable-http --http-host 127.0.0.1 --http-port 9000
```

### Option 3: Deploy on VPS (Production)

Deploy OpenAlgo MCP on a VPS server (Vultr, DigitalOcean, AWS EC2, etc.) with HTTPS:

#### Quick Setup

```bash
# 1. Upload deployment files from your local machine
scp -r deploy src pyproject.toml requirements.txt root@your-server-ip:/tmp/

# 2. Connect to your server
ssh root@your-server-ip

# 3. Run installation (will prompt for domain name)
chmod +x /tmp/deploy/install.sh
/tmp/deploy/install.sh
# Enter your domain when prompted (e.g., mcp.yourdomain.com)

# 4. Configure OpenAlgo credentials
sudo nano /opt/openalgo-mcp/.env

# 5. Copy application files
sudo cp -r /tmp/src/* /opt/openalgo-mcp/
cd /opt/openalgo-mcp && source venv/bin/activate && pip install -e .

# 6. Setup systemd service
sudo cp /tmp/deploy/openalgo-mcp.service /etc/systemd/system/
sudo systemctl enable --now openalgo-mcp

# 7. Setup Nginx (automatically uses your domain)
chmod +x /tmp/deploy/setup-nginx.sh
sudo /tmp/deploy/setup-nginx.sh

# 8. Get SSL certificate
sudo certbot --nginx -d your-domain.com
```

#### Features
- ✅ Full HTTPS with Let's Encrypt
- ✅ Nginx reverse proxy
- ✅ Systemd auto-restart
- ✅ Cloudflare integration support
- ✅ Production-ready configuration

📖 **Complete deployment guide:** See [deploy/DEPLOYMENT_GUIDE.md](./deploy/DEPLOYMENT_GUIDE.md)

---

## Features

OpenAlgo MCP provides **34 trading tools** across multiple categories:

### 📈 Order Management (9 tools)
- **place_order** - Place market, limit, stop-loss orders
- **place_smart_order** - Smart order with position sizing
- **place_basket_order** - Execute multiple orders in a basket
- **place_split_order** - Split large orders into smaller chunks
- **place_options_order** - 🆕 Place options orders with ATM/ITM/OTM offset
- **place_options_multi_order** - 🆕 Multi-leg options strategies (spreads, iron condor, etc.)
- **modify_order** - Modify existing orders
- **cancel_order** - Cancel specific orders
- **cancel_all_orders** - Cancel all open orders for a strategy

### 📊 Position Management (2 tools)
- **close_all_positions** - Close all positions for a strategy
- **get_open_position** - Get current open position for an instrument

### 📋 Order Status & Tracking (7 tools)
- **get_order_status** - Get status of a specific order
- **get_order_book** - View all orders
- **get_trade_book** - View all executed trades
- **get_position_book** - View all current positions
- **get_holdings** - View long-term holdings
- **get_funds** - Get account funds and margin info
- **calculate_margin** - 🆕 Calculate margin requirements for positions

### 📉 Market Data (3 tools)
- **get_quote** - Get current quote for a symbol
- **get_market_depth** - Get market depth (Level 2 data)
- **get_historical_data** - Get historical OHLCV data

### 🔍 Instrument Search & Info (8 tools)
- **search_instruments** - Search for stocks, futures, options
- **get_symbol_info** - Get detailed symbol information
- **get_index_symbols** - Get NSE/BSE index symbols
- **get_expiry_dates** - Get derivative expiry dates
- **get_available_intervals** - Get available timeframes
- **get_option_symbol** - 🆕 Get option symbol for specific strike
- **get_synthetic_future** - 🆕 Calculate synthetic future price
- **get_option_greeks** - 🆕 Calculate Greeks (delta, gamma, theta, vega, rho)

### 🛠️ Utility Tools (3 tools)
- **get_openalgo_version** - Get version information
- **validate_order_constants** - View valid order parameters
- **send_telegram_alert** - 🆕 Send Telegram notifications

### 🔬 Analyzer Tools (2 tools)
- **analyzer_status** - Get analyzer mode status
- **analyzer_toggle** - Toggle between analyze/live mode

---

## 🆕 New Options Trading Features

### Advanced Options Order Placement

**Place Options Order with Offset:**
```python
# Buy ATM Call option
place_options_order(
    underlying="NIFTY",
    exchange="NSE_INDEX",
    expiry_date="28NOV25",
    offset="ATM",
    option_type="CE",
    action="BUY",
    quantity=75,
    strategy="MyStrategy"
)

# Sell OTM Put option
place_options_order(
    underlying="BANKNIFTY",
    exchange="NSE_INDEX",
    expiry_date="27NOV25",
    offset="OTM5",
    option_type="PE",
    action="SELL",
    quantity=75,
    product="NRML"
)
```

**Multi-Leg Options Strategies:**
```python
# Iron Condor
place_options_multi_order(
    strategy="IronCondor",
    underlying="NIFTY",
    exchange="NSE_INDEX",
    expiry_date="28NOV25",
    legs='[
        {"offset": "OTM6", "option_type": "CE", "action": "BUY", "quantity": 75},
        {"offset": "OTM6", "option_type": "PE", "action": "BUY", "quantity": 75},
        {"offset": "OTM4", "option_type": "CE", "action": "SELL", "quantity": 75},
        {"offset": "OTM4", "option_type": "PE", "action": "SELL", "quantity": 75}
    ]'
)

# Diagonal Spread (different expiry dates)
place_options_multi_order(
    strategy="DiagonalSpread",
    underlying="NIFTY",
    exchange="NSE_INDEX",
    legs='[
        {"offset": "ITM2", "option_type": "CE", "action": "BUY", "quantity": 75, "expiry_date": "30DEC25"},
        {"offset": "OTM2", "option_type": "CE", "action": "SELL", "quantity": 75, "expiry_date": "28NOV25"}
    ]'
)
```

### Options Analytics

**Get Option Symbol:**
```python
# Get the exact option symbol for ATM Call
get_option_symbol(
    underlying="NIFTY",
    exchange="NSE_INDEX",
    expiry_date="28NOV25",
    offset="ATM",
    option_type="CE"
)
# Returns: {"symbol": "NIFTY25NOV2526000CE", "lotsize": 75, "tick_size": 0.05, ...}
```

**Calculate Option Greeks:**
```python
get_option_greeks(
    symbol="NIFTY25NOV2526000CE",
    exchange="NFO",
    underlying_symbol="NIFTY",
    underlying_exchange="NSE_INDEX",
    interest_rate=0.06
)
# Returns: {"delta": 0.52, "gamma": 0.003, "theta": -15.2, "vega": 12.5, "rho": 8.3, "iv": 18.5, ...}
```

**Calculate Synthetic Future:**
```python
get_synthetic_future(
    underlying="NIFTY",
    exchange="NSE_INDEX",
    expiry_date="28NOV25"
)
# Returns: {"synthetic_future_price": 24523.50, "atm_strike": 24500, ...}
```

### Margin Calculation

**Calculate Margin Requirements:**
```python
# For Options
calculate_margin(
    positions_json='[{
        "symbol": "NIFTY25NOV2525000CE",
        "exchange": "NFO",
        "action": "BUY",
        "product": "NRML",
        "pricetype": "MARKET",
        "quantity": "75"
    }]'
)

# For Futures
calculate_margin(
    positions_json='[{
        "symbol": "NIFTY25NOV25FUT",
        "exchange": "NFO",
        "action": "BUY",
        "product": "NRML",
        "pricetype": "MARKET",
        "quantity": "25"
    }]'
)
# Returns: {"total_margin_required": 125000, "span_margin": 100000, "exposure_margin": 25000}
```

### Telegram Alerts

**Send Trading Alerts:**
```python
send_telegram_alert(
    username="your_openalgo_username",
    message="🚀 Position opened: NIFTY 26000 CE @ 150"
)
```

---

## Supported Exchanges

- **NSE** - NSE Equity
- **NFO** - NSE Futures & Options
- **CDS** - NSE Currency
- **BSE** - BSE Equity
- **BFO** - BSE Futures & Options
- **BCD** - BSE Currency
- **MCX** - MCX Commodity
- **NCDEX** - NCDEX Commodity

## Product Types

- **CNC** - Cash & Carry (delivery)
- **NRML** - Normal (for F&O)
- **MIS** - Intraday Square Off

## Order Types

- **MARKET** - Market Order
- **LIMIT** - Limit Order
- **SL** - Stop Loss Limit
- **SL-M** - Stop Loss Market

## Strike Offsets (Options)

- **ATM** - At The Money
- **ITM1** to **ITM10** - In The Money (1-10 strikes)
- **OTM1** to **OTM10** - Out of The Money (1-10 strikes)

---

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project follows the license of the original OpenAlgo project.

## Credits

- Original logic from [OpenAlgo by MarketCalls](https://github.com/marketcalls/openalgo)
- MCP implementation using [FastMCP](https://github.com/jlowin/fastmcp)

---

## Version History

### v0.1.8 (Latest)
- ✅ Added streamable-http transport support
- ✅ Added 7 new trading tools
- ✅ Advanced options trading with ATM/ITM/OTM offset
- ✅ Multi-leg options strategies support
- ✅ Options Greeks calculation
- ✅ Margin calculation tool
- ✅ Synthetic future pricing
- ✅ Telegram alert notifications
- ✅ Total of 34 trading tools available