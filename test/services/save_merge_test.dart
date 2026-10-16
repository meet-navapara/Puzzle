import 'dart:convert';

import 'package:block_garden/campaign/progression.dart';
import 'package:block_garden/core/app_config.dart';
import 'package:block_garden/services/cloud_save_service.dart';
import 'package:block_garden/services/local_save_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('save round-trip json', () {
    final daily = DateTime.utc(2026, 10, 15);
    final snap = LocalSaveSnapshot(
      schemaVersion: AppConfig.saveSchemaVersion,
      settings: const PlayerSettings(tutorialSeen: true, welcomeSeen: true),
      campaign: CampaignProgression(null)..petals = 12,
      classicBest: 99,
      guestId: 'guest_x',
      lastDailyClaimUtc: daily,
    );
    final encoded = jsonEncode(snap.toJson());
    final decoded = LocalSaveSnapshot.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    expect(decoded.classicBest, 99);
    expect(decoded.campaign.petals, 12);
    expect(decoded.settings.tutorialSeen, isTrue);
    expect(decoded.settings.welcomeSeen, isTrue);
    expect(decoded.guestId, 'guest_x');
    expect(decoded.lastDailyClaimUtc, daily);
  });

  test('cloud conflict merge policy', () {
    final local = LocalSaveSnapshot(
      schemaVersion: 1,
      settings: const PlayerSettings(),
      campaign: CampaignProgression(null)
        ..completeLevel(levelId: 1, score: 10, sectionsDone: 1),
      classicBest: 10,
      guestId: 'g1',
    );
    final cloud = LocalSaveSnapshot(
      schemaVersion: 1,
      settings: const PlayerSettings(),
      campaign: CampaignProgression(null)
        ..completeLevel(levelId: 1, score: 50, sectionsDone: 2)
        ..completeLevel(levelId: 2, score: 20, sectionsDone: 2),
      classicBest: 80,
      linkedUid: 'uid',
    );
    final service = CloudSaveService();
    final merged = service.resolveConflict(
      local: local,
      cloud: cloud,
      policy: CloudMergePolicy.mergeProgress,
    );
    expect(merged.classicBest, 80);
    expect(merged.campaign.progressOf(2).completed, isTrue);
    expect(merged.campaign.progressOf(1).bestScore, 50);
  });
}
