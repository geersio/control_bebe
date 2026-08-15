import 'enums.dart';

/// Registro activo del cronómetro de lactancia (solo local).
class LactationTimer {
  final int? id;
  final LactationSide side;
  final DateTime startedAt;
  final int totalPausedMs;
  final DateTime? pausedAt;

  LactationTimer({
    this.id,
    required this.side,
    required this.startedAt,
    this.totalPausedMs = 0,
    this.pausedAt,
  });

  bool get isPaused => pausedAt != null;

  Duration get elapsed {
    final now = DateTime.now();
    var paused = Duration(milliseconds: totalPausedMs);
    if (pausedAt != null) {
      paused += now.difference(pausedAt!);
    }
    final raw = now.difference(startedAt) - paused;
    return raw.isNegative ? Duration.zero : raw;
  }

  LactationTimer copyWith({
    int? id,
    LactationSide? side,
    DateTime? startedAt,
    int? totalPausedMs,
    DateTime? pausedAt,
    bool clearPausedAt = false,
  }) {
    return LactationTimer(
      id: id ?? this.id,
      side: side ?? this.side,
      startedAt: startedAt ?? this.startedAt,
      totalPausedMs: totalPausedMs ?? this.totalPausedMs,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
    );
  }
}
