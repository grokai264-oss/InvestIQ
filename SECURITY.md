# InvestIQ Security

## Secrets policy

- **Never** commit Kotak credentials, TOTP secrets, MPINs, session tokens, or private keys.
- All secrets live only in the host environment (Render Environment Variables).
- Flutter must never receive broker secrets (`--dart-define`, assets, or source).

Required Render env vars (names only):

```
KOTAK_CONSUMER_KEY
KOTAK_MOBILE
KOTAK_UCC
KOTAK_MPIN
KOTAK_TOTP_SECRET
```

Optional later: `REDIS_*`, `POSTGRES_DSN`, `JWT_SECRET_KEY`.

## If a secret was ever committed

1. **Rotate immediately** in the Kotak Neo developer portal (revoke tokens, new consumer key, new TOTP if needed, change MPIN).
2. Enable **GitHub Secret Scanning** and **Push Protection** on this repository.
3. Purge history (example):

```bash
# Prefer git-filter-repo or BFG
bfg --delete-files .env
# or
git filter-repo --path backend/.env --invert-paths
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push origin --force --all
```

4. Assume any historical token is compromised.

## Portfolio endpoint

The app is designed as a **single-user private research tool**.

- `/api/v1/portfolio/summary` must never be publicly callable without authentication if the deployment is shared.
- Preferred: network restriction, private service, or authenticated user-scoped vault before multi-user.
- Flutter currently does not send auth headers; treat the deployed portfolio path as owner-only until auth is added.

## Client surface

- No order / trade / place_order APIs.
- Read-only analytical signals only.
- Display name and watchlist stay on-device (`shared_preferences`).

## Reporting

If you discover a credential exposure or auth gap, rotate secrets first, then fix the code path.
