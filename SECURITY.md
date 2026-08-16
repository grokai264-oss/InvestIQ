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

Optional later: `REDIS_*`

## Portfolio access token (optional)

For single-user private deploys, set on Render:

```
PORTFOLIO_ACCESS_TOKEN=<long-random-secret>
```

Clients must send header:

```
X-InvestIQ-Token: <same-secret>
```

Comparison uses `secrets.compare_digest`. Do **not** embed this token in a public APK.

## Rotation

If any credential ever appeared in Git history, rotate it at the broker and purge history if needed.
Enable GitHub secret scanning and push protection.

## Product boundary

InvestIQ is a **read-only research desk**. It never places orders.
