# InvestIQ

Read-only stock rankings + portfolio view. **Never places orders.**

## Stack
- Flutter app (classical desk UI)
- FastAPI backend on Render: https://investiq-g92v.onrender.com

## Features
- Multi-horizon rankings (daily / monthly / yearly)
- Market indices strip
- Local display name (onboarding) — not sent to servers
- Portfolio tab (read-only; needs Kotak linked on server)
- Watchlist (on-device only)
- Profile / safety notes

## Safety
- No order/trade endpoints
- Kotak secrets only in Render Environment
- Analytical signals only

## Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn api.main:app --host 0.0.0.0 --port 8000
```
