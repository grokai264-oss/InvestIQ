"""InvestIQ FastAPI entry — read-only research API (v2.3 Research Foundations).

Secrets only via environment variables. Never places orders.
"""
from __future__ import annotations

import secrets
import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, Query, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from loguru import logger

from config.settings import settings
from engines.equity_universe import search_equity
from engines.quotes import quotes_for

try:
    from ingestion.kotak_client import kotak
except Exception:  # pragma: no cover
    kotak = None  # type: ignore

app = FastAPI(
    title="InvestIQ API",
    version="2.3.0",
    description="Read-only research API. Continuous OHLCV scoring. Never places orders.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "OPTIONS"],
    allow_headers=["*"],
)

_start = time.time()


@app.get("/", response_model=None)
def root(request: Request):
    """Landing for browser wake-up + API discovery.

    Free Render dynos sleep after idle. The Flutter app asks users to open this
    URL once so the instance boots. Without a root route FastAPI returned
    {"detail":"Not Found"}, which looked broken. Browsers get a small HTML
    page; clients get JSON.
    """
    payload: Dict[str, Any] = {
        "service": "InvestIQ Research API",
        "version": "2.3.0",
        "status": "ok",
        "engine": "2.3",
        "uptime_sec": round(time.time() - _start, 1),
        "docs": "/docs",
        "health": "/health",
        "message": "Read-only multi-horizon stock research. Never places orders.",
        "endpoints": {
            "health": "/health",
            "top_recommendations": "/api/v1/recommendations/top",
            "symbol": "/api/v1/recommendations/{symbol}",
            "history": "/api/v1/stocks/{symbol}/history",
            "movers": "/api/v1/market/movers",
            "indices": "/api/v1/indices",
            "search": "/api/v1/search",
            "quotes": "/api/v1/quotes",
            "portfolio": "/api/v1/portfolio/summary",
        },
    }
    accept = (request.headers.get("accept") or "").lower()
    if "text/html" in accept:
        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>InvestIQ API</title>
