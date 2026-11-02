# Validation results

Last run: 2026-10-31, Flutter 3.47.7, Pixel 8a on Android 17.

## Automated

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues |
| `flutter test` | 131 passing |
| Every one of the 768 campaign sections won by the solver bot on its in-game deal | Pass (108 sections use a recorded alternate deal) |
| Layouts at 320×568, 390×844, 800×1280 and 1280×800 | No overflows |
| Saves from the 50-level version | Migrate; level 51 unlocks |

## Difficulty

A bot, not people. "Careless" makes a random move 30% of the time and uses no Bloom,
petals or rescues, so real players have more tools. Treat this as the shape of the
curve, and retune from what closed testers actually do.

| World | Careless win rate |
| --- | --- |
| Verdant Grove | 82% |
| Crystal Harbor | 85% |
| Sunpetal Dunes | 62% |
| Ember Workshop | 61% |
| Mistwood Hollow | 47% |
| Coral Lagoon | 50% |
| Frostglass Peaks | 34% |
| Lunar Observatory | 29% |
| Stormroot Highlands | 22% |
| Celestial Conservatory | 25% |

## Release build

| Check | Result |
| --- | --- |
| R8 release APK and AAB build | Pass (debug-signed: no upload key available yet) |
| Target SDK / min SDK | 36 / 26 |
| 16 KB page alignment of 64-bit native libraries | Pass |
| Installed over the previous build on a real phone, keeping its save | Pass |
| Login screen shown after that upgrade | Pass |
| Consent step, then test ads load, no crash in release | Pass (from device log) |
| Google account chooser opens from the login button | Pass |

## Played on the phone (release build)

All passed: login screen; Terms and Privacy links open Chrome and return; Play as
Guest; save kept across the upgrade; world map; level grid; drag-and-drop; tap to
place; a triple-line clear; 3 stars and petals on level complete; system back to
pause; Menu then Continue Garden resumes the same board; a full rewarded test ad
granting its petals once; no second ad stacking afterwards.

## Not yet verified on a device

- Completing Google sign-in. The chooser opens, but its account rows are hidden from
  screen capture, so a person must pick one. The phone's log shows `BadAuthentication`
  from Google services, so a Google account on it may need signing in again.
- Delete account, with a real account. It is irreversible, so it needs a throwaway
  account and your go-ahead.
- Interstitial and app-open ads on screen (rules are unit-tested; both load)
- Level 500 and the victory screen on a device (covered by automated tests)
- The consent form itself, which needs a published AdMob message and an EEA/UK test
- Production ads, signing, and sign-in under Play App Signing, which need your accounts

## Real AdMob IDs (2 Nov 2026)

App `ca-app-pub-1959480289882936~8672528981`, rewarded and interstitial units set
with `tool/set_admob_ids.dart`. No app-open unit was created, so app-open ads are
off until one is added. The release build starts the ads SDK with the real app ID
and doesn't crash. This Pixel 8a is registered as a test device. AdMob currently
answers every request with HTTP 403: the AdMob app is new and not yet reviewed or
linked to a Play listing, so no ads, test or live, are served yet. Background retries
now stop after 5 failures instead of repeating every 16 seconds all session.
