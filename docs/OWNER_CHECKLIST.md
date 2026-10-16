# Owner actions required before store release

## Identity & legal

- [ ] Confirm **PetalGrid** (or chosen final name) via trademark counsel / USPTO / EUIPO
- [ ] Host Privacy Policy, Terms, Support pages; put real URLs in `AppConfig`
- [ ] Decide audience (general vs Families/Kids) and ad/consent implications
- [ ] Provide support email and legal entity name for store listings

## Firebase

- [ ] Create Firebase project
- [ ] Add Android app `com.petalgrid.game` → download `google-services.json`
- [ ] Add iOS app → download `GoogleService-Info.plist`
- [ ] Enable Google Sign-In provider
- [ ] Create Firestore database
- [ ] Deploy `firestore/security.rules`
- [ ] Set `AppConfig.firebaseEnabled = true`
- [ ] Add FlutterFire options / initialize Firebase in `main.dart`

## AdMob

- [ ] Create AdMob apps for Android/iOS
- [ ] Create rewarded, interstitial, app-open units
- [ ] Replace test IDs in `AppConfig` + AndroidManifest + Info.plist
- [ ] Configure UMP / consent where required
- [ ] Never click your own live ads

## Android

- [ ] Create upload keystore; configure release signing (do not commit secrets)
- [ ] Replace launcher icon with original PetalGrid art
- [ ] `flutter build appbundle --release`
- [ ] Complete Play Console Data Safety, ads, rating questionnaires

## iOS (macOS required)

- [ ] Set bundle ID, signing team, Google URL scheme
- [ ] Replace icons / launch screen
- [ ] Archive + TestFlight
- [ ] App Privacy labels + account deletion declaration

## Audio / polish

- [ ] Add original SFX under `assets/audio/` and wire `AudioService`
- [ ] Optional: original music loop with mute respect
