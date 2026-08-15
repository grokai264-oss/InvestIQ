"""Live multi-factor engine v2.5 — regime weights, VWAP, momentum, parallel rank."""
from __future__ import annotations

import math
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any, Dict, List, Optional
from loguru import logger

from .data_fetcher import LiveDataFetcher
from .technical import TechnicalEngine
from .scoring import ScoringEngine
from .nse_fetcher import NSEFetcher
from .advanced_factors import (
    add_advanced_columns,
    regime_weights,
    volatility_regime,
    india_vix,
    normalize_vwap_distance,
    normalize_momentum,
    normalize_low_vol,
    fundamentals_scores,
    friction_note,
)

DEFAULT_UNIVERSE = [
    "RELIANCE", "TCS", "INFY", "HDFCBANK", "ICICIBANK",
    "SBIN", "BHARTIARTL", "ITC", "KOTAKBANK", "LT", "BEL",
]


def _f(x, default=0.0):
    try:
        v = float(x)
        return default if math.isnan(v) else v
    except Exception:
        return default


class LiveRecommendationEngine:
    def __init__(self):
        self.nse = NSEFetcher()

    def generate_live_signal(self, symbol: str, timeframe: str = "daily") -> Dict[str, Any]:
        symbol = symbol.upper().replace(".NS", "")
        tf = timeframe if timeframe in ("daily", "monthly", "yearly") else "daily"
        w = regime_weights(tf)
        vix = india_vix()
        regime = volatility_regime(vix)

        df = LiveDataFetcher.fetch_daily_ohlcv(symbol, days=200)
        tech = TechnicalEngine.compute_factors(df)
        tech = add_advanced_columns(tech)
        row = tech.iloc[-1]

        rsi = float(row["rsi"])
        ema_dist = float(row["ema_distance_pct"])
        rvol = float(row["rvol"])
        atr = float(row["atr"])
        close = float(row["close"])
        macd_h = float(row.get("macd_hist", 0) or 0)
        vwap_dist = float(row.get("vwap_distance_pct", 0) or 0)
        roc_63 = _f(row.get("roc_63"), 0.0)
        roc_126 = _f(row.get("roc_126"), 0.0)
        vol20 = _f(row.get("realized_vol_20"), float("nan"))
        vol90 = _f(row.get("realized_vol_90"), float("nan"))

        delivery = self.nse.fetch_delivery_data(symbol)
        flow = self.nse.fetch_fii_dii_data()
        fii_net = float(flow.get("fii_net_cr", 0) or 0)
        fund = fundamentals_scores(symbol)

        score_rsi = ScoringEngine.normalize_rsi(rsi)
        score_ema = ScoringEngine.normalize_ema_distance(ema_dist)
        score_rvol = ScoringEngine.normalize_rvol(rvol)
        score_macd = ScoringEngine.normalize_macd_hist(macd_h)
        score_delivery = ScoringEngine.normalize_delivery(delivery)
        score_fii = ScoringEngine.normalize_fii(fii_net)
        score_vwap = normalize_vwap_distance(vwap_dist)
        score_mom = normalize_momentum(roc_63, roc_126)
        score_lvol = normalize_low_vol(vol20, vol90)
        score_value = float(fund.get("score_value", 50.0))

        final = (
            score_rsi * w.get("rsi", 0)
            + score_ema * w.get("ema", 0)
            + score_rvol * w.get("rvol", 0)
            + score_macd * w.get("macd", 0)
            + score_vwap * w.get("vwap", 0)
            + score_mom * w.get("momentum", 0)
            + score_lvol * w.get("low_vol", 0)
            + score_delivery * w.get("delivery", 0)
            + score_fii * w.get("fii", 0)
            + score_value * w.get("value", 0)
        )

        rationale: List[str] = [f"Regime={regime} (India VIX {vix:.1f})"]
        if score_vwap >= 70:
            rationale.append(f"Near/above VWAP ({vwap_dist:+.1f}%)")
        if score_mom >= 70:
            rationale.append(f"Momentum 3m/6m ROC {roc_63:.1f}% / {roc_126:.1f}%")
        if score_rsi >= 70:
            rationale.append(f"RSI {rsi:.1f} momentum zone")
        if score_ema >= 70:
            rationale.append(f"Price {ema_dist:+.1f}% vs 20-EMA")
        if score_rvol >= 70:
            rationale.append(f"RVOL {rvol:.2f}x")
        if score_delivery >= 70:
            rationale.append(f"Delivery {delivery:.1f}%")
        if fii_net > 0:
            rationale.append(f"FII net +Rs {fii_net:.0f} Cr")
        elif fii_net < 0:
            rationale.append(f"FII net Rs {fii_net:.0f} Cr")
        if score_lvol >= 75 and regime == "high":
            rationale.append(f"Low realized vol {vol20:.0f}% defensive")
        if score_value >= 80:
            rationale.append("Value/quality proxy constructive")

        atr_pct = (atr / close * 100) if close else 0
        note = friction_note(final, atr_pct)
        if note:
            rationale.append(note)

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
                "score_vwap": round(score_vwap, 1),
                "score_momentum": round(score_mom, 1),
                "score_low_vol": round(score_lvol, 1),
                "score_delivery": round(score_delivery, 1),
                "score_fii": round(score_fii, 1),
                "score_value": round(score_value, 1),
            },
            "raw": {
                "rsi": round(rsi, 2),
                "ema_distance_pct": round(ema_dist, 2),
                "vwap_distance_pct": round(vwap_dist, 2),
                "rvol": round(rvol, 2),
                "roc_63": round(roc_63, 2),
                "roc_126": round(roc_126, 2),
                "realized_vol_20": None if math.isnan(vol20) else round(vol20, 2),
                "delivery_pct": round(delivery, 2),
                "fii_net_cr": fii_net,
                "india_vix": round(vix, 2),
                "regime": regime,
                "pe": fund.get("pe"),
            },
            "rationale": rationale,
            "data_source": "live",
            "engine_version": "2.5.0",
        }

    def rank_universe(
        self,
        symbols: Optional[List[str]] = None,
        timeframe: str = "daily",
        limit: int = 10,
    ) -> List[Dict[str, Any]]:
        symbols = symbols or DEFAULT_UNIVERSE
        results: List[Dict[str, Any]] = []

        def _one(sym: str):
            return self.generate_live_signal(sym, timeframe=timeframe)

        with ThreadPoolExecutor(max_workers=6) as pool:
            futs = {pool.submit(_one, s): s for s in symbols}
            for fut in as_completed(futs):
                sym = futs[fut]
                try:
                    results.append(fut.result())
                except Exception as e:
                    logger.warning(f"live signal failed for {sym}: {e}")

        results.sort(key=lambda x: x.get("final_score", 0), reverse=True)
        return results[:limit]


live_engine = LiveRecommendationEngine()
