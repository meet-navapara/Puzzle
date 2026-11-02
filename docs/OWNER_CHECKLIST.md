# Publishing PetalGrid on Google Play

Everything the code can do is done. These steps need your accounts, so only you
can do them. Work top to bottom.

`dart run tool/release_check.dart` tells you what is still missing in the project.

## 1. Real ads (AdMob)

The app shows Google's test ads until you do this. Test ads earn nothing.

1. [AdMob](https://admob.google.com) → Apps → Add app → Android, "not yet listed".
2. Create three ad units: **Rewarded**, **Interstitial**, **App open**.
3. Run one command with the app ID and the three ad unit IDs, in this order:

   ```
   dart run tool/set_admob_ids.dart <app id ~> <rewarded /> <interstitial /> <app open />
   ```

   It checks the IDs, then switches off test ads and updates `app_config.dart`,
   `AndroidManifest.xml` and `public/app-ads.txt` together. A mismatched app ID in the
   manifest would crash the app on launch, which this prevents.
4. AdMob → Privacy & messaging → **GDPR** → create and publish a message for this
   app. The app already shows it to players in the EEA/UK and offers "Ad privacy
   choices" in Settings. Without a published message those players get no ads.
5. **app-ads.txt**: deploy it (step 4 below), and in Play Console set the store
   listing **Website** to `https://petalgrid-e7287.web.app`. AdMob looks for the file
   there; until it finds it, ad requests are limited.
6. Never tap your own live ads. Install the real-ads build on your phone once, run
   `adb logcat | grep setTestDeviceIds`, and paste the ID it prints into
   `AppConfig.ownerTestDeviceIds`. Your phone then always gets test ads.

## 2. Signing key

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Fill in the passwords and alias for your upload keystore. The example points at
   `C:\Users\mauli\upload-keystore.jks`; change it if that is not the key for this app.
3. Back up the keystore and passwords somewhere safe, away from this PC.

Print your key's SHA-1, needed in step 3:

```
keytool -list -v -keystore C:\Users\mauli\upload-keystore.jks
```

## 3. Google Sign-In for release builds

Firebase currently knows only the debug fingerprint, so "Continue with Google"
fails for release builds until you add the others.

1. Firebase Console → Project settings → Android app `com.petalgrid.game` → Add
   fingerprint → paste the upload key SHA-1 from step 2.
2. After your first upload: Play Console → Test and release → App integrity → App
   signing → copy the **App signing key SHA-1** → add it in Firebase the same way.
   Play re-signs the app, so this is the one real users' phones present.
3. Download the new `google-services.json` to `android/app/`.
4. Confirm in Firebase → Authentication that Google is enabled.

## 4. Publish the web pages and rules

The privacy policy changed, and app-ads.txt is new, so the hosted site must be updated.
Sign in with an account that can see petalgrid-e7287 (`firebase login:add`), then:

```
firebase deploy --only hosting --project petalgrid-e7287
```

## 5. Build

```
dart run tool/release_check.dart
flutter test
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab`. Every later upload needs
a higher build number: the number after `+` in `pubspec.yaml`.

## 6. Play Console

Create the app as a **Game**, free, then fill in the store listing and App content.
Copy-ready answers are in:

- `docs/STORE_LISTING.md`: name, descriptions, and graphics in `docs/store_assets/`
- `docs/PLAY_CONSOLE_DATA_SAFETY.md`: Data safety, ads, audience, account deletion

## 7. Closed test (personal developer accounts)

Personal accounts created after November 2023 must run a closed test with at least
**12 testers opted in for 14 days in a row** before they can apply for production.
Organization accounts are exempt. Check your own account's Dashboard, which states
what applies to you. Google then reviews a production access application.

Plan for this: it means at least two weeks between first upload and public release.

## Before you announce it

- Test the signed build from the closed-test link on a real phone: both login
  buttons, one level, one rewarded ad, Delete account.
- Check [USPTO](https://tmsearch.uspto.gov) and Play Store search for "PetalGrid";
  this project has only had informal spot checks of the name.
