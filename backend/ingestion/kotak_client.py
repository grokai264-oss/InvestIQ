"""
Kotak Neo client — READ ONLY.
Never places orders. Only login + quotes / instruments.
"""
from __future__ import annotations

import os
from typing import Any, Dict, List, Optional
from loguru import logger

try:
    import pyotp
except ImportError:
    pyotp = None

try:
    from neo_api_client import NeoAPI
except ImportError:
    NeoAPI = None
    logger.warning("neo_api_client not installed")


class KotakReadOnlyClient:
    """Session manager for quotes only."""

    def __init__(self):
        self._client: Optional[Any] = None
        self._ok = False

    @property
    def ready(self) -> bool:
        return self._ok and self._client is not None

    def connect(
        self,
        consumer_key: str,
        mobile: str,
        ucc: str,
        mpin: str,
        totp_secret: str,
        environment: str = "prod",
    ) -> bool:
        if NeoAPI is None or pyotp is None:
            logger.error("neo_api_client or pyotp missing")
            return False
        try:
            totp = pyotp.TOTP(totp_secret).now()
            client = NeoAPI(
                consumer_key=consumer_key,
                environment=environment,
            )
            # Two-step auth (Neo TOTP flow)
            client.totp_login(mobilenumber=mobile, ucc=ucc, totp=totp)
            client.totp_validate(mpin=mpin)
            self._client = client
            self._ok = True
            logger.info("Kotak Neo session established (read-only)")
            return True
        except Exception as e:
            logger.exception(f"Kotak login failed: {e}")
            self._client = None
            self._ok = False
            return False

    def quotes(self, symbols: List[str]) -> List[Dict[str, Any]]:
        """Best-effort quotes. Returns list of dicts with symbol, ltp, etc."""
        if not self.ready:
            return []
        out: List[Dict[str, Any]] = []
        try:
            # SDK method names vary by version; try common patterns
            client = self._client
            for sym in symbols:
                row: Dict[str, Any] = {"symbol": sym}
                try:
                    if hasattr(client, "quotes"):
                        q = client.quotes(instrument_tokens=[sym])  # may need token map
                        row["raw"] = q
                    elif hasattr(client, "get_quotes"):
                        q = client.get_quotes(sym)
                        row["raw"] = q
                except Exception as e:
                    row["error"] = str(e)
                out.append(row)
        except Exception as e:
            logger.error(f"quotes error: {e}")
        return out


kotak = KotakReadOnlyClient()
