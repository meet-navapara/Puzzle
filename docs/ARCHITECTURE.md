# PetalGrid architecture

## Layers

| Layer | Path | Responsibility |
| --- | --- | --- |
| Game rules | `lib/game/` | Board, pieces, scoring, bloom, engine (no widgets) |
| Campaign | `lib/campaign/` | 500 levels in 10 worlds, generator, progression, merge |
| Services | `lib/services/` | Local save, auth, cloud, ads, connectivity, audio, haptics |
| State | `lib/state/app_state.dart` | Navigation + orchestration |
| UI | `lib/ui/` | Theme, screens, board/tray widgets |
| Config | `lib/core/app_config.dart` | Feature flags, ad IDs, policy knobs |

## Scoring

- +1 per cell placed  
- +10 per line cleared  
- Multi-line bonus: `5 * lines * (lines - 1)`  
- Combo bonus: `8 * (combo - 1) * lines` when combo > 1  
- Bloom prune bonus: +2  

## Bloom Charge

Clear cells fill a meter (`bloomChargePerClearCells = 12`). Each full charge (max 3) enables **Bloom Prune**: remove one filled cell.

## Campaign

`CampaignCatalog` holds the worlds and hand-built levels 1–10; `LevelGenerator` deterministically builds 11–500 from the level id. Saves store progress only, and only for levels the player has reached. Completing level 500 sets `campaignComplete`.

**Objectives live in the engine.** `GameEngine` decides every win and loss, and a move that reaches the goal always wins, even if it also leaves the board dead. `SectionStarter` is the only path from a level definition to an engine run, so tests play exactly what players get.

**Fair deals.** A dealt tray always has a piece that fits. Each section has a fixed seed, so a retry deals the same pieces.

**Stars** rate moves against par: at par 3 stars, within 1.5× par 2 stars, otherwise 1. Survival sections have a fixed length, so they don't count, and no level opens on one.

**Changing levels.** `test/campaign/level_solvability_test.dart` has a bot play every section on its in-game seed, using no Bloom, petals or rescues. If it fails after a retune, run `flutter test test/campaign/calibration_report.dart` and paste the printed map into `LevelGenerator.seedOverrides`. The report also shows the difficulty curve per world.

**Migration.** `catalogVersion` marks saves from the old 50-level catalog. They keep cleared levels and petals, drop finale and world-reward flags, and get the next level unlocked. Mid-run campaign boards from older schemas are dropped because their level may have changed.

## Persistence

- Guest: `SharedPreferences` key `petalgrid_save_v1`
- Cloud: Firestore `users/{uid}`. Writes are batched (20 s after the last change, plus on level clear, backgrounding and sign-out) and cancelled before account deletion  
- Merge policy default: max progress + claimed flags (no double first-clear rewards)

## Ads

`AdsService` uses Google's test unit IDs until `adsUseTestIds` is false. Consent (UMP) runs before the SDK starts. Rewards are granted only after `onUserEarnedReward`.

`AdPolicy` holds the when-to-show rules. Full-screen ads are only shown if already loaded, never after waiting, so one can't land on top of a puzzle. Interstitials play after the player taps out of a finished level, starting after 5 clears and at most every 2 minutes. App-open ads need 30 s away from the app, a quiet menu screen, and no other recent ad.
