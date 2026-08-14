# InvestIQ

**Read-only** multi-horizon stock recommendation system powered by Kotak Neo live data + institutional factors.

Backend (Python + FastAPI) + modern Flutter dashboard.

> ⚠️ **This app NEVER places, modifies, or cancels any orders on Kotak Neo or any broker.**  
> It only collects market data, computes factors, and shows analytical rankings.

---

## Download APK (Android)

1. Open the repo on GitHub: https://github.com/grokai264-oss/InvestIQ
2. Tap **Actions** (top menu)
3. Select workflow **Build APK**
4. Tap **Run workflow** → **Run workflow**
5. Wait 3–6 minutes for the green check
6. Open the completed run → scroll to **Artifacts**
7. Download **InvestIQ-APK**
8. Unzip and install `app-release.apk` on your phone

> First run may take longer. The workflow is triggered automatically on every push to `flutter_app/` as well.

---

## Repository Structure

```
InvestIQ/
├── .github/workflows/build-apk.yml   # APK builder
├── backend/                          # FastAPI (read-only)
│   ├── api/main.py
│   └── requirements.txt
├── flutter_app/                      # Flutter dashboard
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── services/                 # GET only
│   │   ├── widgets/
│   │   └── theme/
│   └── pubspec.yaml
└── docs/
```

---

## Quick Start (local)

### Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000
```

### Flutter
```bash
cd flutter_app
flutter pub get
flutter run
```

---

## Security

- No buy/sell/order endpoints exist (any attempt returns 403)
- Flutter only uses GET requests
- Every screen shows an analytical-only disclaimer
