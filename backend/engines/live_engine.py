"""Live multi-factor recommendation engine."""
from __future__ import annotations

from typing import Any, Dict, List, Optional
from loguru import logger

from .data_fetcher import LiveDataFetcher
from .technical import TechnicalEngine
from .scoring import ScoringEngine
from .nse_fetcher import NSEFetcher

WEIGHTS = {
    "daily": {"rsi": 0.25, "ema": 0.20, "rvol": 0.25, "macd": 0.10, "delivery": 0.12, "fii": 0.08},
    "monthly": {"rsi": 0.20, "ema": 0.30, "rvol": 0.15, "macd": 0.15, "delivery": 0.12, "fii": 0.08},
    "yearly": {"rsi": 0.15, "ema": 0.35, "rvol": 0.10, "macd": 0.15, "delivery": 0.15, "fii": 0.10},
}

DEFAULT_UNIVERSE = [
    "RELIANCE", "TCS", "INFY", "HDFCBANK", "ICICIBANK",
    "SBIN", "BHARTIARTL", "ITC", "KOTAKBANK", "LT", "BEL",
]


class LiveRecommendationEngine:
    def __init__(self):
        self.nse = NSEFetcher()

    def generate_live_signal(self, symbol: str, timeframe: str = "daily") -> Dict[str, Any]:
        symbol = symbol.upper().replace(".NS", "")
        tf = timeframe if timeframe in WEIGHTS else "daily"
        w = WEIGHTS[tf]

        df = LiveDataFetcher.fetch_daily_ohlcv(symbol, days=90)
        tech = TechnicalEngine.compute_factors(df)
        row = tech.iloc[-1]

        rsi = float(row["rsi"])
        ema_dist = float(row["ema_distance_pct"])
        rvol = float(row["rvol"])
        atr = float(row["atr"])
        close = float(row["close"])
        macd_h = float(row.get("macd_hist", 0) or 0)

        delivery = self.nse.fetch_delivery_data(symbol)
        flow = self.nse.fetch_fii_dii_data()
        fii_net = float(flow.get("fii_net_cr", 0) or 0)

        score_rsi = ScoringEngine.normalize_rsi(rsi)
        score_ema = ScoringEngine.normalize_ema_distance(ema_dist)
        score_rvol = ScoringEngine.normalize_rvol(rvol)
        score_macd = ScoringEngine.normalize_macd_hist(macd_h)
        score_delivery = ScoringEngine.normalize_delivery(delivery)
        score_fii = ScoringEngine.normalize_fii(fii_net)

        final = (
            score_rsi * w["rsi"]
            + score_ema * w["ema"]
            + score_rvol * w["rvol"]
            + score_macd * w["macd"]
            + score_delivery * w["delivery"]
            + score_fii * w["fii"]
        )

        rationale: List[str] = []
        if score_delivery >= 70:
            rationale.append(f"Delivery {delivery:.1f}% — institutional interest")
        if score_rsi >= 70:
            rationale.append(f"RSI {rsi:.1f} in momentum zone")
        if score_ema >= 70:
            rationale.append(f"Price {ema_dist:+.1f}% vs 20-EMA")
        if score_rvol >= 70:
            rationale.append(f"Relative volume {rvol:.2f}x")
        if fii_net > 0:
            rationale.append(f"FII net +₹{fii_net:.0f} Cr")
        elif fii_net < 0:
            rationale.append(f"FII net ₹{fii_net:.0f} Cr")
        if not rationale:
            rationale.append("Composite multi-factor live score")

        return {
            "symbol": symbol,
            "timeframe": tf,
            "final_score": round(float(final), 2),
            "close": round(close, 2),
            "atr_14": round(atr, 2),
            "factors": {
                "score_rsi": round(score_rsi, 1),
                "score_ema": round(score_ema, 1),
                "score_rvol": round(score_rvol, 1),
                "score_macd": round(score_macd, 1),
                "score_delivery": round(score_delivery, 1),
                "score_fii": round(score_fii, 1),
            },
            "raw": {
                "rsi": round(rsi, 2),
                "ema_distance_pct": round(ema_dist, 2),
                "rvol": round(rvol, 2),
                "delivery_pct": round(delivery, 2),
                "fii_net_cr": fii_net,
            },
            "rationale": rationale,
            "data_source": "live",
        }

    def rank_universe(
        self,
        symbols: Optional[List[str]] = None,
        timeframe: str = "daily",
        limit: int = 10,
    ) -> List[Dict[str, Any]]:
        symbols = symbols or DEFAULT_UNIVERSE
        results: List[Dict[str, Any]] = []
        for sym in symbols:
            try:
                results.append(self.generate_live_signal(sym, timeframe=timeframe))
            except Exception as e:
                logger.warning(f"live signal failed for {sym}: {e}")
        results.sort(key=lambda x: x.get("final_score", 0), reverse=True)
        return results[:limit]


live_engine = LiveRecommendationEngine()
