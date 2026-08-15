"""
InvestIQ FastAPI — READ-ONLY live recommendation engine.
Never places orders.
"""
from __future__ import annotations

from typing import List, Optional, Literal
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from datetime import datetime, timezone
from contextlib import asynccontextmanager
from loguru import logger

from config.settings import settings

try:
    from ingestion.kotak_client import kotak
except Exception:
    kotak = None

try:
    from engines.live_engine import live_engine, DEFAULT_UNIVERSE
except Exception as e:
    live_engine = None
    DEFAULT_UNIVERSE = []
    logger.error(f"Live engine import failed: {e}")


def _try_kotak_connect() -> bool:
    if not settings.kotak_configured or kotak is None:
        return False
    try:
        return bool(
            kotak.connect(
                consumer_key=settings.KOTAK_CONSUMER_KEY,
                mobile=settings.KOTAK_MOBILE,
                ucc=settings.KOTAK_UCC,
                mpin=settings.KOTAK_MPIN,
                totp_secret=settings.KOTAK_TOTP_SECRET,
                environment=settings.KOTAK_ENVIRONMENT,
            )
        )
    except Exception as e:
        logger.warning(f"Kotak connect failed: {e}")
        return False


@asynccontextmanager
async def lifespan(app: FastAPI):
    if settings.kotak_configured and kotak is not None:
        ok = _try_kotak_connect()
        logger.info(f"Kotak connect on startup: {ok}")
    else:
        logger.warning("Kotak env incomplete — portfolio optional")
    if live_engine is None:
        logger.error("Live engine unavailable")
    else:
        logger.info("Live recommendation engine ready")
    yield


app = FastAPI(
    title="InvestIQ API",
    description="Live multi-factor rankings. Analytical only — never places orders.",
    version="2.5.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET"],
    allow_headers=["*"],
)


class RecommendationResponse(BaseModel):
    symbol: str
    timeframe: str
    action: str
    confidence_score: float
    entry_price: Optional[float] = None
    stop_loss: Optional[float] = None
    target_price: Optional[float] = None
    final_score: float
    factors: dict = Field(default_factory=dict)
    rationale: List[str] = Field(default_factory=list)
    data_source: str = "live"
    disclaimer: str = "Analytical signal only. Does not place any orders."
    generated_at: str


class TopPicksResponse(BaseModel):
    timeframe: str
    count: int
    kotak_connected: bool = False
    engine: str = "live"
    recommendations: List[RecommendationResponse]
    disclaimer: str = "Analytical only. Never places orders."


class IndexItem(BaseModel):
    name: str
    symbol: str
    last: float
    change_pct: float
    bias: str


class IndicesResponse(BaseModel):
    as_of: str
    indices: List[IndexItem]
    note: str = "Live Yahoo-derived where available; else last known."


class HoldingItem(BaseModel):
    symbol: str
    quantity: float = 0
    avg_price: float = 0
    ltp: float = 0
    pnl: float = 0
    pnl_pct: float = 0


class PortfolioSummaryResponse(BaseModel):
    linked: bool
    message: str
    total_value: float = 0
    total_pnl: float = 0
    total_pnl_pct: float = 0
    holdings: List[HoldingItem] = Field(default_factory=list)
    disclaimer: str = "Read-only view. This API never places orders."


class HealthResponse(BaseModel):
    status: str
    message: str
    kotak_configured: bool
    kotak_connected: bool
    kotak_error: Optional[str] = None
    engine: str = "live"
    version: str = "2.5.0"


def _kotak_connected() -> bool:
    return bool(kotak is not None and getattr(kotak, "ready", False))


def _action_from_score(score: float) -> str:
    if score >= 80:
        return "STRONG BUY"
    if score >= 65:
        return "BUY"
    if score <= 35:
        return "SELL"
    return "HOLD"


def _to_rec(live: dict) -> RecommendationResponse:
    score = float(live["final_score"])
    price = float(live["close"])
    atr = float(live.get("atr_14") or price * 0.02)
    action = _action_from_score(score)
    stop = round(price - 2 * atr, 2) if action in ("BUY", "STRONG BUY") else None
    target = round(price + 3 * atr, 2) if action in ("BUY", "STRONG BUY") else None
    conf = round(min(0.95, abs(score - 50) / 40), 3)
    return RecommendationResponse(
        symbol=live["symbol"],
        timeframe=live.get("timeframe", "daily"),
        action=action,
        confidence_score=conf,
        entry_price=price,
        stop_loss=stop,
        target_price=target,
        final_score=score,
        factors=live.get("factors") or {},
        rationale=live.get("rationale") or ["Live multi-factor score"],
        data_source=live.get("data_source", "live"),
        generated_at=datetime.now(timezone.utc).isoformat(),
    )


