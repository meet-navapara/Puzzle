import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../campaign/progression.dart';
import '../core/app_config.dart';
import 'local_save_service.dart';

enum CloudMergePolicy { keepLocal, keepCloud, mergeProgress }

class CloudSaveService {
  CloudSaveService({FirebaseFirestore? firestore}) : _db = firestore;

  FirebaseFirestore? _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    _db ??= FirebaseFirestore.instance;
    return _db!.collection('users').doc(uid);
  }

  Future<LocalSaveSnapshot?> fetch(String uid) async {
    if (!AppConfig.firebaseEnabled || Firebase.apps.isEmpty) return null;
    try {
      final snap = await _doc(uid).get();
      if (!snap.exists || snap.data() == null) return null;
      return LocalSaveSnapshot.fromJson(snap.data()!);
    } catch (e) {
      debugPrint('Cloud fetch failed: $e');
      return null;
    }
  }

  Future<bool> push(String uid, LocalSaveSnapshot snapshot) async {
    if (!AppConfig.firebaseEnabled || Firebase.apps.isEmpty) return false;
    try {
      final data = snapshot.toJson();
      data['uid'] = uid;
      data['schema'] = AppConfig.saveSchemaVersion;
      await _doc(uid).set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Cloud push failed: $e');
      return false;
    }
  }

  Future<bool> deleteCloudData(String uid) async {
    if (!AppConfig.firebaseEnabled || Firebase.apps.isEmpty) return false;
    try {
      await _doc(uid).delete();
      return true;
    } catch (e) {
      debugPrint('Cloud delete failed: $e');
      return false;
    }
  }

  static DateTime? _laterDaily(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  LocalSaveSnapshot resolveConflict({
    required LocalSaveSnapshot local,
    required LocalSaveSnapshot? cloud,
    required CloudMergePolicy policy,
  }) {
    if (cloud == null) return local;
    switch (policy) {
      case CloudMergePolicy.keepLocal:
        return local;
      case CloudMergePolicy.keepCloud:
        return LocalSaveSnapshot(
          schemaVersion: cloud.schemaVersion,
          settings: cloud.settings,
          campaign: cloud.campaign,
          classicBest: cloud.classicBest,
          activeGame: cloud.activeGame,
          guestId: local.guestId,
          linkedUid: cloud.linkedUid,
          updatedAt: DateTime.now().toUtc(),
          lastDailyClaimUtc: cloud.lastDailyClaimUtc,
        );
      case CloudMergePolicy.mergeProgress:
        return LocalSaveSnapshot(
          schemaVersion: AppConfig.saveSchemaVersion,
          settings: local.settings,
          campaign: CampaignProgression.merge(local.campaign, cloud.campaign),
          classicBest: local.classicBest > cloud.classicBest
              ? local.classicBest
              : cloud.classicBest,
          activeGame: local.activeGame ?? cloud.activeGame,
          guestId: local.guestId,
          linkedUid: local.linkedUid ?? cloud.linkedUid,
          updatedAt: DateTime.now().toUtc(),
          lastDailyClaimUtc: _laterDaily(
            local.lastDailyClaimUtc,
            cloud.lastDailyClaimUtc,
          ),
        );
    }
  }
}
