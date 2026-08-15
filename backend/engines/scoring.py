"""Normalize raw indicators to 0–100 scores."""
from __future__ import annotations
import numpy as np

class ScoringEngine:
    @staticmethod
    def normalize_rsi(rsi: float) -> float:
        if rsi is None or (isinstance(rsi, float) and np.isnan(rsi)): return 50.0
        if 55 <= rsi <= 75: return 100.0
        if 75 < rsi <= 80: return 80.0
        if rsi > 80: return 25.0
        if 45 <= rsi < 55: return 50.0
        return 15.0

    @staticmethod
    def normalize_ema_distance(dist_pct: float) -> float:
        if dist_pct is None or (isinstance(dist_pct, float) and np.isnan(dist_pct)): return 50.0
        if 1 <= dist_pct <= 5: return 100.0
        if 0 <= dist_pct < 1: return 70.0
        if 5 < dist_pct <= 10: return 55.0
        if dist_pct > 10: return 30.0
        if -3 <= dist_pct < 0: return 40.0
        return 15.0

    @staticmethod
    def normalize_rvol(rvol: float) -> float:
        if rvol is None or (isinstance(rvol, float) and np.isnan(rvol)): return 40.0
        return float(min(100.0, max(0.0, rvol * 40.0)))

    @staticmethod
    def normalize_macd_hist(hist: float) -> float:
        if hist is None or (isinstance(hist, float) and np.isnan(hist)): return 50.0
        if hist > 0: return min(100.0, 60.0 + abs(hist) * 5)
        return max(0.0, 40.0 - abs(hist) * 5)

    @staticmethod
    def normalize_delivery(delivery_pct: float) -> float:
        if not delivery_pct: return 40.0
        return float(min(100.0, (delivery_pct / 60.0) * 100.0))

    @staticmethod
    def normalize_fii(fii_net_cr: float) -> float:
        if fii_net_cr > 1000: return 100.0
        if fii_net_cr > 0: return 65.0
        if fii_net_cr > -1000: return 35.0
        return 10.0
