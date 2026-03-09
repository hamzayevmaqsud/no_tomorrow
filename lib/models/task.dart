import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }
enum TaskCategory { work, live }

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
  });

  int get xp {
    switch (priority) {
      case TaskPriority.high:   return 50;
      case TaskPriority.medium: return 25;
      case TaskPriority.low:    return 10;
    }
  }
}
