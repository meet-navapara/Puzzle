import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../campaign/progression.dart';
import '../core/app_config.dart';
import '../game/game_engine.dart';
import '../core/theme_preference.dart';

class PlayerSettings {
  const PlayerSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
    this.reducedEffects = false,
    this.soundVolume = 0.8,
    this.musicVolume = 0.5,
    this.tutorialSeen = false,
    this.privacyAccepted = false,
    this.themePreference = AppThemePreference.dark,
    this.welcomeSeen = false,
    this.tutorialLevel1Done = false,
    this.tutorialLevel2Done = false,
    this.tutorialClassicDone = false,
    this.tutorialDailyDone = false,
  });

  final bool soundEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;
  final bool reducedEffects;
  final double soundVolume;
  final double musicVolume;
  final bool tutorialSeen;
  final bool privacyAccepted;
  final AppThemePreference themePreference;

  /// When true, cold start skips Welcome and opens Main Menu.
  final bool welcomeSeen;

  /// Interactive lesson on campaign level 1 has been finished or skipped.
  final bool tutorialLevel1Done;

  /// Interactive lesson on campaign level 2 has been finished or skipped.
  final bool tutorialLevel2Done;

  /// First Classic Garden visit has been guided or skipped.
  final bool tutorialClassicDone;

  /// First Daily Dew visit has been guided or skipped.
  final bool tutorialDailyDone;

  PlayerSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
    bool? reducedEffects,
    double? soundVolume,
    double? musicVolume,
    bool? tutorialSeen,
    bool? privacyAccepted,
    AppThemePreference? themePreference,
    bool? welcomeSeen,
    bool? tutorialLevel1Done,
    bool? tutorialLevel2Done,
    bool? tutorialClassicDone,
    bool? tutorialDailyDone,
  }) => PlayerSettings(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    reducedEffects: reducedEffects ?? this.reducedEffects,
    soundVolume: soundVolume ?? this.soundVolume,
    musicVolume: musicVolume ?? this.musicVolume,
    tutorialSeen: tutorialSeen ?? this.tutorialSeen,
    privacyAccepted: privacyAccepted ?? this.privacyAccepted,
    themePreference: themePreference ?? this.themePreference,
    welcomeSeen: welcomeSeen ?? this.welcomeSeen,
    tutorialLevel1Done: tutorialLevel1Done ?? this.tutorialLevel1Done,
    tutorialLevel2Done: tutorialLevel2Done ?? this.tutorialLevel2Done,
    tutorialClassicDone: tutorialClassicDone ?? this.tutorialClassicDone,
    tutorialDailyDone: tutorialDailyDone ?? this.tutorialDailyDone,
  );

  Map<String, dynamic> toJson() => {
    'sound': soundEnabled,
    'music': musicEnabled,
    'haptics': hapticsEnabled,
    'reduced': reducedEffects,
    'sVol': soundVolume,
    'mVol': musicVolume,
    'tutorial': tutorialSeen,
    'privacy': privacyAccepted,
    'theme': themePreference.name,
    'welcomeSeen': welcomeSeen,
    'tutorialL1': tutorialLevel1Done,
    'tutorialL2': tutorialLevel2Done,
    'tutorialClassic': tutorialClassicDone,
    'tutorialDaily': tutorialDailyDone,
  };

  factory PlayerSettings.fromJson(Map<String, dynamic> json) {
    final themeName = json['theme'] as String? ?? 'dark';
    final theme = AppThemePreference.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => AppThemePreference.dark,
    );
    return PlayerSettings(
      soundEnabled: json['sound'] as bool? ?? true,
      musicEnabled: json['music'] as bool? ?? true,
      hapticsEnabled: json['haptics'] as bool? ?? true,
      reducedEffects: json['reduced'] as bool? ?? false,
      soundVolume: (json['sVol'] as num?)?.toDouble() ?? 0.8,
      musicVolume: (json['mVol'] as num?)?.toDouble() ?? 0.5,
      tutorialSeen: json['tutorial'] as bool? ?? false,
      privacyAccepted: json['privacy'] as bool? ?? false,
      themePreference: theme,
      welcomeSeen: json['welcomeSeen'] as bool? ?? false,
      tutorialLevel1Done: json['tutorialL1'] as bool? ?? false,
      tutorialLevel2Done: json['tutorialL2'] as bool? ?? false,
      tutorialClassicDone: json['tutorialClassic'] as bool? ?? false,
      tutorialDailyDone: json['tutorialDaily'] as bool? ?? false,
    );
  }
}

