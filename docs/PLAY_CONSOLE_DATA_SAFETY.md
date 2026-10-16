# Play Console — Data Safety / App content (PetalGrid)

Use with package `com.petalgrid.game`. Support email: **navaparameetdev@gmail.com**.

## URLs to paste

| Field | URL |
| --- | --- |
| Privacy policy | https://petalgrid-e7287.web.app/privacy.html |
| Terms (optional) | https://petalgrid-e7287.web.app/terms.html |
| Support | https://petalgrid-e7287.web.app/support.html |
| **Account deletion** | https://petalgrid-e7287.web.app/delete-account.html |

## Audience

- **Target audience:** General (not designed for children / not Families)
- Do **not** check “Designed for children” unless you implement Families ads policies

## Ads

- App contains ads: **Yes** (Google Mobile Ads)
- While developing: `adsUseTestIds = true` + test APPLICATION_ID (safe)
- Before production release: replace with real AdMob IDs, set `adsUseTestIds = false`, add UMP for EEA/UK
- Never click your own live ads

## Data collected (declare honestly)

| Data type | Collected? | Shared? | Purpose |
| --- | --- | --- | --- |
| Email address | Yes (via Google Sign-In, optional) | Shared with Google/Firebase as processor | Account management |
| User IDs | Yes (Firebase UID, guest id) | Firebase | App functionality / cloud save |
| App activity / gameplay progress | Yes (saves, scores) | Firestore when signed in | App functionality |
| Device or other IDs (Advertising ID) | Yes when ads enabled | AdMob | Advertising |

Not collected for core play: precise location, contacts, photos, mic, SMS, health, financial info.

## Account deletion (App content)

- Users can delete in-app (Settings / Privacy) after Google re-auth
- Web path: account deletion URL above + email navaparameetdev@gmail.com
- Deletes Auth user + `users/{uid}` + local data on that device

## Still required before upload (not done by this doc)

1. Real AdMob production credentials (keep test for now per owner)
2. UMP consent when serving personalized ads in EEA/UK
3. Release signing keystore (not debug)
4. Original launcher icon / branding
5. Content rating questionnaire
