import 'package:flutter/foundation.dart';
import '../l10n/app_locale.dart';

class GameState extends ChangeNotifier {
  static final GameState instance = GameState._();
  GameState._();

  int _totalXp = 0;
  int _level   = 1;
  int _totalCompletions = 0;

  // Streak tracking
  DateTime? _lastCompletionDate;
  int _streak = 0;
  int _bestStreak = 0;

  // Achievement tracking
  final Set<String> _unlockedBadges = {};

  int get totalXp => _totalXp;
  int get level   => _level;
  int get streak  => _streak;
  int get bestStreak => _bestStreak;
  int get totalCompletions => _totalCompletions;
  Set<String> get unlockedBadges => _unlockedBadges;

  // Daily quest — changes each day
  String get dailyQuest {
    final day = DateTime.now().day;
    final quests = [
      t('Complete 3 tasks', 'Выполни 3 задания'),
      t('Check in all habits', 'Отметь все привычки'),
      t('Log a workout', 'Запиши тренировку'),
      t('Read 10 pages', 'Прочитай 10 страниц'),
      t('Log all meals', 'Запиши все приёмы пищи'),
      t('Maintain your streak', 'Сохрани свою серию'),
      t('Earn 50 XP', 'Заработай 50 XP'),
      t('Complete a Critical task', 'Выполни важное задание'),
      t('Add a new habit', 'Добавь новую привычку'),
      t('Finish a workout fully', 'Заверши тренировку полностью'),
    ];
    return quests[day % quests.length];
  }

  int get dailyQuestXp => 25;

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
    }
    _lastCompletionDate = todayDate;
    _totalCompletions++;
    if (_streak > _bestStreak) _bestStreak = _streak;
    _checkBadges();
    notifyListeners();
  }

  void _checkBadges() {
    if (_totalCompletions >= 1)   _unlockedBadges.add('first_blood');
    if (_totalCompletions >= 10)  _unlockedBadges.add('grinding');
    if (_totalCompletions >= 50)  _unlockedBadges.add('machine');
    if (_totalCompletions >= 100) _unlockedBadges.add('centurion');
    if (_streak >= 3)  _unlockedBadges.add('streak_3');
    if (_streak >= 7)  _unlockedBadges.add('streak_7');
    if (_streak >= 30) _unlockedBadges.add('streak_30');
    if (_level >= 5)   _unlockedBadges.add('lvl_5');
    if (_level >= 10)  _unlockedBadges.add('lvl_10');
    if (_totalXp >= 500) _unlockedBadges.add('xp_500');
    if (_totalXp >= 1000) _unlockedBadges.add('xp_1000');
  }

  static const badgeInfo = {
    'first_blood': ('FIRST BLOOD', 'Complete your first task', '⚔️'),
    'grinding':    ('GRINDING',    'Complete 10 tasks',        '🔥'),
    'machine':     ('MACHINE',     'Complete 50 tasks',        '⚙️'),
    'centurion':   ('CENTURION',   'Complete 100 tasks',       '🏛️'),
    'streak_3':    ('ON FIRE',     '3-day streak',             '🔥'),
    'streak_7':    ('UNSTOPPABLE', '7-day streak',             '💎'),
    'streak_30':   ('LEGENDARY',   '30-day streak',            '👑'),
    'lvl_5':       ('RISING',      'Reach level 5',            '⭐'),
    'lvl_10':      ('ELITE',       'Reach level 10',           '🌟'),
    'xp_500':      ('HALF K',      'Earn 500 XP',              '💰'),
    'xp_1000':     ('THOUSAND',    'Earn 1000 XP',             '💎'),
  };

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

  // ── Profile / sync ──────────────────────────────────────────────────────────
  String? username;
  int avatarIndex = 0;

  static const avatarEmojis = [
    '😎', '🧑‍💻', '🦊', '🐺', '🦁', '🐉', '👑', '🎮',
    '⚔️', '🛡️', '🧙', '🥷', '🦸', '🧛', '🤖', '👽',
    '🔥', '💀', '🎯', '🌟', '🏆', '💎', '🦅', '🐍',
  ];

  String get avatarEmoji => avatarEmojis[avatarIndex % avatarEmojis.length];

  void setAvatar(int index) {
    avatarIndex = index;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'avatarIndex': avatarIndex,
    'totalXp': _totalXp,
    'level': _level,
    'totalCompletions': _totalCompletions,
    'lastCompletionDate': _lastCompletionDate?.toIso8601String(),
    'streak': _streak,
    'bestStreak': _bestStreak,
    'unlockedBadges': _unlockedBadges.toList(),
  };

  void loadFromJson(Map<String, dynamic> j) {
    username = j['username'] as String?;
    avatarIndex = j['avatarIndex'] ?? 0;
    _totalXp = j['totalXp'] ?? 0;
    _level = j['level'] ?? 1;
    _totalCompletions = j['totalCompletions'] ?? 0;
    _lastCompletionDate = j['lastCompletionDate'] != null
      ? DateTime.parse(j['lastCompletionDate']) : null;
    _streak = j['streak'] ?? 0;
    _bestStreak = j['bestStreak'] ?? 0;
    _unlockedBadges
      ..clear()
      ..addAll((j['unlockedBadges'] as List?)?.cast<String>() ?? []);
    notifyListeners();
  }

  void reset() {
    username = null;
    _totalXp = 0;
    _level = 1;
    _totalCompletions = 0;
    _lastCompletionDate = null;
    _streak = 0;
    _bestStreak = 0;
    _unlockedBadges.clear();
    notifyListeners();
  }
}
