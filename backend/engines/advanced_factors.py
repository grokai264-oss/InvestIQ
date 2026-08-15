"""Institutional-inspired factors computable from OHLCV + light fundamentals.

Implemented (no paid Level-2 required):
- Session VWAP distance (volume-weighted fair value proxy)
- Momentum ROC (63d ~ 3m, 126d ~ 6m)
- Realized volatility (20d / 90d) → low-vol score
- India VIX regime classifier
- Simple quality/value proxies from yfinance fundamentals when available
"""
from __future__ import annotations

from typing import Any, Dict, Optional, Tuple
import numpy as np
import pandas as pd
from loguru import logger

try:
    import yfinance as yf
except ImportException:
    yf = None

_vix_cache: Tuple[float, float] = (0.0, 0.0)
_fund_cache: Dict[str, Tuple[float, dict]] = {}


def india_vix() -> float:
    import time
    global _vix_cache
    ts, val = _vix_cache
    if time.time() - ts < 1800 and val > 0:
        return val
    if yf is None:
        return 15.0
    try:
        hist = yf.Ticker("^INDIAVIX").history(period="10d")
        if hist is None or hist.empty:
            return val or 15.0
        v = float(hist["Close"].iloc[-1])
        _vix_cache = (time.time(), v)
        return v
    except Exception as e:
        logger.debug(f"VIX fetch: {e}")
        return val or 15.0


def volatility_regime(vix: Optional[float] = None) -> str:
    v = india_vix() if vix is None else vix
    if v < 15:
        return "low"
    if v > 22:
        return "high"
    return "mid"


def regime_weights(timeframe: str = "daily") -> Dict[str, float]:
    regime = volatility_regime()
    base = {
        "daily": {
            "rsi": 0.18, "ema": 0.12, "rvol": 0.15, "macd": 0.08,
            "vwap": 0.15, "momentum": 0.12, "low_vol": 0.05,
            "delivery": 0.08, "fii": 0.05, "value": 0.02,
        },
        "monthly": {
            "rsi": 0.12, "ema": 0.15, "rvol": 0.10, "macd": 0.08,
            "vwap": 0.12, "momentum": 0.18, "low_vol": 0.08,
            "delivery": 0.08, "fii": 0.05, "value": 0.04,
        },
        "yearly": {
            "rsi": 0.08, "ema": 0.15, "rvol": 0.05, "macd": 0.07,
            "vwap": 0.10, "momentum": 0.20, "low_vol": 0.12,
            "delivery": 0.08, "fii": 0.05, "value": 0.10,
        },
    }
    w = dict(base.get(timeframe, base["daily"]))
    if regime == "low":
        w["momentum"] = w.get("momentum", 0.1) + 0.08
        w["rvol"] = w.get("rvol", 0.1) + 0.05
        w["rsi"] = w.get("rsi", 0.1) + 0.03
        w["low_vol"] = max(0.02, w.get("low_vol", 0.05) - 0.04)
        w["value"] = max(0.01, w.get("value", 0.02) - 0.01)
    elif regime == "high":
        w["low_vol"] = w.get("low_vol", 0.05) + 0.10
        w["vwap"] = w.get("vwap", 0.1) + 0.05
        w["value"] = w.get("value", 0.02) + 0.05
        w["momentum"] = max(0.03, w.get("momentum", 0.1) - 0.08)
        w["rvol"] = max(0.03, w.get("rvol", 0.1) - 0.05)
    s = sum(w.values()) or 1.0
    return {k: v / s for k, v in w.items()}


def add_advanced_columns(df: pd.DataFrame) -> pd.DataFrame:
    d = df.copy()
    close = d["close"].astype(float)
    high = d["high"].astype(float)
    low = d["low"].astype(float)
    vol = d["volume"].astype(float).clip(lower=0)
    typical = (high + low + close) / 3.0
    cum_tp_vol = (typical * vol).cumsum()
    cum_vol = vol.cumsum().replace(0, np.nan)
    d["vwap"] = cum_tp_vol / cum_vol
    d["vwap_distance_pct"] = ((close - d["vwap"]) / d["vwap"]) * 100
    d["roc_63"] = close.pct_change(63) * 100
    d["roc_126"] = close.pct_change(126) * 100
    rets = close.pct_change()
    d["realized_vol_20"] = rets.rolling(20).std() * np.sqrt(252) * 100
    d["realized_vol_90"] = rets.rolling(90).std() * np.sqrt(252) * 100
    return d


def normalize_vwap_distance(dist_pct: float) -> float:
    if dist_pct is None or (isinstance(dist_pct, float) and np.isnan(dist_pct)):
        return 50.0
    if 0 <= dist_pct <= 3:
        return 100.0
    if 3 < dist_pct <= 6:
        return 70.0
    if dist_pct > 6:
        return 35.0
    if -2 <= dist_pct < 0:
        return 55.0
    return 25.0


def normalize_momentum(roc_63: float, roc_126: float) -> float:
    scores = []
    for roc in (roc_63, roc_126):
        if roc is None or (isinstance(roc, float) and np.isnan(roc)):
            scores.append(50.0)
            continue
        if roc >= 15:
            scores.append(100.0)
        elif roc >= 5:
            scores.append(80.0)
        elif roc >= 0:
            scores.append(60.0)
        elif roc >= -5:
            scores.append(40.0)
        else:
            scores.append(15.0)
    return float(0.6 * scores[0] + 0.4 * scores[1])


def normalize_low_vol(vol_20: float, vol_90: float) -> float:
    v = vol_20 if vol_20 and not (isinstance(vol_20, float) and np.isnan(vol_20)) else vol_90
    if v is None or (isinstance(v, float) and np.isnan(v)):
        return 50.0
    if v <= 18:
        return 100.0
    if v <= 25:
        return 75.0
    if v <= 35:
        return 50.0
    if v <= 45:
        return 30.0
    return 15.0


def fundamentals_scores(symbol: str) -> Dict[str, float]:
    import time
    sym = symbol.upper().replace(".NS", "")
    hit = _fund_cache.get(sym)
    if hit and time.time() - hit[0] < 21600:
        return hit[1]
    out = {"score_value": 50.0, "pe": None, "de": None}
    if yf is None:
        return out
    try:
        info = yf.Ticker(f"{sym}.NS").info or {}
        pe = info.get("trailingPE") or info.get("forwardPE")
        de = info.get("debtToEquity")
        dy = info.get("dividendYield") or 0
        if pe and pe > 0:
            if 8 <= pe <= 20:
                out["score_value"] = 90.0
            elif 20 < pe <= 30:
                out["score_value"] = 65.0
            elif pe < 8:
                out["score_value"] = 70.0
            else:
                out["score_value"] = 35.0
            out["pe"] = float(pe)
        if de is not None:
            out["de"] = float(de)
            if de < 50:
                out["score_value"] = min(100.0, out["score_value"] + 5)
            elif de > 150:
                out["score_value"] = max(10.0, out["score_value"] - 15)
        if dy and float(dy) > 1.5:
            out["score_value"] = min(100.0, out["score_value"] + 5)
    except Exception as e:
        logger.debug(f"fundamentals {sym}: {e}")
    _fund_cache[sym] = (time.time(), out)
    return out


def friction_note(score: float, atr_pct: float):
    if score >= 65 and atr_pct < 1.0:
        return "Thin ATR vs friction — edge may be small after costs"
    return None