class LocalSaveSnapshot {
  LocalSaveSnapshot({
    required this.schemaVersion,
    required this.settings,
    required this.campaign,
    required this.classicBest,
    this.activeGame,
    this.guestId,
    this.linkedUid,
    this.updatedAt,
    this.lastDailyClaimUtc,
  });

  final int schemaVersion;
  final PlayerSettings settings;
  final CampaignProgression campaign;
  final int classicBest;
  final GameState? activeGame;
  final String? guestId;
  final String? linkedUid;
  final DateTime? updatedAt;

  /// UTC midnight of the last Daily Dew claim day (null = never).
  final DateTime? lastDailyClaimUtc;

  LocalSaveSnapshot copyWith({
    int? schemaVersion,
    PlayerSettings? settings,
    CampaignProgression? campaign,
    int? classicBest,
    GameState? activeGame,
    String? guestId,
    String? linkedUid,
    DateTime? updatedAt,
    DateTime? lastDailyClaimUtc,
    bool clearActiveGame = false,
    bool clearDailyClaim = false,
    bool clearLinkedUid = false,
  }) => LocalSaveSnapshot(
    schemaVersion: schemaVersion ?? this.schemaVersion,
    settings: settings ?? this.settings,
    campaign: campaign ?? this.campaign,
    classicBest: classicBest ?? this.classicBest,
    activeGame: clearActiveGame ? null : (activeGame ?? this.activeGame),
    guestId: guestId ?? this.guestId,
    linkedUid: clearLinkedUid ? null : (linkedUid ?? this.linkedUid),
    updatedAt: updatedAt ?? this.updatedAt,
    lastDailyClaimUtc: clearDailyClaim
        ? null
        : (lastDailyClaimUtc ?? this.lastDailyClaimUtc),
  );

  Map<String, dynamic> toJson() => {
    'schema': schemaVersion,
    'settings': settings.toJson(),
    'campaign': campaign.toJson(),
    'classicBest': classicBest,
    'activeGame': activeGame?.toJson(),
    'guestId': guestId,
    'linkedUid': linkedUid,
    'updatedAt': (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    'lastDailyClaimUtc': lastDailyClaimUtc?.toIso8601String(),
  };

  factory LocalSaveSnapshot.fromJson(Map<String, dynamic> json) {
    final schema = json['schema'] as int? ?? 1;
    DateTime? daily;
    final rawDaily = json['lastDailyClaimUtc'] as String?;
    if (rawDaily != null) {
      final parsed = DateTime.tryParse(rawDaily);
      if (parsed != null) {
        daily = DateTime.utc(parsed.year, parsed.month, parsed.day);
      }
    }
    return LocalSaveSnapshot(
      schemaVersion: schema,
      settings: PlayerSettings.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      ),
      campaign: CampaignProgression.fromJson(
        Map<String, dynamic>.from(json['campaign'] as Map? ?? {}),
      ),
      classicBest: json['classicBest'] as int? ?? 0,
      activeGame: json['activeGame'] != null
          ? GameState.fromJson(
              Map<String, dynamic>.from(json['activeGame'] as Map),
            )
          : null,
      guestId: json['guestId'] as String?,
      linkedUid: json['linkedUid'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      lastDailyClaimUtc: daily,
    );
  }
}

class LocalSaveService {
  static const _key = 'petalgrid_save_v1';

  Future<LocalSaveSnapshot> loadOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final snap = LocalSaveSnapshot(
        schemaVersion: AppConfig.saveSchemaVersion,
        settings: const PlayerSettings(),
        campaign: CampaignProgression(null),
        classicBest: 0,
        guestId: guestId,
        updatedAt: DateTime.now().toUtc(),
      );
      await save(snap);
      return snap;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LocalSaveSnapshot.fromJson(map);
    } catch (_) {
      final snap = LocalSaveSnapshot(
        schemaVersion: AppConfig.saveSchemaVersion,
        settings: const PlayerSettings(),
        campaign: CampaignProgression(null),
        classicBest: 0,
        guestId: 'guest_recovered_${DateTime.now().millisecondsSinceEpoch}',
        updatedAt: DateTime.now().toUtc(),
      );
      await save(snap);
      return snap;
    }
  }

  Future<void> save(LocalSaveSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final withTime = snapshot.copyWith(updatedAt: DateTime.now().toUtc());
    await prefs.setString(_key, jsonEncode(withTime.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
