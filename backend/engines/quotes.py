"""Equity LTP — fast path with short timeouts and in-memory cache."""
from __future__ import annotations

import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any, Dict, List, Optional
from loguru import logger

try:
    import yfinance as yf
except ImportError:
    yf = None

_cache: Dict[str, tuple] = {}  # symbol -> (ts, payload)
_CACHE_TTL = 20  # seconds — near-live without hammering


def _cached_get(symbol: str) -> Optional[Dict[str, Any]]:
    item = _cache.get(symbol)
    if not item:
        return None
    ts, payload = item
    if time.time() - ts > _CACHE_TTL:
        return None
    return payload


def _cached_put(symbol: str, payload: Dict[str, Any]) -> None:
    _cache[symbol] = (time.time(), payload)


def _yahoo_ltp(symbol: str) -> Optional[Dict[str, Any]]:
    hit = _cached_get(symbol)
    if hit is not None:
        return hit
    if yf is None:
        return None
    sym = symbol.upper().replace(".NS", "").replace("-EQ", "")
    try:
        t = yf.Ticker(f"{sym}.NS")
        last = None
        prev = None
        fi = getattr(t, "fast_info", None)
        if fi is not None:
            try:
                last = float(getattr(fi, "last_price", None) or 0) or None
            except Exception:
                last = None
            try:
                prev = float(getattr(fi, "previous_close", None) or 0) or None
            except Exception:
                prev = None
        if last is None:
            hist = t.history(period="5d")
            if hist is not None and not hist.empty:
                last = float(hist["Close"].iloc[-1])
                if len(hist) > 1:
                    prev = float(hist["Close"].iloc[-2])
        if last is None:
            return None
        prev = prev if prev is not None else last
        chg = ((last - prev) / prev * 100.0) if prev else 0.0
        payload = {
            "symbol": sym,
            "ltp": round(float(last), 2),
            "change_pct": round(float(chg), 2),
            "source": "market",
            "segment": "EQ",
        }
        _cached_put(sym, payload)
        return payload
    except Exception as e:
        logger.debug(f"yahoo quote {sym}: {e}")
        return None


def quotes_for(
    symbols: List[str],
    kotak_holdings: Optional[List[Dict[str, Any]]] = None,
) -> List[Dict[str, Any]]:
    kotak_map: Dict[str, float] = {}
    if kotak_holdings:
        for h in kotak_holdings:
            s = str(h.get("symbol", "")).upper()
            ltp = h.get("ltp")
            if s and ltp is not None:
                kotak_map[s] = float(ltp)

    cleaned: List[str] = []
    seen = set()
    for raw in symbols:
        sym = str(raw).upper().replace(".NS", "").replace("-EQ", "").strip()
        if sym and sym not in seen:
            seen.add(sym)
            cleaned.append(sym)

    out: List[Dict[str, Any]] = []
    need_fetch: List[str] = []

    for sym in cleaned:
        if sym in kotak_map:
            out.append(
                {
                    "symbol": sym,
                    "ltp": round(kotak_map[sym], 2),
                    "change_pct": None,
                    "source": "kotak",
                    "segment": "EQ",
                }
            )
        else:
            need_fetch.append(sym)

    # Parallel Yahoo fetch (capped workers)
    fetched: Dict[str, Dict[str, Any]] = {}
    if need_fetch:
        with ThreadPoolExecutor(max_workers=min(8, len(need_fetch))) as pool:
            futs = {pool.submit(_yahoo_ltp, s): s for s in need_fetch}
            for fut in as_completed(futs):
                s = futs[fut]
                try:
                    q = fut.result()
                    if q:
                        fetched[s] = q
                except Exception:
                    pass

    for sym in need_fetch:
        if sym in fetched:
            out.append(fetched[sym])
        else:
            out.append(
                {
                    "symbol": sym,
                    "ltp": None,
                    "change_pct": None,
                    "source": "unavailable",
                    "segment": "EQ",
                }
            )

    # preserve request order
    order = {s: i for i, s in enumerate(cleaned)}
    out.sort(key=lambda x: order.get(x["symbol"], 999))
    return out
