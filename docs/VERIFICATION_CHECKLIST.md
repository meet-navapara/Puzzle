# Verification checklist (after release setup)

## A. Local files (do not commit secrets)

1. Confirm these exist on disk:
   - `android/keystore/petalgrid-upload.jks`
   - `android/keystore/CREDENTIALS.txt`
   - `android/key.properties`
2. **Back up** `CREDENTIALS.txt` + `.jks` to a password manager / offline drive today.
3. Confirm git ignores them:
   ```bash
   git check-ignore -v android/key.properties android/keystore/petalgrid-upload.jks
   ```
   Both should show as ignored.

## B. Launcher icon

1. Uninstall any old PetalGrid debug build from the phone.
2. Install a fresh debug or release build.
3. Home screen icon should show the green petal flower (not the default Flutter logo).

## C. Firebase — add release SHA-1

1. Open Firebase → Project settings → Android app `com.petalgrid.game`
2. Add fingerprint:
   ```
   BE:EB:94:E9:1B:3A:2D:A9:3E:CC:86:53:E2:52:0B:6C:9A:B8:41:F5
   ```
3. Download new `google-services.json` → replace `android/app/google-services.json`
4. Rebuild the app

## D. Release build

```bash
cd c:\Puzzle\Puzzle
flutter clean
flutter pub get
flutter build apk --release
```

1. Install: `flutter install --release` or copy `build/app/outputs/flutter-apk/app-release.apk`
2. Confirm app opens (Firebase init OK)
3. Google Sign-In works on this release build
4. Settings → Delete account still works (re-auth prompt)

## E. Play-facing URLs (browser)

Open and confirm:

- https://petalgrid-e7287.web.app/privacy.html
- https://petalgrid-e7287.web.app/terms.html
- https://petalgrid-e7287.web.app/support.html (email navaparameetdev@gmail.com)
- https://petalgrid-e7287.web.app/delete-account.html

## F. Still deferred (not part of this setup)

- [ ] Real AdMob IDs + turn off `adsUseTestIds`
- [ ] UMP consent
- [ ] Play Console forms + screenshots
- [ ] Legal entity name

## G. Optional AAB for Play Internal testing

```bash
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console → Internal testing.
