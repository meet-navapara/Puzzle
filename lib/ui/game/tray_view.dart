import 'package:flutter/material.dart';

import '../../game/piece.dart';
import 'piece_visual.dart';

/// Tray of up to three pieces. Uses pan gestures (not [Draggable]) so
/// mid-drag parent rebuilds cannot freeze placement updates.
class TrayView extends StatelessWidget {
  const TrayView({
    super.key,
    required this.pieces,
    required this.selectedUid,
    required this.draggingUid,
    required this.onSelect,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.trayHeight = 108,
  });

  final List<TrayPiece> pieces;
  final String? selectedUid;
  final String? draggingUid;
  final void Function(TrayPiece piece) onSelect;
  final void Function(TrayPiece piece, Offset globalPosition) onDragStarted;
  final void Function(TrayPiece piece, Offset globalPosition) onDragUpdate;
  final void Function(TrayPiece piece) onDragEnd;
  final double trayHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: trayHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in pieces)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _TraySlot(
                  piece: p,
                  selected: p.uid == selectedUid,
                  dragging: p.uid == draggingUid,
                  onSelect: onSelect,
                  onDragStarted: onDragStarted,
                  onDragUpdate: onDragUpdate,
                  onDragEnd: onDragEnd,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TraySlot extends StatelessWidget {
  const _TraySlot({
    required this.piece,
    required this.selected,
    required this.dragging,
    required this.onSelect,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final TrayPiece piece;
  final bool selected;
  final bool dragging;
  final void Function(TrayPiece piece) onSelect;
  final void Function(TrayPiece piece, Offset globalPosition) onDragStarted;
  final void Function(TrayPiece piece, Offset globalPosition) onDragUpdate;
  final void Function(TrayPiece piece) onDragEnd;

  @override
  Widget build(BuildContext context) {
    if (piece.used) {
      return PieceVisual(piece: piece, maxExtent: 68, dimmed: true);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = constraints.maxWidth.clamp(56.0, 88.0);
        final visual = PieceVisual(
          piece: piece,
          maxExtent: extent,
          selected: selected,
          dimmed: dragging,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: dragging ? null : () => onSelect(piece),
          onPanStart: (details) {
            onDragStarted(piece, details.globalPosition);
          },
          onPanUpdate: (details) {
            onDragUpdate(piece, details.globalPosition);
          },
          onPanEnd: (_) => onDragEnd(piece),
          onPanCancel: () => onDragEnd(piece),
          child: Center(child: visual),
        );
      },
    );
  }
}
