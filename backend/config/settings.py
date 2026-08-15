"""
Settings — all secrets from environment variables only.
Never commit real values to GitHub.
"""
from __future__ import annotations

from typing import Optional, List
from pydantic_settings import BaseSettings
from pydantic import Field


class Settings(BaseSettings):
    # Kotak Neo (set these ONLY in Render Environment)
    KOTAK_CONSUMER_KEY: Optional[str] = None
    KOTAK_MOBILE: Optional[str] = None
    KOTAK_UCC: Optional[str] = None
    KOTAK_MPIN: Optional[str] = None
    KOTAK_TOTP_SECRET: Optional[str] = None
    KOTAK_ENVIRONMENT: str = "prod"

    # Optional later
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_PASSWORD: Optional[str] = None
    POSTGRES_DSN: Optional[str] = None

    # Expanded liquid universe for Desk rankings (Nifty + high-volume names)
    # Full NSE search is available via /api/v1/search + Flutter offline catalog (2235 symbols)
    UNIVERSE_SYMBOLS: str = (
        "RELIANCE,TCS,INFY,HDFCBANK,ICICIBANK,SBIN,BHARTIARTL,ITC,KOTAKBANK,LT,"
        "AXISBANK,HINDUNILVR,BAJFINANCE,ASIANPAINT,MARUTI,TITAN,SUNPHARMA,WIPRO,"
        "ULTRACEMCO,NESTLEIND,POWERGRID,NTPC,ONGC,COALINDIA,TATASTEEL,JSWSTEEL,"
        "ADANIENT,ADANIPORTS,BAJAJFINSV,TECHM,HCLTECH,M&M,INDUSINDBK,CIPLA,"
        "DRREDDY,EICHERMOT,GRASIM,HEROMOTOCO,BPCL,HINDPETRO,HPCL,IOC,BEL,SUZLON,"
        "TATAMOTORS,VEDL,IRFC,RECLTD,PFC,HAL,BHEL"
    )

    class Config:
        env_file = ".env"
        case_sensitive = True

    @property
    def kotak_configured(self) -> bool:
        return all([
            self.KOTAK_CONSUMER_KEY,
            self.KOTAK_MOBILE,
            self.KOTAK_UCC,
            self.KOTAK_MPIN,
            self.KOTAK_TOTP_SECRET,
        ])

    @property
    def symbols(self) -> List[str]:
        return [s.strip().upper() for s in self.UNIVERSE_SYMBOLS.split(",") if s.strip()]


settings = Settings()
