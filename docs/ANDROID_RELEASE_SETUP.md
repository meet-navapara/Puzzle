# Android release setup (PetalGrid)

## Signing

Release signing reads `android/key.properties` (gitignored). Start from
`android/key.properties.example`. Without that file a release build falls back to
debug signing, prints a warning, and Google Play rejects the upload.
`dart run tool/release_check.dart` catches this.

## Build

```
cd c:\Puzzle\Puzzle
flutter pub get
dart run tool/release_check.dart
flutter build appbundle --release
```

- AAB for Play: `build/app/outputs/bundle/release/app-release.aab`
- APK for sideloading: `flutter build apk --release`, output in `build/app/outputs/flutter-apk/`

## SHA-1 fingerprints

Google Sign-In needs each signing key's SHA-1 in Firebase: debug, upload, and Play
App Signing. See `docs/OWNER_CHECKLIST.md` step 3.

## Platform requirements

| Requirement | Status |
| --- | --- |
| Target API 36 (Play requires it from 31 Aug 2026) | Set by Flutter (`flutter.targetSdkVersion`) |
| Minimum API | 26 |
| 16 KB memory pages | See `docs/VALIDATION_RESULTS.md` |
| Edge-to-edge | Flutter handles it; screens use `SafeArea` |
| Orientation | Portrait on phones. Android 16 ignores the lock on large screens, so layouts are tested in landscape too |
