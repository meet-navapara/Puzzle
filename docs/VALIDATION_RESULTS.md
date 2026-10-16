# Validation results (this environment)

Date: 2026-10-15  
Flutter: 3.47.7 · Dart: 3.13.5 · Windows

| Command | Result |
| --- | --- |
| `flutter pub get` | Pass |
| `dart format .` | Pass (formatted) |
| `flutter analyze` | Pass — No issues found |
| `flutter test` | Pass — **23/23** |
| `flutter build apk --release` | Pass — `build/app/outputs/flutter-apk/app-release.apk` (51.6MB) |
| `flutter build appbundle --release` | Attempted; may require owner approval / re-run |
| iOS archive / TestFlight | **Not run** (macOS/Xcode required) |

## Notes

- Release APK currently signed with **debug** keys (template default). Replace before Play upload.
- `google_mobile_ads` upgraded to **9.1.0** for Gradle 9 compatibility.
- Kotlin incremental compilation disabled in `android/gradle.properties` to avoid Windows cache-lock failures.
- Firebase remains gated (`AppConfig.firebaseEnabled = false`) until owner adds config files.
- Ad units are Google **test** IDs.
