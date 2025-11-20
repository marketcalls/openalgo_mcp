"""
Vercel serverless function for OpenAlgo MCP Server
"""
import os
import sys
from pathlib import Path

# Add the src directory to the Python path
src_path = Path(__file__).parent.parent / "src"
sys.path.insert(0, str(src_path))

# Import after path is set
import nest_asyncio
nest_asyncio.apply()

from fastmcp import FastMCP
import httpx
from typing import List, Dict, Any, Optional
import json
import asyncio
import threading
from urllib.parse import urlparse

# Get API key and host from environment variables
api_key = os.environ.get("OPENALGO_API_KEY")
host = os.environ.get("OPENALGO_HOST")

if not api_key or not host:
    raise ValueError("OPENALGO_API_KEY and OPENALGO_HOST environment variables must be set")

print(f"Initializing OpenAlgo MCP Server...")
print(f"Host: {host}")

# Ensure host ends with /
if not host.endswith('/'):
    host += '/'

# Create MCP server
mcp = FastMCP("openalgo")

# HTTP Client class for OpenAlgo API
class OpenAlgoHTTPClient:
    def __init__(self, api_key: str, host: str):
        parsed = urlparse(host)
        origin = f"{parsed.scheme}://{parsed.netloc}"
        self.api_key = api_key
        self.base_url = f"{host}api/v1/"
        self.headers = {
            "Content-Type": "application/json",
            "Accept": "application/json, text/plain, */*",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
            "Origin": origin,
            "Referer": f"{origin}/",
            "Accept-Language": "en-US,en;q=0.9",
            "X-Requested-With": "XMLHttpRequest"
        }

    async def _make_request(self, endpoint: str, data: dict) -> dict:
        """Make HTTP POST request to OpenAlgo API"""
        data["apikey"] = self.api_key

        url = f"{self.base_url}{endpoint}"

        async with httpx.AsyncClient(
            base_url=self.base_url,
            headers=self.headers,
            timeout=30.0,
            http2=True,
            follow_redirects=True
        ) as client:
            try:
                response = await client.post(endpoint, json=data)
                response.raise_for_status()
                return response.json()
            except httpx.HTTPStatusError as e:
                body = ""
                try:
                    body = e.response.text if e.response is not None else ""
                except Exception:
                    pass
                status = e.response.status_code if e.response is not None else "unknown"
                reason = e.response.reason_phrase if e.response is not None else "unknown"
                url_info = str(e.request.url) if e.request is not None else url
                raise Exception(f"HTTP request failed: {status} {reason} for url '{url_info}' - Response body: {body[:500]}")
            except httpx.HTTPError as e:
                raise Exception(f"HTTP request failed: {str(e)}")
            except Exception as e:
                raise Exception(f"Request error: {str(e)}")

# Initialize HTTP client
http_client = OpenAlgoHTTPClient(api_key, host)

# Helper function to run async functions
def run_async(coro):
    """Run async function in sync context, safe for nested event loops."""
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        return asyncio.run(coro)
    else:
        import queue
        q = queue.Queue()

        def thread_worker():
            try:
                new_loop = asyncio.new_event_loop()
                asyncio.set_event_loop(new_loop)
                result = new_loop.run_until_complete(coro)
                q.put((result, None))
            except Exception as e:
                q.put((None, e))
            finally:
                new_loop.close()

        t = threading.Thread(target=thread_worker)
        t.start()
        result, error = q.get()
        t.join()
        if error:
            raise error
        return result

# Import all the tool definitions from mcpserver
# This is a simplified approach - in production, you'd want to refactor shared code

@mcp.tool()
def get_funds() -> str:
    """Get account funds and margin information."""
    try:
        data = {}
        response = run_async(http_client._make_request("funds", data))
        return json.dumps(response, indent=2)
    except Exception as e:
        return f"Error getting funds: {str(e)}"

@mcp.tool()
def get_holdings() -> str:
    """Get all holdings (long-term investments)."""
    try:
        data = {}
        response = run_async(http_client._make_request("holdings", data))
        return json.dumps(response, indent=2)
    except Exception as e:
        return f"Error getting holdings: {str(e)}"

@mcp.tool()
def get_position_book() -> str:
    """Get all current positions."""
    try:
        data = {}
        response = run_async(http_client._make_request("positionbook", data))
        return json.dumps(response, indent=2)
    except Exception as e:
        return f"Error getting position book: {str(e)}"

@mcp.tool()
def get_order_book() -> str:
    """Get all orders from the order book."""
    try:
        data = {}
        response = run_async(http_client._make_request("orderbook", data))
        return json.dumps(response, indent=2)
    except Exception as e:
        return f"Error getting order book: {str(e)}"

@mcp.tool()
def get_quote(symbol: str, exchange: str = "NSE") -> str:
    """
    Get current quote for a symbol.

    Args:
        symbol: Stock symbol
        exchange: Exchange name
    """
    try:
        data = {
            "symbol": symbol.upper(),
            "exchange": exchange.upper()
        }
        response = run_async(http_client._make_request("quotes", data))
        return json.dumps(response, indent=2)
    except Exception as e:
        return f"Error getting quote: {str(e)}"

# Export the FastMCP instance directly for Vercel
# FastMCP implements ASGI protocol, so it can be used directly
app = mcp

# For local testing
if __name__ == "__main__":
    print("Starting OpenAlgo MCP Server...")
    import uvicorn
    uvicorn.run(mcp, host="0.0.0.0", port=8000)
