# PetalGrid

Original Flutter block-placement puzzle for Android and iOS.

Plant polyomino pieces on a garden board, bloom completed rows and columns, chain combos, and spend **Bloom Charge** to prune a stuck cell. Includes Classic high-score mode and a finite **50-level** campaign across five worlds.

> **Name note:** The working title *BlockBloom* conflicts with pending trademarks and existing store apps. This project ships as **PetalGrid**. Spot checks are not legal clearance.

## Quick start

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Release & owner checklist](docs/RELEASE.md)
- [Store listing draft](docs/STORE_LISTING.md)
- [Asset inventory](docs/ASSET_INVENTORY.md)
- [Firestore rules](firestore/security.rules)

## Configuration gates

Firebase is enabled for Android (`firebaseEnabled = true`). Ads still use Google **test** unit IDs until production AdMob IDs are added. See `docs/ANDROID_RELEASE_SETUP.md` and `docs/PLAY_CONSOLE_DATA_SAFETY.md`.

## Project layout

```
lib/game/       # Pure puzzle rules
lib/campaign/   # 50 levels + progression
lib/services/   # Saves, auth, ads, connectivity
lib/ui/         # Screens + board widgets
test/           # Unit + widget tests
```
