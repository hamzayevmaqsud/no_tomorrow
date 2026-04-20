import 'package:flutter/material.dart';

enum HabitCategory { health, mindset, productivity, social }

Color habitCatColor(HabitCategory c) {
  switch (c) {
    case HabitCategory.health:       return const Color(0xFF22C55E);
    case HabitCategory.mindset:      return const Color(0xFF8B5CF6);
    case HabitCategory.productivity: return const Color(0xFFFF6B35);
    case HabitCategory.social:       return const Color(0xFF3B82F6);
  }
}

String habitCatLabel(HabitCategory c) {
  switch (c) {
    case HabitCategory.health:       return 'HEALTH';
    case HabitCategory.mindset:      return 'MINDSET';
    case HabitCategory.productivity: return 'PRODUCTIVITY';
    case HabitCategory.social:       return 'SOCIAL';
  }
}

IconData habitCatIcon(HabitCategory c) {
  switch (c) {
    case HabitCategory.health:       return Icons.favorite_rounded;
    case HabitCategory.mindset:      return Icons.psychology_rounded;
    case HabitCategory.productivity: return Icons.bolt_rounded;
    case HabitCategory.social:       return Icons.people_rounded;
  }
}

// ── Routine slots ────────────────────────────────────────────────────────────

class RoutineSlot {
  final String key;
  final String labelEn;
  final String labelRu;
  final IconData icon;
  const RoutineSlot(this.key, this.labelEn, this.labelRu, this.icon);
}

const List<RoutineSlot> kRoutineSlots = [
  RoutineSlot('morning',     'MORNING',      'УТРО',        Icons.wb_sunny_rounded),
  RoutineSlot('afternoon',   'AFTERNOON',    'ДЕНЬ',        Icons.light_mode_rounded),
  RoutineSlot('evening',     'EVENING',      'ВЕЧЕР',       Icons.wb_twilight_rounded),
  RoutineSlot('night',       'NIGHT',        'НОЧЬ',        Icons.nightlight_round),
  RoutineSlot('beforeSleep', 'BEFORE SLEEP', 'ПЕРЕД СНОМ',  Icons.bedtime_rounded),
];

RoutineSlot? findRoutineSlot(String key) {
  for (final s in kRoutineSlots) {
    if (s.key == key) return s;
  }
  return null;
}

IconData routineSlotIcon(String key) =>
    findRoutineSlot(key)?.icon ?? Icons.all_inclusive_rounded;

class Habit {
  final String id;
  String title;
  HabitCategory category;
  final DateTime createdAt;

  /// Which dates this habit was checked in
  final Set<String> completedDates; // "2026-04-06" format

  /// Notes per check-in date
  final Map<String, String> notes; // "2026-04-06" → "felt great"

  // Schedule: which days of week (1=Mon..7=Sun), empty=every day
  final List<int> scheduleDays;

  // Routine type
  String routineSlot; // 'morning', 'evening', '' (none)

  // Streak freeze
  int streakFreezes; // available freezes

  // Timer (minutes, 0 = no timer)
  int timerMinutes;

  Habit({
    required this.id,
    required this.title,
    this.category = HabitCategory.health,
    required this.createdAt,
    Set<String>? completedDates,
    Map<String, String>? notes,
    List<int>? scheduleDays,
    this.routineSlot = '',
    this.streakFreezes = 0,
    this.timerMinutes = 0,
  }) : completedDates = completedDates ?? {},
       notes = notes ?? {},
       scheduleDays = scheduleDays ?? [];

  /// Whether this habit is scheduled for today
  bool isScheduledToday() {
    if (scheduleDays.isEmpty) return true; // every day
    return scheduleDays.contains(DateTime.now().weekday);
  }