<style>
  body {{ margin:0; font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
         background:#0b0f14; color:#e8eef5; display:flex; min-height:100vh;
         align-items:center; justify-content:center; }}
  .card {{ max-width:520px; padding:28px 32px; border-radius:16px;
           background:#12181f; border:1px solid #1e2936; box-shadow:0 12px 40px rgba(0,0,0,.35); }}
  h1 {{ margin:0 0 6px; font-size:1.45rem; letter-spacing:-0.02em; }}
  .ok {{ color:#34d399; font-weight:600; font-size:0.9rem; margin-bottom:8px; }}
  p {{ color:#9aa7b5; line-height:1.55; margin:12px 0; }}
  a {{ color:#5eead4; text-decoration:none; }}
  a:hover {{ text-decoration:underline; }}
  .meta {{ font-size:0.85rem; margin-top:18px; color:#6b7785; }}
</style>
</head>
<body>
  <div class="card">
    <div class="ok">● Online</div>
    <h1>InvestIQ Research API</h1>
    <p>Read-only multi-horizon stock research desk. <strong>Never places orders.</strong></p>
    <p>Server is awake. Return to the app and tap <strong>Retry</strong>.</p>
    <p><a href="/docs">Open API docs</a> · <a href="/health">Health</a></p>
    <p class="meta">v{payload['version']} · uptime {payload['uptime_sec']}s · engine {payload['engine']}</p>
  </div>
</body>
</html>"""
        return HTMLResponse(html)
    return JSONResponse(payload)


@app.get("/health")
def health() -> Dict[str, Any]:
    return {
        "status": "ok",
        "engine": "2.3",
        "uptime_sec": round(time.time() - _start, 1),
        "kotak_configured": settings.kotak_configured,
        "universe_size": len(settings.symbols),
        "portfolio_token_required": bool(getattr(settings, "PORTFOLIO_ACCESS_TOKEN", None)),
    }


@app.get("/api/v1/search")
def api_search(q: str = "", limit: int = Query(25, ge=1, le=50)) -> Dict[str, Any]:
    return {"results": search_equity(q, limit=limit)}


@app.get("/api/v1/quotes")
def api_quotes(symbols: str = "") -> Dict[str, Any]:
    syms = [s.strip() for s in symbols.split(",") if s.strip()]
    holdings = None
    if kotak is not None and settings.kotak_configured and getattr(kotak, "ready", False):
        try:
            holdings = kotak.normalized_holdings()
        except Exception as e:
            logger.debug(f"holdings for quotes: {e}")
    return {"quotes": quotes_for(syms, kotak_holdings=holdings)}


@app.get("/api/v1/indices")
def api_indices() -> Dict[str, Any]:
    idx = [
        ("NIFTY 50", "^NSEI"),
        ("BANK NIFTY", "^NSEBANK"),
        ("INDIA VIX", "^INDIAVIX"),
    ]
    out: List[Dict[str, Any]] = []
    try:
        import yfinance as yf
        for name, ticker in idx:
            try:
                t = yf.Ticker(ticker)
                hist = t.history(period="5d")
                if hist is None or hist.empty:
                    continue
                last = float(hist["Close"].iloc[-1])
                prev = float(hist["Close"].iloc[-2]) if len(hist) > 1 else last
                chg = ((last - prev) / prev * 100.0) if prev else 0.0
                out.append({"name": name, "ltp": round(last, 2), "change_pct": round(chg, 2)})
            except Exception:
                continue
    except Exception as e:
        logger.debug(f"indices: {e}")
    return {"indices": out}


@app.get("/api/v1/portfolio/summary")
def api_portfolio(
    x_investiq_token: Optional[str] = Header(default=None, alias="X-InvestIQ-Token"),
) -> Dict[str, Any]:
    expected = getattr(settings, "PORTFOLIO_ACCESS_TOKEN", None)
    if expected:
        if not x_investiq_token or not secrets.compare_digest(x_investiq_token, expected):
            raise HTTPException(status_code=401, detail="Portfolio requires valid X-InvestIQ-Token")
    if not settings.kotak_configured or kotak is None:
        return {
            "linked": False,
            "message": "Kotak not configured on server.",
            "total_value": 0,
            "total_pnl": 0,
            "total_pnl_pct": 0,
            "holdings": [],
        }
    try:
        if not getattr(kotak, "ready", False):
            ok = kotak.connect(
                consumer_key=settings.KOTAK_CONSUMER_KEY or "",
                mobile=settings.KOTAK_MOBILE or "",
                ucc=settings.KOTAK_UCC or "",
                mpin=settings.KOTAK_MPIN or "",
                totp_secret=settings.KOTAK_TOTP_SECRET or "",
                environment=settings.KOTAK_ENVIRONMENT,
            )
            if not ok:
                return {
                    "linked": False,
                    "message": getattr(kotak, "last_error", None) or "Kotak session failed",
                    "total_value": 0,
                    "total_pnl": 0,
                    "total_pnl_pct": 0,
                    "holdings": [],
                }
        holdings = kotak.normalized_holdings()
        total_value = sum(h.get("mkt_value", 0) for h in holdings)
        total_pnl = sum(h.get("pnl", 0) for h in holdings)
        cost = total_value - total_pnl
        pct = (total_pnl / cost * 100.0) if cost else 0.0
        return {
            "linked": True,
            "message": "ok",
            "total_value": round(total_value, 2),
            "total_pnl": round(total_pnl, 2),
            "total_pnl_pct": round(pct, 2),
            "holdings": holdings,
        }
    except Exception as e:
        logger.exception("portfolio")
        return {
            "linked": False,
            "message": str(e),
            "total_value": 0,
            "total_pnl": 0,
            "total_pnl_pct": 0,
            "holdings": [],
        }


@app.get("/api/v1/market/movers")
def api_movers(
    kind: str = Query("gainers", description="gainers|losers|active"),
    limit: int = Query(10, ge=1, le=30),
) -> Dict[str, Any]:
    from engines.quotes import quotes_for
    from engines.live_engine import score_symbol

    syms = settings.symbols[:80]
    quotes = quotes_for(syms)
    rows = []
    for q in quotes:
        ch = q.get("change_pct")
        ltp = q.get("ltp")
        if ch is None or ltp is None:
            continue
        rows.append({
            "symbol": q.get("symbol"),
            "ltp": ltp,
            "change_pct": round(float(ch), 2),
            "source": q.get("source") or "market",
        })
    if kind == "losers":
        rows.sort(key=lambda x: x["change_pct"])
    elif kind == "active":
        rows.sort(key=lambda x: abs(x["change_pct"]), reverse=True)
    else:
        rows.sort(key=lambda x: x["change_pct"], reverse=True)
    top = rows[:limit]
    for r in top[: min(8, len(top))]:
        try:
            sc = score_symbol(r["symbol"], timeframe="daily")
            r["final_score"] = sc.get("final_score")
            r["action"] = sc.get("action")
            r["factors"] = {
                k: sc["factors"][k]
                for k in ("score_momentum", "score_ema", "score_rsi")
                if k in sc.get("factors", {})
            }
        except Exception:
            r["final_score"] = None
    return {"kind": kind, "movers": top, "universe": len(syms), "engine": "2.3"}


@app.get("/api/v1/recommendations/top")
def api_top(
    timeframe: str = "daily",
    limit: int = Query(10, ge=1, le=25),
) -> Dict[str, Any]:
    from engines.live_engine import rank_universe

    pool = settings.symbols[: min(len(settings.symbols), max(60, limit * 5))]
    return rank_universe(pool, timeframe=timeframe, limit=limit, max_workers=8)


@app.get("/api/v1/recommendations/{symbol}")
def api_one(symbol: str, timeframe: str = "daily") -> Dict[str, Any]:
    from engines.live_engine import score_symbol
    return score_symbol(symbol, timeframe=timeframe)


@app.get("/api/v1/stocks/{symbol}/history")
def api_history(
    symbol: str,
    range: str = Query("1M", description="1D|1W|1M|3M|1Y|5Y"),
) -> Dict[str, Any]:
    from engines.data_fetcher import LiveDataFetcher
    import pandas as pd

    period_map = {
        "1D": ("5d", "1h"),
        "1W": ("1mo", "1d"),
        "1M": ("3mo", "1d"),
        "3M": ("6mo", "1d"),
        "1Y": ("1y", "1d"),
        "5Y": ("5y", "1wk"),
    }
    period, interval = period_map.get(range.upper(), ("3mo", "1d"))
    sym = symbol.upper().replace(".NS", "")
    points: List[Dict[str, Any]] = []
    try:
        import yfinance as yf
        t = yf.Ticker(f"{sym}.NS")
        hist = t.history(period=period, interval=interval, auto_adjust=True)
        if hist is not None and not hist.empty:
            hist = hist.dropna(subset=["Close"])
            for ts, row in hist.iterrows():
                points.append({
                    "t": pd.Timestamp(ts).isoformat(),
                    "c": round(float(row["Close"]), 2),
                    "o": round(float(row.get("Open", row["Close"])), 2),
                    "h": round(float(row.get("High", row["Close"])), 2),
                    "l": round(float(row.get("Low", row["Close"])), 2),
                    "v": int(row.get("Volume", 0) or 0),
                })
    except Exception as e:
        logger.debug(f"history yf {sym}: {e}")
        try:
            days = {"1D": 5, "1W": 10, "1M": 40, "3M": 90, "1Y": 260, "5Y": 1200}.get(range.upper(), 40)
            df = LiveDataFetcher.fetch_daily_ohlcv(sym, days=days)
            for ts, row in df.iterrows():
                points.append({
                    "t": pd.Timestamp(ts).isoformat(),
                    "c": round(float(row["close"]), 2),
                    "o": round(float(row["open"]), 2),
                    "h": round(float(row["high"]), 2),
                    "l": round(float(row["low"]), 2),
                    "v": int(row.get("volume", 0) or 0),
                })
        except Exception as e2:
            logger.debug(f"history fallback {sym}: {e2}")

    return {
        "symbol": sym,
        "range": range.upper(),
        "points": points,
        "count": len(points),
        "source": "yahoo",
    }
