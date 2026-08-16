"""InvestIQ settings — secrets from environment variables only.
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

    # Optional portfolio gate (set on Render for private single-user)
    PORTFOLIO_ACCESS_TOKEN: Optional[str] = None

    # Optional later
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_PASSWORD: Optional[str] = None
    POSTGRES_DSN: Optional[str] = None

    # Liquid scoring universe (expanded toward NIFTY 500 core).
    # Full NSE search remains via /api/v1/search + Flutter offline catalog.
    # True point-in-time NIFTY 500 membership + free-float weights is the next data layer.
    UNIVERSE_SYMBOLS: str = (
        "RELIANCE,TCS,INFY,HDFCBANK,ICICIBANK,SBIN,BHARTIARTL,ITC,KOTAKBANK,LT,"
        "AXISBANK,HINDUNILVR,BAJFINANCE,ASIANPAINT,MARUTI,TITAN,SUNPHARMA,WIPRO,"
        "ULTRACEMCO,NESTLEIND,POWERGRID,NTPC,ONGC,COALINDIA,TATASTEEL,JSWSTEEL,"
        "ADANIENT,ADANIPORTS,BAJAJFINSV,TECHM,HCLTECH,M&M,INDUSINDBK,CIPLA,"
        "DRREDDY,EICHERMOT,GRASIM,HEROMOTOCO,BPCL,HINDPETRO,IOC,BEL,SUZLON,"
        "TATAMOTORS,VEDL,IRFC,RECLTD,PFC,HAL,BHEL,DIVISLAB,APOLLOHOSP,BRITANNIA,"
        "PIDILITIND,DABUR,GODREJCP,HAVELLS,SIEMENS,ABB,CGPOWER,POLYCAB,CUMMINSIND,"
        "BAJAJ-AUTO,TVSMOTOR,ASHOKLEY,MOTHERSON,BOSCHLTD,MRF,AMBUJACEM,SHREECEM,"
        "DLF,GODREJPROP,OBEROIRLTY,PRESTIGE,INDIGO,IRCTC,ZOMATO,PAYTM,NYKAA,"
        "SBILIFE,HDFCLIFE,ICICIPRULI,ICICIGI,SBICARD,CHOLAFIN,MUTHOOTFIN,BAJAJHLDNG,"
        "LTIM,PERSISTENT,COFORGE,MPHASIS,OFSS,NAUKRI,TRENT,PAGEIND,ABBOTINDIA,"
        "AUROPHARMA,BIOCON,LUPIN,TORNTPHARM,ALKEM,MAXHEALTH,FORTIS,METROPOLIS,"
        "GAIL,PETRONET,IGL,MGL,CONCOR,ADANIGREEN,TATAPOWER,NHPC,SJVN"
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
