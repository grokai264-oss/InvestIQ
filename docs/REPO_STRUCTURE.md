# Exact File Placement Guide

Use this when creating the GitHub repository or when cloning on another machine.

```
InvestIQ/
│
├── README.md                          ← main documentation
├── .gitignore
│
├── backend/                           ← all Python code lives here
│   ├── api/
│   │   └── main.py                    ← FastAPI entry (uvicorn api.main:app)
│   ├── core/
│   │   ├── __init__.py
│   │   ├── recommendation.py
│   │   ├── factors/
│   │   │   ├── __init__.py
│   │   │   ├── technical.py
│   │   │   ├── institutional.py
│   │   │   └── scoring.py
│   │   └── backtest/
│   │       ├── __init__.py
│   │       ├── harness.py
│   │       └── metrics.py
│   ├── ingestion/
│   │   ├── __init__.py
│   │   ├── kotak_auth.py
│   │   ├── kotak_live.py
│   │   ├── kotak_historical.py
│   │   └── alternative_data.py
│   ├── storage/
│   │   ├── __init__.py
│   │   ├── schema.sql
│   │   ├── postgres.py
│   │   └── redis_store.py
│   ├── schemas/
│   │   └── stock.py
│   ├── config/
│   │   └── settings.py
│   ├── requirements.txt
│   ├── .env.example
│   ├── run_ingestion_demo.py
│   └── run_backtest_demo.py
│
├── flutter_app/
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── models/
│       │   └── recommendation.dart
│       ├── services/
│       │   └── api_service.dart       ← only GET calls
│       ├── screens/
│       │   ├── dashboard_screen.dart
│       │   └── stock_detail_screen.dart
│       ├── widgets/
│       │   ├── recommendation_card.dart
│       │   └── disclaimer_banner.dart
│       └── theme/
│           └── app_theme.dart
│
└── docs/
    └── REPO_STRUCTURE.md              ← this file
```

## Important naming conventions

| Item | Name |
|------|------|
| Backend package root | `backend/` |
| Flutter package name | `intelligent_stock_engine` (in pubspec.yaml) |
| API base path | `/api/v1/recommendations/...` |
| Never create | any file named `order`, `trade`, `place_order`, `buy`, `sell` that talks to Kotak |
