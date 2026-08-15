"""Equity LTP quotes — Kotak holdings LTP preferred when linked, else Yahoo."""
from __future__ import annotations

from typing import Any, Dict, List, Optional
from loguru import logger

try:
    import yfinance as yf
except ImportError:
    yf = None


def _yahoo_ltp(symbol: str) -> Optional[Dict[str, Any]]:
    if yf is None:
        return None
    sym = symbol.upper().replace(".NS", "").replace("-EQ", "")
    try:
        t = yf.Ticker(f"{sym}.NS")
        # fast_info often has lastPrice
        fi = getattr(t, "fast_info", None)
        last = None
        prev = None
        if fi is not None:
            last = getattr(fi, "last_price", None) or (fi.get("lastPrice") if isinstance(fi, dict) else None)
            prev = getattr(fi, "previous_close", None) or (fi.get("previousClose") if isinstance(fi, dict) else None)
        if last is None:
            hist = t.history(period="5d")
            if hist is not None and not hist.empty:
                last = float(hist["Close"].iloc[-1])
                if len(hist) > 1:
                    prev = float(hist["Close"].iloc[-2])
        if last is None:
            return None
        last = float(last)
        prev = float(prev) if prev is not None else last
        chg = ((last - prev) / prev * 100.0) if prev else 0.0
        return {
            "symbol": sym,
            "ltp": round(last, 2),
            "change_pct": round(chg, 2),
            "source": "market",
            "segment": "EQ",
        }
    except Exception as e:
        logger.debug(f"yahoo quote {sym}: {e}")
        return None


def quotes_for(
    symbols: List[str],
    kotak_holdings: Optional[List[Dict[str, Any]]] = None,
) -> List[Dict[str, Any]]:
    """Merge Kotak LTP (if symbol is in holdings) over market quotes."""
    kotak_map: Dict[str, float] = {}
    if kotak_holdings:
        for h in kotak_holdings:
            s = str(h.get("symbol", "")).upper()
            ltp = h.get("ltp")
            if s and ltp is not None:
                kotak_map[s] = float(ltp)

    out: List[Dict[str, Any]] = []
    seen = set()
    for raw in symbols:
        sym = str(raw).upper().replace(".NS", "").replace("-EQ", "").strip()
        if not sym or sym in seen:
            continue
        seen.add(sym)
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
            continue
        q = _yahoo_ltp(sym)
        if q:
            out.append(q)
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
    return out
