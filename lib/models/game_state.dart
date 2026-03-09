import 'package:flutter/foundation.dart';

class GameState extends ChangeNotifier {
  static final GameState instance = GameState._();
  GameState._();

  int _totalXp = 0;
  int _level   = 1;

  int get totalXp => _totalXp;
  int get level   => _level;

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
