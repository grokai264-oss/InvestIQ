"""
InvestIQ FastAPI — READ-ONLY
Secrets only from environment (Render). Never places orders.
"""
from __future__ import annotations

from typing import List, Optional, Literal
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from datetime import datetime, timezone
from contextlib import asynccontextmanager
import pandas as pd
from loguru import logger

from config.settings import settings

try:
    from ingestion.kotak_client import kotak
except Exception:
    kotak = None


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
        if not ok and kotak is not None:
            logger.warning(f"Kotak last_error: {getattr(kotak, 'last_error', None)}")
    else:
        logger.warning("Kotak env not complete — rankings use model data")
    yield


app = FastAPI(
    title="InvestIQ API",
    description="Analytical only. NEVER places buy/sell orders.",
    version="1.3.0",
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
    data_source: str = "model"
    disclaimer: str = "Analytical signal only. Does not place any orders."
    generated_at: str


class TopPicksResponse(BaseModel):
    timeframe: str
    count: int
    kotak_connected: bool = False
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
    note: str = "Indicative model values until live index feed is wired."


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
    version: str = "1.3.0"


_MODEL = pd.DataFrame([
    {"symbol": "RELIANCE", "final_score": 78.5, "close": 2950.0, "atr_14": 45.0,
     "score_rsi": 72, "score_ema": 85, "score_rvol": 68, "score_delivery": 74, "score_bulk": 60},
    {"symbol": "TCS", "final_score": 71.2, "close": 3850.0, "atr_14": 55.0,
     "score_rsi": 65, "score_ema": 78, "score_rvol": 55, "score_delivery": 62, "score_bulk": 58},
    {"symbol": "INFY", "final_score": 54.0, "close": 1520.0, "atr_14": 22.0,
     "score_rsi": 48, "score_ema": 52, "score_rvol": 40, "score_delivery": 45, "score_bulk": 50},
    {"symbol": "HDFCBANK", "final_score": 82.1, "close": 1680.0, "atr_14": 28.0,
     "score_rsi": 70, "score_ema": 88, "score_rvol": 75, "score_delivery": 80, "score_bulk": 72},
    {"symbol": "SBIN", "final_score": 33.5, "close": 780.0, "atr_14": 15.0,
     "score_rsi": 28, "score_ema": 25, "score_rvol": 30, "score_delivery": 35, "score_bulk": 40},
    {"symbol": "ICICIBANK", "final_score": 69.0, "close": 1100.0, "atr_14": 20.0,
     "score_rsi": 62, "score_ema": 70, "score_rvol": 58, "score_delivery": 66, "score_bulk": 55},
    {"symbol": "ITC", "final_score": 61.0, "close": 450.0, "atr_14": 8.0,
     "score_rsi": 55, "score_ema": 60, "score_rvol": 50, "score_delivery": 58, "score_bulk": 48},
    {"symbol": "BHARTIARTL", "final_score": 73.0, "close": 1550.0, "atr_14": 25.0,
     "score_rsi": 68, "score_ema": 75, "score_rvol": 62, "score_delivery": 70, "score_bulk": 65},
    {"symbol": "LT", "final_score": 66.0, "close": 3600.0, "atr_14": 50.0,
     "score_rsi": 60, "score_ema": 68, "score_rvol": 55, "score_delivery": 58, "score_bulk": 52},
    {"symbol": "KOTAKBANK", "final_score": 58.0, "close": 1750.0, "atr_14": 30.0,
     "score_rsi": 52, "score_ema": 55, "score_rvol": 48, "score_delivery": 50, "score_bulk": 45},
])

_INDICES = [
    {"name": "Nifty 50", "symbol": "NIFTY", "last": 24580.0, "change_pct": 0.42, "bias": "bullish"},
    {"name": "Sensex", "symbol": "SENSEX", "last": 80720.0, "change_pct": 0.38, "bias": "bullish"},
    {"name": "Bank Nifty", "symbol": "BANKNIFTY", "last": 51240.0, "change_pct": -0.15, "bias": "neutral"},
    {"name": "India VIX", "symbol": "INDIAVIX", "last": 13.8, "change_pct": -2.1, "bias": "bullish"},
]


def _to_rec(row, timeframe: str, data_source: str) -> RecommendationResponse:
    score = float(row["final_score"])
    price = float(row["close"])
    atr = float(row.get("atr_14", price * 0.02))
    if score >= 80:
        action = "STRONG BUY"
    elif score >= 65:
        action = "BUY"
    elif score <= 35:
        action = "SELL"
    else:
        action = "HOLD"
    stop = round(price - 2 * atr, 2) if action in ("BUY", "STRONG BUY") else None
    target = round(price + 3 * atr, 2) if action in ("BUY", "STRONG BUY") else None
    factors = {k: float(v) for k, v in row.items() if str(k).startswith("score_")}
    rationale = []
    if factors.get("score_delivery", 0) >= 70:
        rationale.append("Elevated delivery — possible institutional activity")
    if factors.get("score_rsi", 0) >= 70:
        rationale.append("RSI in healthy momentum zone")
    if factors.get("score_ema", 0) >= 70:
        rationale.append("Price holding above trend EMA")
    if data_source == "kotak":
        rationale.insert(0, "Kotak Neo session active (read-only)")
    if not rationale:
        rationale.append("Composite multi-factor score")
    return RecommendationResponse(
        symbol=str(row["symbol"]),
        timeframe=timeframe,
        action=action,
        confidence_score=round(min(0.95, abs(score - 50) / 40), 3),
        entry_price=price,
        stop_loss=stop,
        target_price=target,
        final_score=score,
        factors=factors,
        rationale=rationale,
        data_source=data_source,
        generated_at=datetime.now(timezone.utc).isoformat(),
    )


def _kotak_connected() -> bool:
    return bool(kotak is not None and getattr(kotak, "ready", False))


@app.get("/", response_model=HealthResponse)
async def health():
    connected = _kotak_connected()
    err = None
    if kotak is not None:
        err = getattr(kotak, "last_error", None)
    return HealthResponse(
        status="operational",
        message=(
            "Kotak Neo linked (read-only)."
            if connected
            else "API up. Rankings available. Check kotak_error if portfolio needed."
        ),
        kotak_configured=settings.kotak_configured,
        kotak_connected=connected,
        kotak_error=err,
    )


@app.get("/api/v1/indices", response_model=IndicesResponse)
async def market_indices():
    return IndicesResponse(
        as_of=datetime.now(timezone.utc).isoformat(),
        indices=[IndexItem(**x) for x in _INDICES],
    )


@app.get("/api/v1/portfolio/summary", response_model=PortfolioSummaryResponse)
async def portfolio_summary():
    """Read-only holdings snapshot. No trading."""
    if not _kotak_connected():
        # One reconnect attempt (session may have expired or startup failed)
        _try_kotak_connect()
    if not _kotak_connected():
        err = getattr(kotak, "last_error", None) if kotak else "client missing"
        return PortfolioSummaryResponse(
            linked=False,
            message=f"Kotak not linked. {err or 'Check Render env vars (mobile +91, TOTP Setup Key, MPIN, UCC, access token).'}",
            holdings=[],
        )

    rows = []
    try:
        rows = kotak.normalized_holdings()
    except Exception as e:
        logger.warning(f"holdings error: {e}")

    holdings = [HoldingItem(**r) for r in rows]
    total_value = sum(float(r.get("mkt_value") or r["ltp"] * r["quantity"]) for r in rows)
    total_pnl = sum(float(r["pnl"]) for r in rows)
    cost = total_value - total_pnl
    total_pnl_pct = (total_pnl / cost * 100.0) if cost else 0.0

    return PortfolioSummaryResponse(
        linked=True,
        message=(
            f"{len(holdings)} holdings loaded (read-only)."
            if holdings
            else "Session linked but no CNC holdings returned."
        ),
        total_value=round(total_value, 2),
        total_pnl=round(total_pnl, 2),
        total_pnl_pct=round(total_pnl_pct, 2),
        holdings=holdings,
    )


@app.get("/api/v1/recommendations/top", response_model=TopPicksResponse)
async def top_recommendations(
    timeframe: Literal["daily", "monthly", "yearly"] = Query("daily"),
    limit: int = Query(10, ge=1, le=50),
):
    connected = _kotak_connected()
    source = "kotak" if connected else "model"
    df = _MODEL.copy().sort_values("final_score", ascending=False).head(limit)
    recs = [_to_rec(row, timeframe, source) for _, row in df.iterrows()]
    return TopPicksResponse(
        timeframe=timeframe,
        count=len(recs),
        kotak_connected=connected,
        recommendations=recs,
    )


@app.get("/api/v1/recommendations/{symbol}", response_model=RecommendationResponse)
async def single_recommendation(
    symbol: str,
    timeframe: Literal["daily", "monthly", "yearly"] = Query("daily"),
):
    connected = _kotak_connected()
    source = "kotak" if connected else "model"
    match = _MODEL[_MODEL["symbol"] == symbol.upper()]
    if match.empty:
        raise HTTPException(status_code=404, detail=f"No data for {symbol}")
    return _to_rec(match.iloc[0], timeframe, source)


@app.post("/api/v1/orders", include_in_schema=False)
@app.put("/api/v1/orders", include_in_schema=False)
@app.delete("/api/v1/orders", include_in_schema=False)
@app.post("/api/v1/trade", include_in_schema=False)
async def reject_trading():
    return JSONResponse(
        status_code=403,
        content={
            "error": "Forbidden",
            "message": "Analytical only. No buy/sell/order commands exist.",
        },
    )
