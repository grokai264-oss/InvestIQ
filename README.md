# InvestIQ

**Read-only** multi-horizon stock recommendation system powered by Kotak Neo live data + institutional factors.

Backend (Python + FastAPI) + modern Flutter dashboard.

> ⚠️ **This app NEVER places, modifies, or cancels any orders on Kotak Neo or any broker.**  
> It only collects market data, computes factors, and shows analytical rankings.

---

## Repository Structure

```
InvestIQ/
├── backend/                     # Python FastAPI + factor engines
│   ├── api/
│   │   └── main.py              # FastAPI app (read-only endpoints)
│   ├── core/
│   │   ├── factors/             # Technical + Institutional + Scoring
│   │   ├── backtest/            # vectorbt harness
│   │   └── recommendation.py    # Signal generator (no trading)
│   ├── ingestion/               # Kotak auth + live + alternative data
│   ├── storage/                 # Postgres + Redis helpers + schema.sql
│   ├── schemas/
│   ├── config/
│   ├── requirements.txt
│   └── run_*.py
│
├── flutter_app/                 # Modern dark Flutter dashboard
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── screens/             # Dashboard + Stock detail
│   │   ├── services/            # Read-only API client
│   │   ├── widgets/
│   │   └── theme/
│   └── pubspec.yaml
│
└── docs/
    └── REPO_STRUCTURE.md
```

---

## Quick Start (test what it can do today)

### 1. Backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
pip install "git+https://github.com/Kotak-Neo/kotak-neo-api.git#egg=neo_api_client"

# Start the API (demo data included – no Kotak credentials needed for UI test)
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000
```

Open http://localhost:8000/docs to see the interactive API.

### 2. Flutter app

```bash
cd flutter_app
flutter pub get
flutter run
```

**Android emulator**: the API base URL is already set to `http://10.0.2.2:8000`  
**iOS simulator / desktop**: change `baseUrl` in `lib/services/api_service.dart` to `http://127.0.0.1:8000`

---

## What the app can do right now

| Feature | Status |
|---------|--------|
| Show top ranked stocks (daily / monthly / yearly) | ✅ |
| Single stock detail with factor breakdown | ✅ |
| Confidence + rationale | ✅ |
| Modern dark UI | ✅ |
| Read-only guarantee (no order endpoints) | ✅ |
| Live Kotak WebSocket | Ready (needs your credentials) |
| Real historical backtest | Ready (needs real candles in DB) |

---

## Security guarantees

1. FastAPI has **no** POST/PUT/DELETE order routes (they return 403).
2. Flutter `ApiService` only calls `GET` endpoints.
3. Every recommendation carries an explicit disclaimer.
4. UI banner states: “Analytical only • Never places buy/sell orders”.

---

## Next steps after you can run the UI

1. Put your Kotak token + TOTP secret in `backend/.env`
2. Run the ingestion demo to pull live ticks
3. Load historical candles into TimescaleDB
4. Run the backtest harness on real data
5. Only after gates pass → treat the rankings as usable signals
