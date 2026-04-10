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

class Habit {
  final String id;
  String title;
  HabitCategory category;
  final DateTime createdAt;

  /// Which dates this habit was checked in
  final Set<String> completedDates; // "2026-04-06" format

  // Schedule: which days of week (1=Mon..7=Sun), empty=every day
  final List<int> scheduleDays;

  // Routine type
  String routineSlot; // 'morning', 'evening', '' (none)

  Habit({
    required this.id,
    required this.title,
    this.category = HabitCategory.health,
    required this.createdAt,
    Set<String>? completedDates,
    List<int>? scheduleDays,
    this.routineSlot = '',
  }) : completedDates = completedDates ?? {},
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

  int get xpPerCheck => 15;
}

class HabitStore {
  static final List<Habit> habits = [];
  static int nextId = 1;
}
