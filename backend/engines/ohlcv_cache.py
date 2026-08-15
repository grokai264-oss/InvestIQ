"""In-memory OHLCV cache — avoids re-downloading Yahoo data every request."""
from __future__ import annotations

import time
from typing import Dict, Optional, Tuple
import pandas as pd

_store: Dict[str, Tuple[float, pd.DataFrame]] = {}
DEFAULT_TTL = 900  # 15 minutes


def get(symbol: str) -> Optional[pd.DataFrame]:
    item = _store.get(symbol.upper())
    if not item:
        return None
    ts, df = item
    if time.time() - ts > DEFAULT_TTL:
        _store.pop(symbol.upper(), None)
        return None
    return df.copy()


def put(symbol: str, df: pd.DataFrame, ttl: int = DEFAULT_TTL) -> None:
    _store[symbol.upper()] = (time.time(), df.copy())


def clear() -> None:
    _store.clear()
