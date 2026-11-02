# Play Console: App content answers (PetalGrid)

Package `com.petalgrid.game`. Answer every question honestly; these reflect what the
code does today. If you add an SDK, revisit this page.

## URLs

| Field | URL |
| --- | --- |
| Privacy policy | https://petalgrid-e7287.web.app/privacy.html |
| Terms (optional) | https://petalgrid-e7287.web.app/terms.html |
| Support | https://petalgrid-e7287.web.app/support.html |
| Account deletion | https://petalgrid-e7287.web.app/delete-account.html |

## Ads

Does your app contain ads? **Yes.** (Google Mobile Ads: rewarded, interstitial, app open.)

Advertising ID: **Yes**, the app uses it. Purpose: **Advertising or marketing**.

## App access

**All functionality is available without special access.** Guest mode needs no
account, so reviewers do not need credentials.

## Target audience

Ages **13 and over** (select 13-15, 16-17, 18+). Do not select any age under 13: the
app's ad setup and consent flow are not built for child-directed traffic. Appeal to
children: **No**.

## Content rating (IARC questionnaire)

Category: **Game**. Answer **No** to violence, sexual content, profanity, drugs and
gambling. Users do not interact or share content; no location sharing. Purchases:
**none**. Expect a rating of Everyone / PEGI 3. Ads present is declared separately.

## News, COVID-19, government, financial, health

Not applicable: answer **No** to each.

## Data safety

Does your app collect or share required user data? **Yes.**
Is all data encrypted in transit? **Yes.**
Can users request deletion? **Yes**, in-app and at the account deletion URL above.

| Data type | Collected | Shared | Optional | Purpose |
| --- | --- | --- | --- | --- |
| Personal info → Email address | Yes | No | Yes (Google Sign-In only) | Account management |
| Personal info → User IDs | Yes | No | Yes (Google Sign-In only) | App functionality, Account management |
| App activity → Other actions (levels, scores) | Yes | No | Yes (cloud save when signed in) | App functionality |
| App info and performance → Diagnostics | Yes | Yes (Google Mobile Ads) | No | Advertising or marketing |
| Device or other IDs → Advertising ID | Yes | Yes (Google Mobile Ads) | No | Advertising or marketing, Fraud prevention and security |

Firebase and AdMob act for you as processors or per Google's own terms; check
[Google's AdMob Data safety guidance](https://developers.google.com/admob/android/privacy/play-data-disclosure)
when you fill this in, since it is updated with each SDK version.

Not collected: location, contacts, photos, microphone, SMS, health, financial info.
Guest progress stays on the device and is not collected.

## Account deletion

- In-app path: **Settings → Delete account & cloud data** (also under Privacy).
- Web path: the account deletion URL above, for people who no longer have the app.
- Deleted: Firebase Auth user, Firestore `users/{uid}`, and local data on that device.
- Guests: **Settings → Clear local data on this device**.

## Consent (EEA, UK, Switzerland)

The app shows Google's UMP consent form before any ad request where required, and
offers "Ad privacy choices" in Settings. You must publish the GDPR message in AdMob
for this to appear; see `docs/OWNER_CHECKLIST.md` step 1.
