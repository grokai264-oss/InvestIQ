# InvestIQ

**Smarter Research. Better Decisions.**  
Read-only multi-horizon stock research desk. **Never places orders.**

Built by **Ashish Sarswat**.

## Stack
- Flutter app (desk UI, fl_chart, multi-theme)
- FastAPI backend on Render: https://investiq-g92v.onrender.com

## v2.1 highlights
- Continuous factor normalizers (no coarse RSI 55–75 → 100 plateaus)
- Expanded liquid scoring universe (~120 names toward NIFTY 500 core)
- Profile theme switcher (Midnight / Paper) + accent palette
- Stock detail: LiveStockChart shell + humanized timestamps + Risk & Scenario panel
- Security policy + expanded `.gitignore` (see `SECURITY.md`)

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
- See [SECURITY.md](SECURITY.md) for rotation and Git history guidance

## Backend (local)
```bash
cd backend
pip install -r requirements.txt
# copy env vars — never commit .env
uvicorn api.main:app --host 0.0.0.0 --port 8000
```

Note: `backend/api/main.py` in this tree is a deployment placeholder relative to the live Render service. Engines under `backend/engines/` are the shared research core.

## Flutter
```bash
cd flutter_app
flutter pub get
flutter run
```

Optional: `--dart-define=API_BASE_URL=https://your-host`
