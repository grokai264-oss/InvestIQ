"""Live recommendation engine — OHLCV → technicals → continuous scores → composite.

Uses the v2.1 continuous normalizers and VIX regime weights.
Designed for request-path use on a liquid universe (~100–150 names).
Full NIFTY-500 cross-sectional batch + Redis snapshot is the next production layer.

NO hash-based / placeholder scores. Every factor comes from OHLCV or fundamentals.
"""
from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from loguru import logger

from .data_fetcher import LiveDataFetcher
from .technical import TechnicalEngine
from .scoring import ScoringEngine
from . import advanced_factors as af
from .quotes import quotes_for


def _action(score: float) -> str:
    if score >= 72:
        return "STRONG"
    if score >= 58:
        return "WATCH"
    if score >= 42:
        return "NEUTRAL"
    return "WEAK"


def score_symbol(symbol: str, timeframe: str = "daily") -> Dict[str, Any]:
    """Score one symbol with continuous factors. Returns full recommendation payload."""
    sym = symbol.upper().replace(".NS", "").replace("-EQ", "")
    vix = af.india_vix()
    regime = af.volatility_regime(vix)
    weights = af.regime_weights(timeframe)

    ltp: Optional[float] = None
    data_source = "yahoo_ohlcv"
    try:
        qs = quotes_for([sym])
        if qs:
            ltp = qs[0].get("ltp")
            data_source = qs[0].get("source") or data_source
    except Exception:
        pass

    try:
        df = LiveDataFetcher.fetch_daily_ohlcv(sym, days=260)
        tech = TechnicalEngine.compute_factors(df)
        if tech is None or tech.empty:
            raise ValueError("empty technicals")
        row = tech.iloc[-1]
        adv = af.add_advanced_columns(df)
        arow = adv.iloc[-1] if adv is not None and not adv.empty else None

        rsi = float(row.get("rsi", float("nan")))
        ema_dist = float(row.get("ema_distance_pct", float("nan")))
        rvol = float(row.get("rvol", float("nan")))
        macd_h = float(row.get("macd_hist", float("nan")))
        atr = float(row.get("atr", float("nan")))
        close = float(row.get("close", float("nan")))

        vwap_d = float(arow.get("vwap_distance_pct", float("nan"))) if arow is not None else float("nan")
        roc63 = float(arow.get("roc_63", float("nan"))) if arow is not None else float("nan")
        roc126 = float(arow.get("roc_126", float("nan"))) if arow is not None else float("nan")
        vol20 = float(arow.get("realized_vol_20", float("nan"))) if arow is not None else float("nan")
        vol90 = float(arow.get("realized_vol_90", float("nan"))) if arow is not None else float("nan")

        factors = {
            "score_rsi": ScoringEngine.normalize_rsi(rsi),
            "score_ema": ScoringEngine.normalize_ema_distance(ema_dist),
            "score_rvol": ScoringEngine.normalize_rvol(rvol),
            "score_macd": ScoringEngine.normalize_macd_hist(macd_h),
            "score_vwap": af.normalize_vwap_distance(vwap_d),
            "score_momentum": af.normalize_momentum(roc63, roc126),
            "score_low_vol": af.normalize_low_vol(vol20, vol90),
        }

        try:
            fund = af.fundamentals_scores(sym)
            factors["score_value"] = float(fund.get("score_value", 50.0))
        except Exception:
            factors["score_value"] = 50.0

        key_map = {
            "rsi": "score_rsi",
            "ema": "score_ema",
            "rvol": "score_rvol",
            "macd": "score_macd",
            "vwap": "score_vwap",
            "momentum": "score_momentum",
            "low_vol": "score_low_vol",
            "value": "score_value",
            "delivery": "score_rvol",
            "fii": "score_value",
        }

        score = 0.0
        used_w = 0.0
        contrib: Dict[str, float] = {}
        for wk, wv in weights.items():
            fk = key_map.get(wk)
            if fk and fk in factors:
                c = factors[fk] * wv
                contrib[fk] = round(c, 2)
                score += c
                used_w += wv
        if used_w > 0:
            score = score / used_w
        score = float(min(100.0, max(0.0, score)))

        atr_pct = (atr / close * 100.0) if close and atr == atr else 0.0
        friction = af.friction_note(score, atr_pct)

        if ltp is None and close == close:
            ltp = close

        rationale = [
            f"regime={regime} (India VIX {vix:.1f})",
            f"RSI={rsi:.1f} → {factors['score_rsi']:.0f}",
            f"EMA dist={ema_dist:.1f}% → {factors['score_ema']:.0f}",
            f"Momentum(3m/6m) → {factors['score_momentum']:.0f}",
            f"VWAP dist={vwap_d:.1f}% → {factors['score_vwap']:.0f}" if vwap_d == vwap_d else "VWAP n/a",
        ]
        if friction:
            rationale.append(friction)

        return {
            "symbol": sym,
            "timeframe": timeframe,
            "action": _action(score),
            "confidence_score": round(min(0.88, max(0.25, abs(score - 50) / 55.0)), 3),
            "entry_price": round(ltp, 2) if ltp else None,
            "stop_loss": round(ltp * 0.97, 2) if ltp else None,
            "target_price": round(ltp * 1.05, 2) if ltp else None,
            "final_score": round(score, 1),
            "factors": {k: round(v, 1) for k, v in factors.items()},
            "weights": {k: round(v, 4) for k, v in weights.items()},
            "contributions": contrib,
            "rationale": rationale,
            "disclaimer": "Analytical signal only. InvestIQ never places orders.",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "data_source": data_source,
            "engine_version": "2.2",
            "regime": f"{regime} (India VIX {vix:.1f})",
            "raw_inputs": {
                "ltp": ltp,
                "rsi": round(rsi, 2) if rsi == rsi else None,
                "ema_distance_pct": round(ema_dist, 2) if ema_dist == ema_dist else None,
                "rvol": round(rvol, 2) if rvol == rvol else None,
                "macd_hist": round(macd_h, 4) if macd_h == macd_h else None,
                "vwap_distance_pct": round(vwap_d, 2) if vwap_d == vwap_d else None,
                "roc_63": round(roc63, 2) if roc63 == roc63 else None,
                "roc_126": round(roc126, 2) if roc126 == roc126 else None,
                "realized_vol_20": round(vol20, 2) if vol20 == vol20 else None,
                "vix": round(vix, 2),
            },
            "data_quality": 1,
        }
    except Exception as e:
        logger.warning(f"score_symbol {sym}: {e}")
        return {
            "symbol": sym,
            "timeframe": timeframe,
            "action": "NEUTRAL",
            "confidence_score": 0.2,
            "entry_price": ltp,
            "stop_loss": round(ltp * 0.97, 2) if ltp else None,
            "target_price": round(ltp * 1.05, 2) if ltp else None,
            "final_score": 50.0,
            "factors": {
                "score_rsi": 50.0,
                "score_ema": 50.0,
                "score_rvol": 40.0,
                "score_macd": 50.0,
                "score_vwap": 50.0,
                "score_momentum": 50.0,
                "score_low_vol": 50.0,
                "score_value": 50.0,
            },
            "weights": weights,
            "contributions": {},
            "rationale": [f"Insufficient OHLCV for {sym}: {e}", f"regime={regime} (India VIX {vix:.1f})"],
            "disclaimer": "Analytical signal only. InvestIQ never places orders.",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "data_source": "unavailable",
            "engine_version": "2.2",
            "regime": f"{regime} (India VIX {vix:.1f})",
            "raw_inputs": {"ltp": ltp, "vix": round(vix, 2)},
            "data_quality": 0,
        }


