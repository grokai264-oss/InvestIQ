"""NSE delivery + FII/DII with in-memory TTL cache (no Redis required on Render)."""
from __future__ import annotations

import time
from typing import Any, Dict, Optional
from loguru import logger

try:
    import requests
except ImportError:
    requests = None


class _TTLCache:
    def __init__(self):
        self._store: Dict[str, tuple] = {}

    def get(self, key: str):
        item = self._store.get(key)
        if not item:
            return None
        val, exp = item
        if time.time() > exp:
            self._store.pop(key, None)
            return None
        return val

    def set(self, key: str, value, ttl: int):
        self._store[key] = (value, time.time() + ttl)


_cache = _TTLCache()


class NSEFetcher:
    def __init__(self):
        self._session = None
        if requests is None:
            return
        self._session = requests.Session()
        self._session.headers.update(
            {
                "User-Agent": (
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/120.0.0.0 Safari/537.36"
                ),
                "Accept": "application/json,text/html,*/*",
                "Accept-Language": "en-US,en;q=0.9",
                "Referer": "https://www.nseindia.com/",
            }
        )
        try:
            self._session.get("https://www.nseindia.com", timeout=8)
        except Exception as e:
            logger.warning(f"NSE session warmup failed: {e}")

    def fetch_delivery_data(self, symbol: str) -> float:
        key = f"del:{symbol.upper()}"
        hit = _cache.get(key)
        if hit is not None:
            return float(hit)
        if self._session is None:
            return 0.0
        url = f"https://www.nseindia.com/api/quote-equity?symbol={symbol.upper()}&section=trade_info"
        try:
            r = self._session.get(url, timeout=10)
            if r.status_code != 200:
                return 0.0
            data = r.json()
            pct = data.get("securityWiseDP", {}).get("deliveryToTradedQuantity", 0.0)
            val = float(pct or 0.0)
            _cache.set(key, val, 900)
            return val
        except Exception as e:
            logger.debug(f"delivery {symbol}: {e}")
            return 0.0

    def fetch_fii_dii_data(self) -> Dict[str, float]:
        key = "fii_dii"
        hit = _cache.get(key)
        if hit is not None:
            return hit
        empty = {"fii_net_cr": 0.0, "dii_net_cr": 0.0}
        if self._session is None:
            return empty
        try:
            r = self._session.get("https://www.nseindia.com/api/fiidiiTradeReact", timeout=10)
            if r.status_code != 200:
                return empty
            data = r.json()
            fii_net = dii_net = 0.0
            if isinstance(data, list):
                for item in data:
                    cat = str(item.get("category", ""))
                    buy = float(str(item.get("buyValue", 0)).replace(",", "") or 0)
                    sell = float(str(item.get("sellValue", 0)).replace(",", "") or 0)
                    if "FII" in cat.upper() or "FPI" in cat.upper():
                        fii_net = buy - sell
                    elif "DII" in cat.upper():
                        dii_net = buy - sell
            out = {"fii_net_cr": round(fii_net, 2), "dii_net_cr": round(dii_net, 2)}
            _cache.set(key, out, 43200)
            return out
        except Exception as e:
            logger.debug(f"fii/dii: {e}")
            return empty
