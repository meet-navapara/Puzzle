# Android release setup (PetalGrid)

## What was configured locally

- Upload keystore: `android/keystore/petalgrid-upload.jks` (gitignored)
- Credentials backup: `android/keystore/CREDENTIALS.txt` (gitignored) — **back this up offline**
- `android/key.properties` (gitignored)
- Release signing wired in `android/app/build.gradle.kts`
- Launcher icons generated from `assets/branding/app_icon.png`

## Release SHA-1 (required for Google Sign-In on release builds)

```
BE:EB:94:E9:1B:3A:2D:A9:3E:CC:86:53:E2:52:0B:6C:9A:B8:41:F5
```

1. Firebase Console → Project settings → Android app `com.petalgrid.game`
2. Add fingerprint → paste SHA-1 above
3. Download fresh `google-services.json` → replace `android/app/google-services.json`

## Build signed artifacts

```bash
cd c:\Puzzle\Puzzle
flutter clean
flutter pub get
flutter build appbundle --release
flutter build apk --release
```

Outputs:
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

## Still deferred (owner)

- Production AdMob IDs + `adsUseTestIds = false`
- UMP consent for EEA/UK
- Play Console Data Safety / content rating / screenshots
- Legal entity name in Play listing