  String get scheduleLabel {
    if (scheduleDays.isEmpty) return 'Every day';
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return scheduleDays.map((d) => days[d]).join(', ');
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String dateKeyPublic(DateTime d) => _dateKey(d);

  bool isDoneToday() {
    return completedDates.contains(_dateKey(DateTime.now()));
  }

  void toggleToday() {
    final key = _dateKey(DateTime.now());
    if (completedDates.contains(key)) {
      completedDates.remove(key);
    } else {
      completedDates.add(key);
    }
  }

  /// Current streak (consecutive days ending today or yesterday)
  int get streak {
    final now = DateTime.now();
    int count = 0;
    var check = DateTime(now.year, now.month, now.day);
    // If not done today, start from yesterday
    if (!completedDates.contains(_dateKey(check))) {
      check = check.subtract(const Duration(days: 1));
    }
    while (completedDates.contains(_dateKey(check))) {
      count++;
      check = check.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// How many of the last 7 days were completed
  int get weeklyCount {
    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      if (completedDates.contains(_dateKey(d))) count++;
    }
    return count;
  }

  /// Number of days in the last 7 that are actually scheduled
  /// (if no schedule is set, all 7 are scheduled).
  int get scheduledInWeek {
    if (scheduleDays.isEmpty) return 7;
    final now = DateTime.now();
    int n = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      if (scheduleDays.contains(d.weekday)) n++;
    }
    return n;
  }

  /// Completions in the last 7 days that landed on a scheduled day.
  int get weeklyScheduledDone {
    if (scheduleDays.isEmpty) return weeklyCount;
    final now = DateTime.now();
    int n = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      if (scheduleDays.contains(d.weekday) &&
          completedDates.contains(_dateKey(d))) n++;
    }
    return n;
  }

  int get xpPerCheck => 15;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.index,
    'createdAt': createdAt.toIso8601String(),
    'completedDates': completedDates.toList(),
    'notes': notes,
    'scheduleDays': scheduleDays,
    'routineSlot': routineSlot,
    'streakFreezes': streakFreezes,
    'timerMinutes': timerMinutes,
  };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
    id: j['id'] ?? '',
    title: j['title'] ?? '',
    category: HabitCategory.values[j['category'] ?? 0],
    createdAt: j['createdAt'] != null
      ? DateTime.parse(j['createdAt']) : DateTime.now(),
    completedDates: (j['completedDates'] as List?)?.cast<String>().toSet(),
    notes: (j['notes'] as Map?)?.map((k, v) => MapEntry(k as String, v as String)),
    scheduleDays: (j['scheduleDays'] as List?)?.cast<int>(),
    routineSlot: j['routineSlot'] ?? '',
    streakFreezes: j['streakFreezes'] ?? 0,
    timerMinutes: j['timerMinutes'] ?? 0,
  );
}

class HabitStore {
  static final List<Habit> habits = [];
  static int nextId = 1;
}

/// A routine is an ordered sequence of habit IDs
class Routine {
  final String id;
  String name;
  String slot; // 'morning' or 'evening'
  final List<String> habitIds;

  Routine({required this.id, required this.name, this.slot = 'morning',
    List<String>? habitIds}) : habitIds = habitIds ?? [];
}

class RoutineStore {
  static final List<Routine> routines = [];
  static int nextId = 1;

  /// Get morning habits in order
  static List<Habit> morningHabits() {
    final r = routines.where((r) => r.slot == 'morning').toList();
    if (r.isEmpty) return HabitStore.habits.where((h) => h.routineSlot == 'morning').toList();
    final ids = r.first.habitIds;
    return ids.map((id) => HabitStore.habits.firstWhere((h) => h.id == id,
        orElse: () => HabitStore.habits.first)).where((h) => HabitStore.habits.contains(h)).toList();
  }

  /// Get evening habits in order
  static List<Habit> eveningHabits() {
    final r = routines.where((r) => r.slot == 'evening').toList();
    if (r.isEmpty) return HabitStore.habits.where((h) => h.routineSlot == 'evening').toList();
    final ids = r.first.habitIds;
    return ids.map((id) => HabitStore.habits.firstWhere((h) => h.id == id,
        orElse: () => HabitStore.habits.first)).where((h) => HabitStore.habits.contains(h)).toList();
  }
}
