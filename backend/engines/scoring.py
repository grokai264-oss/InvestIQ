"""Normalize raw indicators to continuous 0–100 scores.

Design goals (v2.1):
- Avoid wide plateaus (e.g. RSI 55–75 all → 100) that inflate confidence.
- Prefer smooth / piecewise-linear curves so small changes move the score.
- Missing / NaN → explicit None handling upstream; default 50 only as last resort
  when a factor is optional and must not break the composite.
"""
from __future__ import annotations

import numpy as np


def _clip(x: float, lo: float = 0.0, hi: float = 100.0) -> float:
    return float(min(hi, max(lo, x)))


def _finite(x) -> bool:
    try:
        return x is not None and np.isfinite(float(x))
    except Exception:
        return False


class ScoringEngine:
    @staticmethod
    def normalize_rsi(rsi: float) -> float:
        """Peak near 62–68 (constructive momentum); taper into overbought/oversold."""
        if not _finite(rsi):
            return 50.0
        r = float(rsi)
        if r < 20:
            return _clip(5 + r * 0.5)
        if r < 35:
            return _clip(15 + (r - 20) * 1.2)
        if r < 45:
            return _clip(33 + (r - 35) * 1.7)
        if r < 55:
            return _clip(50 + (r - 45) * 2.5)
        if r <= 68:
            # sweet spot: 55 → ~75, 62 → ~92, 68 → 100
            return _clip(75 + (r - 55) * (25 / 13))
        if r <= 75:
            return _clip(100 - (r - 68) * 2.5)
        if r <= 85:
            return _clip(82.5 - (r - 75) * 4.5)
        return _clip(20 - (r - 85) * 1.5)

    @staticmethod
    def normalize_ema_distance(dist_pct: float) -> float:
        """Slight premium above EMA preferred; large extensions or deep discounts penalized."""
        if not _finite(dist_pct):
            return 50.0
        d = float(dist_pct)
        if d < -8:
            return 10.0
        if d < -3:
            return _clip(15 + (d + 8) * 5)
        if d < 0:
            return _clip(40 + (d + 3) * (15 / 3))
        if d <= 2:
            return _clip(55 + d * 20)  # 0→55, 2→95
        if d <= 5:
            return _clip(95 - (d - 2) * 8)  # mild extension still good
        if d <= 10:
            return _clip(71 - (d - 5) * 6)
        return _clip(35 - min(20, (d - 10) * 2))

    @staticmethod
    def normalize_rvol(rvol: float) -> float:
        if not _finite(rvol):
            return 40.0
        # 1.0x = baseline, 2.0x+ strong participation
        return _clip(rvol * 42.0)

    @staticmethod
    def normalize_macd_hist(hist: float) -> float:
        if not _finite(hist):
            return 50.0
        h = float(hist)
        # Symmetric soft response around zero
        if h >= 0:
            return _clip(55 + min(45.0, h * 8.0))
        return _clip(45 - min(45.0, abs(h) * 8.0))

    @staticmethod
    def normalize_delivery(delivery_pct: float) -> float:
        if not _finite(delivery_pct) or float(delivery_pct) <= 0:
            return 40.0
        # Typical delivery ~40–60%; high delivery = institutional interest proxy
        return _clip((float(delivery_pct) / 55.0) * 100.0)

    @staticmethod
    def normalize_fii(fii_net_cr: float) -> float:
        """Market-wide FII only — soft continuous curve."""
        if not _finite(fii_net_cr):
            return 50.0
        x = float(fii_net_cr)
        # map roughly [-3000, +3000] → [10, 95]
        return _clip(50.0 + (x / 3000.0) * 40.0)
