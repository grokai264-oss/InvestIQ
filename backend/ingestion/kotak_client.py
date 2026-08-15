"""
Kotak Neo client — READ ONLY via pure HTTP (no neo_api_client SDK).
Never places orders. Only session + holdings.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional
from loguru import logger

try:
    import pyotp
except ImportError:
    pyotp = None

try:
    import requests
except ImportError:
    requests = None

LOGIN_URL = "https://mis.kotaksecurities.com/login/1.0/tradeApiLogin"
VALIDATE_URL = "https://mis.kotaksecurities.com/login/1.0/tradeApiValidate"
NEO_FIN_KEY = "neotradeapi"


class KotakReadOnlyClient:
    """TOTP + MPIN session; holdings only."""

    def __init__(self):
        self._ok = False
        self._token: Optional[str] = None
        self._sid: Optional[str] = None
        self._base_url: Optional[str] = None
        self._access_token: Optional[str] = None
        self._last_error: Optional[str] = None

    @property
    def ready(self) -> bool:
        return bool(self._ok and self._token and self._sid and self._base_url)

    @property
    def last_error(self) -> Optional[str]:
        return self._last_error

    def connect(
        self,
        consumer_key: str,
        mobile: str,
        ucc: str,
        mpin: str,
        totp_secret: str,
        environment: str = "prod",
    ) -> bool:
        self._ok = False
        self._last_error = None
        if requests is None or pyotp is None:
            self._last_error = "requests or pyotp missing"
            logger.error(self._last_error)
            return False

        mobile = (mobile or "").strip()
        if mobile and not mobile.startswith("+"):
            mobile = "+91" + mobile.lstrip("0")

        try:
            totp_code = pyotp.TOTP(totp_secret.strip()).now()
        except Exception as e:
            self._last_error = f"Invalid TOTP secret: {e}"
            logger.error(self._last_error)
            return False

        headers = {
            "Authorization": consumer_key.strip(),  # plain access token, not Bearer
            "neo-fin-key": NEO_FIN_KEY,
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

        try:
            # Step 1: TOTP login
            r1 = requests.post(
                LOGIN_URL,
                headers=headers,
                json={
                    "mobileNumber": mobile,
                    "ucc": ucc.strip(),
                    "totp": totp_code,
                },
                timeout=25,
            )
            if r1.status_code != 200:
                self._last_error = f"TOTP login HTTP {r1.status_code}: {r1.text[:300]}"
                logger.error(self._last_error)
                return False

            body1 = r1.json()
            data1 = body1.get("data") or body1
            view_token = data1.get("token") or data1.get("viewToken")
            view_sid = data1.get("sid")
            if not view_token or not view_sid:
                self._last_error = f"TOTP login missing token/sid: {str(body1)[:300]}"
                logger.error(self._last_error)
                return False

            # Step 2: MPIN validate
            headers2 = dict(headers)
            headers2["sid"] = str(view_sid)
            headers2["Auth"] = str(view_token)

            r2 = requests.post(
                VALIDATE_URL,
                headers=headers2,
                json={"mpin": str(mpin).strip()},
                timeout=25,
            )
            if r2.status_code != 200:
                self._last_error = f"MPIN validate HTTP {r2.status_code}: {r2.text[:300]}"
                logger.error(self._last_error)
                return False

            body2 = r2.json()
            data2 = body2.get("data") or body2
            trade_token = data2.get("token") or data2.get("tradeToken") or view_token
            trade_sid = data2.get("sid") or view_sid
            base_url = (
                data2.get("baseUrl")
                or data2.get("baseURL")
                or data2.get("dataCenter")
                or ""
            )
            # Some responses nest baseUrl
            if not base_url and isinstance(data2.get("dataCenterMap"), dict):
                base_url = next(iter(data2["dataCenterMap"].values()), "")

            if not trade_token or not trade_sid:
                self._last_error = f"Validate missing token/sid: {str(body2)[:300]}"
                logger.error(self._last_error)
                return False

            if base_url and not str(base_url).startswith("http"):
                base_url = f"https://{base_url}"

            # Fallback known prod hosts if baseUrl missing
            if not base_url:
                base_url = "https://mis.kotaksecurities.com"

            self._token = str(trade_token)
            self._sid = str(trade_sid)
            self._base_url = str(base_url).rstrip("/")
            self._access_token = consumer_key.strip()
            self._ok = True
            logger.info(f"Kotak Neo session OK (read-only). base={self._base_url}")
            return True

        except Exception as e:
            self._last_error = f"Kotak connect exception: {e}"
            logger.exception(self._last_error)
            self._ok = False
            return False

    def _session_headers(self) -> Dict[str, str]:
        return {
            "Authorization": self._access_token or "",
            "Auth": self._token or "",
            "sid": self._sid or "",
            "neo-fin-key": NEO_FIN_KEY,
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

    def holdings(self) -> List[Dict[str, Any]]:
        """Fetch CNC holdings. Empty list on failure."""
        if not self.ready or requests is None:
            return []

        urls = [
            f"{self._base_url}/portfolio/v1/holdings",
            f"{self._base_url}/Portfolio/1.0/portfolio/v1/holdings",
            f"{self._base_url}/portfolio/1.0/portfolio/v1/holdings",
        ]
        for url in urls:
            try:
                r = requests.get(url, headers=self._session_headers(), timeout=25)
                if r.status_code != 200:
                    logger.warning(f"holdings {url} -> {r.status_code} {r.text[:200]}")
                    continue
                body = r.json()
                data = body.get("data") if isinstance(body, dict) else body
                if isinstance(data, list):
                    return data
                if isinstance(data, dict) and isinstance(data.get("holdings"), list):
                    return data["holdings"]
            except Exception as e:
                logger.warning(f"holdings fetch error: {e}")
        return []

    def normalized_holdings(self) -> List[Dict[str, Any]]:
        raw = self.holdings()
        out: List[Dict[str, Any]] = []
        for h in raw:
            if not isinstance(h, dict):
                continue
            symbol = (
                h.get("symbol")
                or h.get("displaySymbol")
                or h.get("trdSym")
                or ""
            )
            symbol = str(symbol).replace("-EQ", "").strip().upper()
            qty = float(h.get("quantity") or h.get("sellableQuantity") or 0)
            avg = float(h.get("averagePrice") or h.get("avgPrice") or h.get("avgPrc") or 0)
            ltp = float(
                h.get("closingPrice")
                or h.get("ltp")
                or h.get("lastPrice")
                or avg
            )
            mkt = float(h.get("mktValue") or (ltp * qty))
            cost = float(h.get("holdingCost") or (avg * qty))
            pnl = mkt - cost
            pnl_pct = (pnl / cost * 100.0) if cost else 0.0
            if not symbol or qty == 0:
                continue
            out.append(
                {
                    "symbol": symbol,
                    "quantity": qty,
                    "avg_price": round(avg, 4),
                    "ltp": round(ltp, 4),
                    "pnl": round(pnl, 2),
                    "pnl_pct": round(pnl_pct, 2),
                    "mkt_value": round(mkt, 2),
                }
            )
        return out


kotak = KotakReadOnlyClient()