@app.get("/", response_model=HealthResponse)
async def health():
    connected = _kotak_connected()
    err = getattr(kotak, "last_error", None) if kotak else None
    return HealthResponse(
        status="operational",
        message=(
            "Live engine + Kotak linked."
            if connected
            else "Live engine up. Kotak optional for portfolio."
        ),
        kotak_configured=settings.kotak_configured,
        kotak_connected=connected,
        kotak_error=err,
        engine="live" if live_engine else "unavailable",
    )


@app.get("/api/v1/indices", response_model=IndicesResponse)
async def market_indices():
    items: List[IndexItem] = []
    mapping = [
        ("Nifty 50", "^NSEI", "NIFTY"),
        ("Sensex", "^BSESN", "SENSEX"),
        ("Bank Nifty", "^NSEBANK", "BANKNIFTY"),
        ("India VIX", "^INDIAVIX", "INDIAVIX"),
    ]
    try:
        import yfinance as yf
        for name, ticker, sym in mapping:
            try:
                t = yf.Ticker(ticker)
                hist = t.history(period="5d")
                if hist is None or hist.empty:
                    continue
                last = float(hist["Close"].iloc[-1])
                prev = float(hist["Close"].iloc[-2]) if len(hist) > 1 else last
                chg = ((last - prev) / prev * 100) if prev else 0.0
                bias = "bullish" if chg > 0.15 else ("bearish" if chg < -0.15 else "neutral")
                items.append(IndexItem(name=name, symbol=sym, last=round(last, 2), change_pct=round(chg, 2), bias=bias))
            except Exception:
                continue
    except Exception as e:
        logger.warning(f"indices: {e}")
    if not items:
        items = [IndexItem(name="Nifty 50", symbol="NIFTY", last=0, change_pct=0, bias="neutral")]
    return IndicesResponse(as_of=datetime.now(timezone.utc).isoformat(), indices=items)


@app.get("/api/v1/portfolio/summary", response_model=PortfolioSummaryResponse)
async def portfolio_summary():
    if not _kotak_connected():
        _try_kotak_connect()
    if not _kotak_connected():
        err = getattr(kotak, "last_error", None) if kotak else "client missing"
        return PortfolioSummaryResponse(
            linked=False,
            message=f"Kotak not linked. {err or 'Check env vars.'}",
            holdings=[],
        )
    rows = []
    try:
        rows = kotak.normalized_holdings()
    except Exception as e:
        logger.warning(f"holdings error: {e}")
    holdings = [
        HoldingItem(**{k: r[k] for k in ("symbol", "quantity", "avg_price", "ltp", "pnl", "pnl_pct") if k in r})
        for r in rows
    ]
    total_value = sum(float(r.get("mkt_value") or r["ltp"] * r["quantity"]) for r in rows)
    total_pnl = sum(float(r["pnl"]) for r in rows)
    cost = total_value - total_pnl
    total_pnl_pct = (total_pnl / cost * 100.0) if cost else 0.0
    return PortfolioSummaryResponse(
        linked=True,
        message=f"{len(holdings)} holdings loaded (read-only)." if holdings else "Session linked; no CNC holdings.",
        total_value=round(total_value, 2),
        total_pnl=round(total_pnl, 2),
        total_pnl_pct=round(total_pnl_pct, 2),
        holdings=holdings,
    )


@app.get("/api/v1/recommendations/top", response_model=TopPicksResponse)
async def top_recommendations(
    timeframe: Literal["daily", "monthly", "yearly"] = Query("daily"),
    limit: int = Query(10, ge=1, le=30),
):
    if live_engine is None:
        raise HTTPException(500, "Live engine not loaded")
    symbols = settings.symbols or DEFAULT_UNIVERSE
    ranked = live_engine.rank_universe(symbols=symbols, timeframe=timeframe, limit=limit)
    recs = [_to_rec(r) for r in ranked]
    return TopPicksResponse(
        timeframe=timeframe,
        count=len(recs),
        kotak_connected=_kotak_connected(),
        engine="live",
        recommendations=recs,
    )


@app.get("/api/v1/recommendations/{symbol}", response_model=RecommendationResponse)
async def single_recommendation(
    symbol: str,
    timeframe: Literal["daily", "monthly", "yearly"] = Query("daily"),
):
    if live_engine is None:
        raise HTTPException(500, "Live engine not loaded")
    try:
        live = live_engine.generate_live_signal(symbol, timeframe=timeframe)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Could not compute {symbol}: {e}")
    return _to_rec(live)


@app.post("/api/v1/orders", include_in_schema=False)
@app.put("/api/v1/orders", include_in_schema=False)
@app.delete("/api/v1/orders", include_in_schema=False)
@app.post("/api/v1/trade", include_in_schema=False)
async def reject_trading():
    return JSONResponse(
        status_code=403,
        content={"error": "Forbidden", "message": "Analytical only. No buy/sell/order commands exist."},
    )
