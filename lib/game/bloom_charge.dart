import 'package:flutter/foundation.dart';

import '../core/app_config.dart';

/// Signature mechanic: Bloom Charge.
///
/// Earn progress from cleared cells. Each full charge enables one
/// **Bloom Prune** — remove a single filled cell from the board.
@immutable
class BloomState {
  const BloomState({
    this.charges = 0,
    this.progress = 0,
    this.totalPrunesUsed = 0,
  });

  final int charges;
  final int progress;
  final int totalPrunesUsed;

  int get progressNeeded => AppConfig.bloomChargePerClearCells;
  int get maxCharges => AppConfig.bloomMaxCharges;
  bool get canPrune => charges > 0;

  BloomState addClearedCells(int count) {
    if (count <= 0) return this;
    var prog = progress + count;
    var ch = charges;
    while (prog >= progressNeeded && ch < maxCharges) {
      prog -= progressNeeded;
      ch++;
    }
    if (ch >= maxCharges) {
      prog = prog.clamp(0, progressNeeded - 1);
    }
    return BloomState(
      charges: ch,
      progress: prog,
      totalPrunesUsed: totalPrunesUsed,
    );
  }

  BloomState? spendCharge() {
    if (charges <= 0) return null;
    return BloomState(
      charges: charges - 1,
      progress: progress,
      totalPrunesUsed: totalPrunesUsed + 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'charges': charges,
    'progress': progress,
    'prunes': totalPrunesUsed,
  };

  factory BloomState.fromJson(Map<String, dynamic> json) => BloomState(
    charges: json['charges'] as int? ?? 0,
    progress: json['progress'] as int? ?? 0,
    totalPrunesUsed: json['prunes'] as int? ?? 0,
  );
}