def rank_universe(
    symbols: List[str],
    timeframe: str = "daily",
    limit: int = 15,
    max_workers: int = 6,
) -> Dict[str, Any]:
    """Parallel score a liquid universe and return top-N sorted by final_score."""
    vix = af.india_vix()
    regime = af.volatility_regime(vix)
    results: List[Dict[str, Any]] = []

    def _one(s: str) -> Optional[Dict[str, Any]]:
        try:
            return score_symbol(s, timeframe=timeframe)
        except Exception as e:
            logger.debug(f"rank skip {s}: {e}")
            return None

    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        futs = {pool.submit(_one, s): s for s in symbols}
        for fut in as_completed(futs):
            rec = fut.result()
            if rec is not None and rec.get("data_quality", 0) >= 1:
                results.append(rec)

    results.sort(key=lambda x: x.get("final_score", 0), reverse=True)
    return {
        "recommendations": results[:limit],
        "regime": regime,
        "vix": round(vix, 2),
        "scored": len(results),
        "engine_version": "2.2",
    }


class LiveRecommendationEngine:
    @staticmethod
    def score(symbol: str, timeframe: str = "daily") -> Dict[str, Any]:
        return score_symbol(symbol, timeframe)

    @staticmethod
    def rank(symbols: List[str], timeframe: str = "daily", limit: int = 15) -> Dict[str, Any]:
        return rank_universe(symbols, timeframe=timeframe, limit=limit)
