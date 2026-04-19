import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }
enum TaskCategory { work, live }
enum RecurType { none, daily, weekdays, weekly, custom }

class SubTask {
  String title;
  bool done;
  SubTask({required this.title, this.done = false});

  Map<String, dynamic> toJson() => {'title': title, 'done': done};
  factory SubTask.fromJson(Map<String, dynamic> j) =>
      SubTask(title: j['title'] ?? '', done: j['done'] ?? false);
}

class Task {
  final String id;
  String title;
  String description;
  TaskPriority priority;
  bool isCompleted;
  final DateTime createdAt;
  TimeOfDay? dueTime;
  DateTime? dueDate;
  TaskCategory category;

  // Subtasks
  final List<SubTask> subtasks;

  // Tags
  final List<String> tags;

  // Recurring
  RecurType recurType;
  List<int> recurDays; // 1=Mon..7=Sun for custom

  // Analytics / reorder / focus
  DateTime? completedAt;
  int sortOrder;
  int focusMinutes; // minutes spent in focus mode on this task

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    required this.createdAt,
    this.category = TaskCategory.work,
    this.dueTime,
    this.dueDate,
    List<SubTask>? subtasks,
    List<String>? tags,
    this.recurType = RecurType.none,
    List<int>? recurDays,
    this.completedAt,
    this.sortOrder = 0,
    this.focusMinutes = 0,
  }) : subtasks = subtasks ?? [],
       tags = tags ?? [],
       recurDays = recurDays ?? [];

  int get xp {
    switch (priority) {
      case TaskPriority.high:   return 50;
      case TaskPriority.medium: return 25;
      case TaskPriority.low:    return 10;
    }
  }

  int get subtasksDone => subtasks.where((s) => s.done).length;
  double get subtaskProgress => subtasks.isEmpty ? 0.0 : subtasksDone / subtasks.length;

  String get recurLabel {
    switch (recurType) {
      case RecurType.none:     return '';
      case RecurType.daily:    return 'Daily';
      case RecurType.weekdays: return 'Weekdays';
      case RecurType.weekly:   return 'Weekly';
      case RecurType.custom:
        const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return recurDays.map((d) => days[d]).join(', ');
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority.index,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'category': category.index,
    'dueTimeH': dueTime?.hour,
    'dueTimeM': dueTime?.minute,
    'dueDate': dueDate?.toIso8601String(),
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
    'tags': tags,
    'recurType': recurType.index,
    'recurDays': recurDays,
    'completedAt': completedAt?.toIso8601String(),
    'sortOrder': sortOrder,
    'focusMinutes': focusMinutes,
  };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'] ?? '',
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    priority: TaskPriority.values[j['priority'] ?? 1],
    isCompleted: j['isCompleted'] ?? false,
    createdAt: j['createdAt'] != null
      ? DateTime.parse(j['createdAt']) : DateTime.now(),
    category: TaskCategory.values[j['category'] ?? 0],
    dueTime: (j['dueTimeH'] != null && j['dueTimeM'] != null)
      ? TimeOfDay(hour: j['dueTimeH'], minute: j['dueTimeM']) : null,
    dueDate: j['dueDate'] != null ? DateTime.parse(j['dueDate']) : null,
    subtasks: (j['subtasks'] as List?)
      ?.map((e) => SubTask.fromJson(Map<String, dynamic>.from(e)))
      .toList(),
    tags: (j['tags'] as List?)?.cast<String>(),
    recurType: RecurType.values[j['recurType'] ?? 0],
    recurDays: (j['recurDays'] as List?)?.cast<int>(),
    completedAt: j['completedAt'] != null
      ? DateTime.parse(j['completedAt']) : null,
    sortOrder: j['sortOrder'] ?? 0,
    focusMinutes: j['focusMinutes'] ?? 0,
  );
}
