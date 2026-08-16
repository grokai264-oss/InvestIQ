"""Institutional-inspired factors computable from OHLCV + light fundamentals.

Implemented (no paid Level-2 required):
- Session VWAP distance (volume-weighted fair value proxy)
- Momentum ROC (63d ~ 3m, 126d ~ 6m)
- Realized volatility (20d / 90d) → low-vol score
- India VIX regime classifier
- Simple quality/value proxies from yfinance fundamentals when available

v2.1: continuous normalizers (no wide plateaus).
"""
from __future__ import annotations

from typing import Dict, Optional, Tuple
import numpy as np
import pandas as pd
from loguru import logger

try:
    import yfinance as yf
except ImportError:
    yf = None

_vix_cache: Tuple[float, float] = (0.0, 0.0)
_fund_cache: Dict[str, Tuple[float, dict]] = {}


def _finite(x) -> bool:
    try:
        return x is not None and np.isfinite(float(x))
    except Exception:
        return False


def _clip(x: float, lo: float = 0.0, hi: float = 100.0) -> float:
    return float(min(hi, max(lo, x)))


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
    if v < 13.0:
        return "low"
    if v > 18.0:
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
        # Expansion: tilt to momentum / participation
        w["momentum"] = w.get("momentum", 0.1) + 0.08
        w["rvol"] = w.get("rvol", 0.1) + 0.05
        w["rsi"] = w.get("rsi", 0.1) + 0.03
        w["low_vol"] = max(0.02, w.get("low_vol", 0.05) - 0.04)
        w["value"] = max(0.01, w.get("value", 0.02) - 0.01)
    elif regime == "high":
        # Defensive: quality / low-vol / value
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
    """Slight premium to VWAP preferred; large extensions or discounts softer."""
    if not _finite(dist_pct):
        return 50.0
    d = float(dist_pct)
    if d < -6:
        return 18.0
    if d < -2:
        return _clip(25 + (d + 6) * 7.5)
    if d < 0:
        return _clip(55 + d * 5)
    if d <= 2:
        return _clip(55 + d * 20)
    if d <= 5:
        return _clip(95 - (d - 2) * 10)
    if d <= 10:
        return _clip(65 - (d - 5) * 6)
    return 25.0


def normalize_momentum(roc_63: float, roc_126: float) -> float:
    def _one(roc) -> float:
        if not _finite(roc):
            return 50.0
        r = float(roc)
        # continuous: -20 → ~15, 0 → 55, 10 → 80, 25 → 98
        if r < -15:
            return 12.0
        if r < 0:
            return _clip(35 + (r + 15) * (20 / 15))
        if r < 12:
            return _clip(55 + r * 2.5)
        if r < 25:
            return _clip(85 + (r - 12) * (13 / 13))
        return _clip(98 - min(15, (r - 25) * 0.5))

    return float(0.6 * _one(roc_63) + 0.4 * _one(roc_126))


def normalize_low_vol(vol_20: float, vol_90: float) -> float:
    v = vol_20 if _finite(vol_20) else (vol_90 if _finite(vol_90) else None)
    if v is None:
        return 50.0
    # lower realized vol → higher score (defensive quality)
    vv = float(v)
    if vv <= 15:
        return 100.0
    if vv <= 22:
        return _clip(100 - (vv - 15) * 3.5)
    if vv <= 32:
        return _clip(75.5 - (vv - 22) * 2.5)
    if vv <= 45:
        return _clip(50.5 - (vv - 32) * 2.0)
    return _clip(20 - min(15, (vv - 45) * 0.8))


def fundamentals_scores(symbol: str) -> Dict[str, float]:
    import time
    sym = symbol.upper().replace(".NS", "")
    hit = _fund_cache.get(sym)
    if hit and time.time() - hit[0] < 21600:
        return hit[1]
    out: Dict[str, float] = {"score_value": 50.0, "pe": None, "de": None}  # type: ignore
    if yf is None:
        return out
    try:
        info = yf.Ticker(f"{sym}.NS").info or {}
        pe = info.get("trailingPE") or info.get("forwardPE")
        de = info.get("debtToEquity")
        dy = info.get("dividendYield") or 0
        if pe and pe > 0:
            p = float(pe)
            # continuous PE preference: sweet 12–22
            if p < 6:
                out["score_value"] = 55.0
            elif p < 12:
                out["score_value"] = 70.0 + (p - 6) * 3.0
            elif p <= 22:
                out["score_value"] = 95.0 - abs(p - 17) * 1.5
            elif p <= 35:
                out["score_value"] = 70.0 - (p - 22) * 2.0
            else:
                out["score_value"] = max(15.0, 44.0 - (p - 35) * 0.8)
            out["pe"] = p
        if de is not None:
            out["de"] = float(de)
            if de < 40:
                out["score_value"] = min(100.0, out["score_value"] + 6)
            elif de > 120:
                out["score_value"] = max(10.0, out["score_value"] - 12)
        if dy and float(dy) > 1.2:
            out["score_value"] = min(100.0, out["score_value"] + 4)
    except Exception as e:
        logger.debug(f"fundamentals {sym}: {e}")
    _fund_cache[sym] = (time.time(), out)
    return out


def friction_note(score: float, atr_pct: float):
    if score >= 65 and atr_pct < 1.0:
        return "Thin ATR vs friction — edge may be small after costs"
    return None
