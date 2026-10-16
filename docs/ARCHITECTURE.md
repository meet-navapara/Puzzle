# PetalGrid architecture

## Layers

| Layer | Path | Responsibility |
| --- | --- | --- |
| Game rules | `lib/game/` | Board, pieces, scoring, bloom, engine (no widgets) |
| Campaign | `lib/campaign/` | 50 levels, worlds, progression, merge |
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

Static definitions in `CampaignCatalog`. Saves store progress only, not level JSON. Completing level 50 sets `campaignComplete`; level 51 is not generated.

## Persistence

- Guest: `SharedPreferences` key `petalgrid_save_v1`  
- Cloud: Firestore `users/{uid}` when Firebase enabled  
- Merge policy default: max progress + claimed flags (no double first-clear rewards)

## Ads

`AdsService` uses official Google test unit IDs. Rewards granted only after `onUserEarnedReward`. Interstitial/app-open frequency gated in `AppConfig`.
