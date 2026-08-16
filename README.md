# InvestIQ

**Smarter Research. Better Decisions.**  
Read-only multi-horizon stock research desk. **Never places orders.**

Built by **Ashish Sarswat**.

## Stack
- Flutter app (desk UI, fl_chart, multi-theme)
- FastAPI backend on Render: https://investiq-g92v.onrender.com

## v2.2 — Connected Research Layer
- **Real continuous scoring** via `live_engine.py` (OHLCV → technicals → advanced factors → continuous normalizers → VIX regime weights). **Zero hash-based scores.**
- **History API**: `GET /api/v1/stocks/{symbol}/history?range=1D|1W|1M|3M|1Y|5Y`
- Flutter chart wired: `ApiService.getHistory` → `LiveStockChart` with timeframe chips
- Portfolio optional gate: `PORTFOLIO_ACCESS_TOKEN` + `X-InvestIQ-Token` header
- Liquid scoring universe ~113 names toward NIFTY 500 core (full constituents next)
- Profile: Ashish Sarswat credit, theme switcher (Midnight / Paper + accents), honest methodology

## Features
- Multi-horizon rankings (daily / monthly / yearly)
- Market indices strip + sector map (structural weights for now)
- Local display name & watchlist (on-device only)
- Portfolio tab (read-only; single-user / Kotak on server)
- Factor audit with expandable contributions
- Honest confidence label (score-distance, not calibrated probability)

## Safety
- No order/trade endpoints
- Kotak secrets **only** in Render Environment Variables
- Analytical signals only
- See [SECURITY.md](SECURITY.md)

## Backend (local)
```bash
cd backend
pip install -r requirements.txt
# secrets only in env — never commit .env
uvicorn api.main:app --host 0.0.0.0 --port 8000
```

## Flutter
```bash
cd flutter_app
flutter pub get
flutter run
```

Optional: `--dart-define=API_BASE_URL=https://your-host`

## Next layers (honest)
- Point-in-time NIFTY 500 membership + free-float weights
- Redis latest-price + Kotak WebSocket ticks
- Cross-sectional percentiles / sector neutrality / walk-forward lab
