# PetalGrid: release guide

| Field | Value |
| --- | --- |
| Display name | **PetalGrid** |
| Android applicationId | `com.petalgrid.game` |
| Signature mechanic | **Bloom Charge / Bloom Prune** |

**Publishing steps:** `docs/OWNER_CHECKLIST.md`
**Listing text and graphics:** `docs/STORE_LISTING.md`
**Play Console answers:** `docs/PLAY_CONSOLE_DATA_SAFETY.md`
**Signing and build:** `docs/ANDROID_RELEASE_SETUP.md`

## iOS

Not part of this release. It needs a Mac, Xcode, an iOS Firebase app
(`firebase_options.dart` throws on iOS today), Sign in with Apple review, and real
iOS ad IDs.

## Known limitations

- An internet connection is required to play (`AppConfig.requireInternetForPlay`).
  Set it to false to allow offline play; ads and cloud save then simply wait.
- Petals are client-side. Firestore rules bound values but can't stop cheating;
  a competitive economy would need server-side checks.
- Difficulty was tuned with a bot, not with players. Watch where testers get stuck
  during the closed test and retune `LevelGenerator`.
