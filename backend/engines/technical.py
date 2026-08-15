"""Technical factor computation from OHLCV — pure pandas."""
from __future__ import annotations
import numpy as np
import pandas as pd

class TechnicalEngine:
    @staticmethod
    def compute_factors(df: pd.DataFrame) -> pd.DataFrame:
        d = df.copy().sort_index(ascending=True)
        close = d["close"].astype(float)
        high = d["high"].astype(float)
        low = d["low"].astype(float)
        vol = d["volume"].astype(float)
        delta = close.diff()
        gain = delta.clip(lower=0)
        loss = (-delta).clip(lower=0)
        avg_gain = gain.ewm(alpha=1/14, min_periods=14, adjust=False).mean()
        avg_loss = loss.ewm(alpha=1/14, min_periods=14, adjust=False).mean()
        rs = avg_gain / avg_loss.replace(0, np.nan)
        d["rsi"] = 100 - (100 / (1 + rs))
        d["ema_20"] = close.ewm(span=20, adjust=False).mean()
        d["ema_distance_pct"] = ((close - d["ema_20"]) / d["ema_20"]) * 100
        prev_close = close.shift(1)
        tr = pd.concat([(high-low), (high-prev_close).abs(), (low-prev_close).abs()], axis=1).max(axis=1)
        d["atr"] = tr.ewm(alpha=1/14, min_periods=14, adjust=False).mean()
        vol_sma = vol.rolling(10, min_periods=5).mean()
        d["rvol"] = vol / vol_sma.replace(0, np.nan)
        ema12 = close.ewm(span=12, adjust=False).mean()
        ema26 = close.ewm(span=26, adjust=False).mean()
        macd = ema12 - ema26
        signal = macd.ewm(span=9, adjust=False).mean()
        d["macd_hist"] = macd - signal
        return d.dropna(subset=["rsi", "ema_20", "atr"])
