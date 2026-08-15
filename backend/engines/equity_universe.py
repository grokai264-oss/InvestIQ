"""NSE equity universe — full scrip master when data file present."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List

_DATA = Path(__file__).resolve().parent.parent / "data" / "equity_universe.json"


def _load() -> Dict[str, str]:
    if _DATA.exists():
        try:
            raw = json.loads(_DATA.read_text(encoding="utf-8"))
            return {str(k).upper(): str(v) for k, v in raw.items()}
        except Exception:
            pass
    return {
        "RELIANCE": "Reliance Industries",
        "SUZLON": "Suzlon Energy",
        "BEL": "Bharat Electronics",
        "HPCL": "Hindustan Petroleum",
        "HINDPETRO": "Hindustan Petroleum",
    }


EQUITY_MAP: Dict[str, str] = _load()


def search_equity(query: str, limit: int = 25) -> List[Dict[str, str]]:
    q = (query or "").strip().upper()
    if not q:
        keys = list(EQUITY_MAP.keys())[:limit]
        return [{"symbol": k, "name": EQUITY_MAP[k], "segment": "EQ"} for k in keys]
    out: List[Dict[str, str]] = []
    for sym, name in EQUITY_MAP.items():
        if sym.startswith(q):
            out.append({"symbol": sym, "name": name, "segment": "EQ"})
            if len(out) >= limit:
                return out
    for sym, name in EQUITY_MAP.items():
        if any(r["symbol"] == sym for r in out):
            continue
        if q in sym or q in name.upper():
            out.append({"symbol": sym, "name": name, "segment": "EQ"})
            if len(out) >= limit:
                break
    if not out and 2 <= len(q) <= 15 and all(c.isalnum() or c in "&-" for c in q):
        out.append({"symbol": q, "name": "NSE equity", "segment": "EQ"})
    return out


def all_symbols() -> List[str]:
    return list(EQUITY_MAP.keys())
