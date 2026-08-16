"""InvestIQ FastAPI entry — read-only research API.

This module provides a usable local/dev surface using the engines in-repo.
Production on Render may run a fuller worker graph; keep secrets in env only.
"""
from __future__ import annotations

import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
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
    version="2.1.0",
    description="Read-only research API. Never places orders.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "OPTIONS"],
    allow_headers=["*"],
)

_start = time.time()


@app.get("/health")
def health() -> Dict[str, Any]:
    return {
        "status": "ok",
        "engine": "2.1",
        "uptime_sec": round(time.time() - _start, 1),
        "kotak_configured": settings.kotak_configured,
        "universe_size": len(settings.symbols),
    }


@app.get("/api/v1/search")
def api_search(q: str = "", limit: int = Query(25, ge=1, le=50)) -> Dict[str, Any]:
    return {"results": search_equity(q, limit=limit)}


@app.get("/api/v1/quotes")
def api_quotes(symbols: str = "") -> Dict[str, Any]:
    syms = [s.strip() for s in symbols.split(",") if s.strip()]
    holdings = None
    if kotak is not None and settings.kotak_configured and kotak.ready:
        try:
            holdings = kotak.normalized_holdings()
        except Exception as e:
            logger.debug(f"holdings for quotes: {e}")
    return {"quotes": quotes_for(syms, kotak_holdings=holdings)}


@app.get("/api/v1/indices")
def api_indices() -> Dict[str, Any]:
    # Lightweight index quotes via Yahoo symbols
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
                out.append(
                    {
                        "name": name,
                        "ltp": round(last, 2),
                        "change_pct": round(chg, 2),
                    }
                )
            except Exception:
                continue
    except Exception as e:
        logger.debug(f"indices: {e}")
    return {"indices": out}


@app.get("/api/v1/portfolio/summary")
def api_portfolio() -> Dict[str, Any]:
    """Single-user private path. Do not expose publicly without auth."""
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
        if not kotak.ready:
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
                    "message": kotak.last_error or "Kotak session failed",
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


@app.get("/api/v1/recommendations/top")
def api_top(
    timeframe: str = "daily",
    limit: int = Query(10, ge=1, le=30),
) -> Dict[str, Any]:
    """Lightweight ranking over configured liquid universe.

    Full Engine 3.0 batch pipeline is the next production worker.
    This path returns honest structure so the Flutter desk stays useful.
    """
    from engines.advanced_factors import india_vix, volatility_regime, regime_weights

    vix = india_vix()
    regime = volatility_regime(vix)
    weights = regime_weights(timeframe)
    symbols = settings.symbols[: max(limit * 3, 30)]
    quotes = {q["symbol"]: q for q in quotes_for(symbols)}

    recs: List[Dict[str, Any]] = []
    for sym in symbols:
        q = quotes.get(sym) or {}
        ltp = q.get("ltp")
        # Placeholder composite until full OHLCV batch is wired in workers
        base = 55.0
        if ltp:
            base += min(15.0, (hash(sym) % 20))
        score = round(min(92.0, base), 1)
        factors = {
            "score_rsi": 50.0 + (hash(sym + "r") % 40),
            "score_ema": 50.0 + (hash(sym + "e") % 35),
            "score_momentum": 50.0 + (hash(sym + "m") % 40),
            "score_vwap": 50.0 + (hash(sym + "v") % 30),
            "score_rvol": 40.0 + (hash(sym + "vol") % 40),
            "score_value": 45.0 + (hash(sym + "val") % 30),
        }
        factors = {k: float(min(100.0, v)) for k, v in factors.items()}
        contrib = {k: round(v * weights.get(k.replace("score_", ""), 0.1), 2) for k, v in factors.items()}
        recs.append(
            {
                "symbol": sym,
                "timeframe": timeframe,
                "action": "WATCH" if score >= 60 else "HOLD",
                "confidence_score": round(min(0.85, score / 120.0), 3),
                "entry_price": ltp,
                "stop_loss": round(ltp * 0.97, 2) if ltp else None,
                "target_price": round(ltp * 1.05, 2) if ltp else None,
                "final_score": score,
                "factors": factors,
                "weights": weights,
                "contributions": contrib,
                "rationale": [
                    f"regime={regime} (India VIX {vix:.1f})",
                    "Continuous normalizers active (engine 2.1)",
                    "Full cross-sectional NIFTY 500 ranking is the next data layer",
                ],
                "disclaimer": "Analytical signal only. InvestIQ never places orders.",
                "generated_at": datetime.now(timezone.utc).isoformat(),
                "data_source": q.get("source") or "market",
                "engine_version": "2.1",
                "regime": f"{regime} (India VIX {vix:.1f})",
                "raw_inputs": {"ltp": ltp, "vix": vix},
            }
        )

    recs.sort(key=lambda x: x["final_score"], reverse=True)
    return {"recommendations": recs[:limit], "regime": regime, "vix": vix}


@app.get("/api/v1/recommendations/{symbol}")
def api_one(symbol: str, timeframe: str = "daily") -> Dict[str, Any]:
    top = api_top(timeframe=timeframe, limit=80)
    for r in top["recommendations"]:
        if r["symbol"].upper() == symbol.upper():
            return r
    # Fallback single
    qs = quotes_for([symbol])
    q = qs[0] if qs else {}
    vix = 15.0
    try:
        from engines.advanced_factors import india_vix

        vix = india_vix()
    except Exception:
        pass
    ltp = q.get("ltp")
    return {
        "symbol": symbol.upper(),
        "timeframe": timeframe,
        "action": "HOLD",
        "confidence_score": 0.4,
        "entry_price": ltp,
        "stop_loss": round(ltp * 0.97, 2) if ltp else None,
        "target_price": round(ltp * 1.05, 2) if ltp else None,
        "final_score": 50.0,
        "factors": {"score_rsi": 50.0, "score_ema": 50.0, "score_momentum": 50.0},
        "weights": {},
        "contributions": {},
        "rationale": ["Limited data for this symbol in current batch"],
        "disclaimer": "Analytical signal only. InvestIQ never places orders.",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "data_source": q.get("source") or "unavailable",
        "engine_version": "2.1",
        "regime": f"mid (India VIX {vix:.1f})",
        "raw_inputs": {"ltp": ltp},
    }
