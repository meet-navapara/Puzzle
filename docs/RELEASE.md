# PetalGrid — Release & Configuration Guide

## Game identity

| Field | Value |
| --- | --- |
| Display name | **PetalGrid** |
| Working title rejected | BlockBloom (trademark filings + existing store apps) |
| Android applicationId | `com.petalgrid.game` |
| iOS bundle id (default) | Configure in Xcode to `com.petalgrid.game` |
| Signature mechanic | **Bloom Charge / Bloom Prune** |

**Trademark note:** Spot checks found no exact “PetalGrid” mobile game, but this is **not** legal clearance. Verify USPTO, EUIPO, and store listing collisions before commercial launch.

---

## What you must supply before production

1. Firebase project + `google-services.json` (Android) + `GoogleService-Info.plist` (iOS)
2. Enable Authentication → Google provider
3. Create Firestore database; deploy `firestore/security.rules`
4. AdMob app + **production** ad unit IDs (replace Google test IDs in `lib/core/app_config.dart` and platform manifests)
5. Hosted Privacy Policy URL, Terms URL, Support URL/email
6. Android upload keystore (never commit)
7. Apple Developer account, provisioning, App Store Connect listing
8. Audience decision (general / mixed / kids) and UMP consent if required
9. Real package signing config for release AAB

Set `AppConfig.firebaseEnabled = true` only after Firebase options are installed.

---

## Android release

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

Signing: create `android/key.properties` (gitignored) and wire `signingConfigs` in `android/app/build.gradle.kts`. Do not commit keystores or passwords.

Play Console checklist: Data Safety, Ads declaration, Privacy Policy link, content rating, target API, screenshots, account deletion URL/path.

---

## iOS release (requires macOS + Xcode)

1. Open `ios/Runner.xcworkspace` on a Mac
2. Set Bundle Identifier to `com.petalgrid.game`
3. Add `GoogleService-Info.plist`
4. Configure URL schemes for Google Sign-In (reversed client ID)
5. Confirm `GADApplicationIdentifier` (replace test ID)
6. Archive → Distribute → TestFlight
7. App Privacy nutrition labels, account deletion, ATT if needed

This Windows environment cannot produce or validate an iOS archive.

---

## Firestore rules deployment

```bash
firebase deploy --only firestore:rules
```

Rules path: `firestore/security.rules`

Client rules cannot stop all cheating. Competitive economies need Cloud Functions / trusted servers.

---

## Store listing draft (owner fills legal entity)

**Name options:** PetalGrid · PetalGrid Gardens · PetalGrid: Block Garden

**Short description:** Plant blocks, bloom lines, and cultivate fifty original garden puzzles.

**Full description:** See `docs/STORE_LISTING.md`.

**Category:** Puzzle  
**Content rating:** Complete questionnaires honestly (ads present).

---

## Known limitations

- Firebase disabled until owner config (`firebaseEnabled = false`)
- Ad units are Google **test** IDs
- Audio uses system clicks until original SFX are added under `assets/audio/`
- Default launcher icon is Flutter placeholder — replace with original PetalGrid art
- Connectivity “open settings” is best-effort by platform
- iOS build/sign not executed on Windows
- UMP consent flow not fully wired — required for many regions before live ads
