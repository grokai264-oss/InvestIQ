"""
InvestIQ FastAPI — READ-ONLY recommendation API
Never places any orders.
"""
from __future__ import annotations

from typing import List, Optional, Literal
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from datetime import datetime, timezone
import pandas as pd

app = FastAPI(
    title="InvestIQ API",
    description="Analytical stock rankings only. NEVER places buy/sell orders.",
    version="1.0.0",
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
    disclaimer: str = "This is an analytical signal only. It does not place any orders."
    generated_at: str


class TopPicksResponse(BaseModel):
    timeframe: str
    count: int
    recommendations: List[RecommendationResponse]
    disclaimer: str = "Analytical rankings only. This system never places orders."


class HealthResponse(BaseModel):
    status: str
    message: str
    version: str = "1.0.0"


_DEMO = pd.DataFrame([
    {"symbol": "RELIANCE", "timeframe": "daily", "final_score": 78.5, "close": 2950.0, "atr_14": 45.0,
     "score_rsi": 72, "score_ema": 85, "score_rvol": 68, "score_delivery": 74, "score_bulk": 60},
    {"symbol": "TCS", "timeframe": "daily", "final_score": 71.2, "close": 3850.0, "atr_14": 55.0,
     "score_rsi": 65, "score_ema": 78, "score_rvol": 55, "score_delivery": 62, "score_bulk": 58},
    {"symbol": "INFY", "timeframe": "daily", "final_score": 54.0, "close": 1520.0, "atr_14": 22.0,
     "score_rsi": 48, "score_ema": 52, "score_rvol": 40, "score_delivery": 45, "score_bulk": 50},
    {"symbol": "HDFCBANK", "timeframe": "daily", "final_score": 82.1, "close": 1680.0, "atr_14": 28.0,
     "score_rsi": 70, "score_ema": 88, "score_rvol": 75, "score_delivery": 80, "score_bulk": 72},
    {"symbol": "SBIN", "timeframe": "daily", "final_score": 33.5, "close": 780.0, "atr_14": 15.0,
     "score_rsi": 28, "score_ema": 25, "score_rvol": 30, "score_delivery": 35, "score_bulk": 40},
])


def _to_rec(row) -> RecommendationResponse:
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
        rationale.append("Elevated delivery percentage — possible institutional accumulation")
    if factors.get("score_rsi", 0) >= 70:
        rationale.append("RSI in healthy momentum zone")
    if factors.get("score_ema", 0) >= 70:
        rationale.append("Price holding above 20-EMA")
    if not rationale:
        rationale.append("Composite score based on multiple factors")
    return RecommendationResponse(
        symbol=str(row["symbol"]),
        timeframe=str(row.get("timeframe", "daily")),
        action=action,
        confidence_score=round(min(0.95, abs(score - 50) / 40), 3),
        entry_price=price,
        stop_loss=stop,
        target_price=target,
        final_score=score,
        factors=factors,
        rationale=rationale,
        generated_at=datetime.now(timezone.utc).isoformat(),
    )


@app.get("/", response_model=HealthResponse)
async def health():
    return HealthResponse(
        status="operational",
        message="InvestIQ recommendation engine. No trading capability.",
    )


@app.get("/api/v1/recommendations/top", response_model=TopPicksResponse)
async def top_recommendations(
    timeframe: Literal["daily", "monthly", "yearly"] = Query("daily"),
    limit: int = Query(10, ge=1, le=50),
):
    df = _DEMO.copy()
    df = df.sort_values("final_score", ascending=False).head(limit)
    recs = [_to_rec(row) for _, row in df.iterrows()]
    return TopPicksResponse(timeframe=timeframe, count=len(recs), recommendations=recs)


@app.get("/api/v1/recommendations/{symbol}", response_model=RecommendationResponse)
async def single_recommendation(
    symbol: str,
    timeframe: Literal["daily", "monthly", "yearly"] = Query("daily"),
):
    match = _DEMO[_DEMO["symbol"] == symbol.upper()]
    if match.empty:
        raise HTTPException(status_code=404, detail=f"No data for {symbol}")
    return _to_rec(match.iloc[0])


@app.post("/api/v1/orders", include_in_schema=False)
@app.put("/api/v1/orders", include_in_schema=False)
@app.delete("/api/v1/orders", include_in_schema=False)
async def reject_trading():
    return JSONResponse(
        status_code=403,
        content={
            "error": "Forbidden",
            "message": "This API is analytical only. It does not accept or execute any buy/sell/order commands.",
        },
    )
