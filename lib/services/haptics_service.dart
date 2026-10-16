import 'package:flutter/services.dart';

class HapticsService {
  bool enabled = true;

  Future<void> light() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> success() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> selection() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }
}
