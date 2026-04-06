import 'package:flutter/foundation.dart';

class GameState extends ChangeNotifier {
  static final GameState instance = GameState._();
  GameState._();

  int _totalXp = 0;
  int _level   = 1;

  // Streak tracking
  DateTime? _lastCompletionDate;
  int _streak = 0;

  int get totalXp => _totalXp;
  int get level   => _level;
  int get streak  => _streak;

  /// XP required to go from level [l] to level [l+1].
  static int xpForLevel(int l) => l * 100; // 100, 200, 300 …

  int get _xpAtLevelStart {
    int acc = 0;
    for (int l = 1; l < _level; l++) { acc += xpForLevel(l); }
    return acc;
  }

  int    get xpInLevel       => _totalXp - _xpAtLevelStart;
  int    get xpForNextLevel  => xpForLevel(_level);
  double get levelProgress   => (xpInLevel / xpForNextLevel).clamp(0.0, 1.0);

  /// Record a task completion for streak tracking.
  void recordCompletion() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (_lastCompletionDate == null) {
      _streak = 1;
    } else {
      final lastDate = DateTime(
        _lastCompletionDate!.year,
        _lastCompletionDate!.month,
        _lastCompletionDate!.day,
      );
      final diff = todayDate.difference(lastDate).inDays;
      if (diff == 1) {
        _streak++;
      } else if (diff > 1) {
        _streak = 1;
      }
      // diff == 0 → same day, streak stays
    }
    _lastCompletionDate = todayDate;
    notifyListeners();
  }

  /// Add [xp] and return true if leveled up.
  bool addXp(int xp) {
    _totalXp += xp;
    bool up = false;
    while (xpInLevel >= xpForNextLevel) {
      _level++;
      up = true;
    }
    notifyListeners();
    return up;
  }
}
