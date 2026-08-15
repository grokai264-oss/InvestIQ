"""Seed OHLCV from Yahoo Finance (.NS) with in-memory TTL cache."""
from __future__ import annotations

import pandas as pd
from loguru import logger

from . import ohlcv_cache

try:
    import yfinance as yf
except ImportError:
    yf = None


class LiveDataFetcher:
    @staticmethod
    def fetch_daily_ohlcv(symbol: str, days: int = 90) -> pd.DataFrame:
        symbol = symbol.upper().replace(".NS", "")
        cached = ohlcv_cache.get(symbol)
        if cached is not None and len(cached) >= 30:
            return cached

        if yf is None:
            raise RuntimeError("yfinance not installed")

        ticker = f"{symbol}.NS"
        period = "1y" if days >= 180 else ("6mo" if days >= 90 else "3mo")
        raw = yf.download(
            ticker,
            period=period,
            interval="1d",
            progress=False,
            auto_adjust=True,
            threads=False,
        )
        if raw is None or raw.empty:
            raise ValueError(f"No OHLCV for {ticker}")

        if isinstance(raw.columns, pd.MultiIndex):
            raw.columns = [
                c[0].lower() if isinstance(c, tuple) else str(c).lower()
                for c in raw.columns
            ]
        else:
            raw.columns = [str(c).lower() for c in raw.columns]

        need = {}
        for src in ("open", "high", "low", "close", "volume"):
            if src not in raw.columns:
                raise ValueError(f"Missing column {src} for {ticker}")
            need[src] = raw[src].astype(float)

        df = pd.DataFrame(need, index=pd.to_datetime(raw.index)).dropna()
        if len(df) < 30:
            raise ValueError(f"Insufficient history for {ticker}: {len(df)} bars")
        ohlcv_cache.put(symbol, df)
        logger.debug(f"Fetched+cached {len(df)} bars for {ticker}")
        return df
