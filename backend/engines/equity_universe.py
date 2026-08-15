"""NSE equity universe for search/filter (cash market EQ only)."""
from __future__ import annotations

from typing import Dict, List

# symbol -> display name (subset; expandable)
EQUITY_MAP: Dict[str, str] = {
    "RELIANCE": "Reliance Industries",
    "TCS": "Tata Consultancy Services",
    "INFY": "Infosys",
    "HDFCBANK": "HDFC Bank",
    "ICICIBANK": "ICICI Bank",
    "SBIN": "State Bank of India",
    "BHARTIARTL": "Bharti Airtel",
    "ITC": "ITC",
    "KOTAKBANK": "Kotak Mahindra Bank",
    "LT": "Larsen & Toubro",
    "BEL": "Bharat Electronics",
    "HINDUNILVR": "Hindustan Unilever",
    "AXISBANK": "Axis Bank",
    "BAJFINANCE": "Bajaj Finance",
    "ASIANPAINT": "Asian Paints",
    "MARUTI": "Maruti Suzuki",
    "SUNPHARMA": "Sun Pharma",
    "TITAN": "Titan Company",
    "WIPRO": "Wipro",
    "NTPC": "NTPC",
    "POWERGRID": "Power Grid",
    "ONGC": "ONGC",
    "TATAMOTORS": "Tata Motors",
    "TATASTEEL": "Tata Steel",
    "JSWSTEEL": "JSW Steel",
    "ADANIENT": "Adani Enterprises",
    "ADANIPORTS": "Adani Ports",
    "ULTRACEMCO": "UltraTech Cement",
    "NESTLEIND": "Nestle India",
    "HCLTECH": "HCL Technologies",
    "TECHM": "Tech Mahindra",
    "INDUSINDBK": "IndusInd Bank",
    "BAJAJFINSV": "Bajaj Finserv",
    "M&M": "Mahindra & Mahindra",
    "COALINDIA": "Coal India",
    "BPCL": "BPCL",
    "IOC": "Indian Oil",
    "GRASIM": "Grasim",
    "CIPLA": "Cipla",
    "DRREDDY": "Dr Reddy's",
    "DIVISLAB": "Divi's Labs",
    "EICHERMOT": "Eicher Motors",
    "HEROMOTOCO": "Hero MotoCorp",
    "BRITANNIA": "Britannia",
    "APOLLOHOSP": "Apollo Hospitals",
    "HDFCLIFE": "HDFC Life",
    "SBILIFE": "SBI Life",
    "PIDILITIND": "Pidilite",
    "DABUR": "Dabur",
    "GODREJCP": "Godrej Consumer",
    "HAVELLS": "Havells",
    "SIEMENS": "Siemens",
    "DLF": "DLF",
    "ZOMATO": "Zomato",
    "PAYTM": "Paytm",
    "NYKAA": "Nykaa",
    "IRCTC": "IRCTC",
    "IRFC": "IRFC",
    "HAL": "Hindustan Aeronautics",
    "BHEL": "BHEL",
    "SAIL": "SAIL",
    "VEDL": "Vedanta",
    "HINDALCO": "Hindalco",
    "PNB": "Punjab National Bank",
    "BANKBARODA": "Bank of Baroda",
    "CANBK": "Canara Bank",
    "FEDERALBNK": "Federal Bank",
    "IDFCFIRSTB": "IDFC First Bank",
    "AUROPHARMA": "Aurobindo Pharma",
    "LUPIN": "Lupin",
    "BIOCON": "Biocon",
    "AMBUJACEM": "Ambuja Cements",
    "SHREECEM": "Shree Cement",
    "ACC": "ACC",
    "INDIGO": "InterGlobe Aviation",
    "NAUKRI": "Info Edge",
    "DMART": "Avenue Supermarts",
    "TRENT": "Trent",
    "PAGEIND": "Page Industries",
    "BERGEPAINT": "Berger Paints",
    "COLPAL": "Colgate-Palmolive",
    "MARICO": "Marico",
    "UBL": "United Breweries",
    "MCDOWELL-N": "United Spirits",
    "GAIL": "GAIL",
    "PETRONET": "Petronet LNG",
    "RECLTD": "REC",
    "PFC": "Power Finance",
    "NHPC": "NHPC",
    "SJVN": "SJVN",
}


def search_equity(query: str, limit: int = 25) -> List[Dict[str, str]]:
    q = (query or "").strip().upper()
    if not q:
        # default: popular
        keys = list(EQUITY_MAP.keys())[:limit]
        return [{"symbol": k, "name": EQUITY_MAP[k], "segment": "EQ"} for k in keys]
    out = []
    for sym, name in EQUITY_MAP.items():
        if q in sym or q in name.upper():
            out.append({"symbol": sym, "name": name, "segment": "EQ"})
            if len(out) >= limit:
                break
    return out


def all_symbols() -> List[str]:
    return list(EQUITY_MAP.keys())
