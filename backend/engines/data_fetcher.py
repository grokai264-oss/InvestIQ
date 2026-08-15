"""Seed OHLCV from Yahoo Finance (.NS) for Indian equities."""
from __future__ import annotations

import pandas as pd
from loguru import logger

try:
    import yfinance as yf
except ImportError:
    yf = None


class LiveDataFetcher:
    @staticmethod
    def fetch_daily_ohlcv(symbol: str, days: int = 90) -> pd.DataFrame:
        if yf is None:
            raise RuntimeError("yfinance not installed")

        ticker = f"{symbol.upper().replace('.NS', '')}.NS"
        period = "6mo" if days >= 90 else ("3mo" if days >= 60 else "1mo")
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
            raw.columns = [c[0].lower() if isinstance(c, tuple) else str(c).lower() for c in raw.columns]
        else:
            raw.columns = [str(c).lower() for c in raw.columns]

        need = {}
        for src, dst in [("open", "open"), ("high", "high"), ("low", "low"), ("close", "close"), ("volume", "volume")]:
            if src not in raw.columns:
                raise ValueError(f"Missing column {src} for {ticker}")
            need[dst] = raw[src].astype(float)

        df = pd.DataFrame(need, index=pd.to_datetime(raw.index))
        df = df.dropna()
        if len(df) < 30:
            raise ValueError(f"Insufficient history for {ticker}: {len(df)} bars")
        logger.debug(f"Fetched {len(df)} bars for {ticker}")
        return df
