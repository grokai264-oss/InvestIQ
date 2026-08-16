# InvestIQ

**Smarter Research. Better Decisions.**  
Read-only multi-horizon stock research desk. **Never places orders.**

Built by **Ashish Sarswat**.

## Stack
- Flutter app (desk UI, fl_chart, multi-theme)
- FastAPI backend on Render: https://investiq-g92v.onrender.com

## v2.3 — Research Layer Foundations
- **Chart 2.3**: price axis, time axis, OHLC tooltip, timestamps retained
- **Factor profile**: six research pillars (Momentum / Trend / Quality / Value / Risk / Ownership) with semantic colours; radar secondary
- **Market movers**: gainers & losers with InvestIQ score attach (`/api/v1/market/movers`)
- **Ranking pool**: expanded request-path universe (up to full liquid list)
- **Superstar Investors**: disclosure-based shell (Individuals / Institutions / FII) — quarterly filings, not live
- Engine 2.2 continuous OHLCV scoring remains the quant core

## Safety
- No order/trade endpoints
- Kotak secrets only in Render Environment Variables
- See [SECURITY.md](SECURITY.md)

## Honest next layers
- Real NIFTY 500 constituents + cross-sectional percentiles
- Quality / value / ownership pillars from filings & fundamentals
- Kotak WebSocket → Redis → SSE for true live quotes
- NSE XBRL shareholding feed for Superstar Investors
- Candlestick mode for 1D/1W

## Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn api.main:app --host 0.0.0.0 --port 8000
```

## Flutter
```bash
cd flutter_app
flutter pub get
flutter run
```
