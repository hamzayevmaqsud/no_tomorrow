import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppSection {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String description;

  const AppSection({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
  });
}

const List<AppSection> kSections = [
  AppSection(
    id: 'tasks',
    label: 'TASKS',
    icon: Icons.check_box_outlined,
    color: AppColors.tasks,
    description: 'Daily & recurring tasks',
  ),
  AppSection(
    id: 'habits',
    label: 'HABITS',
    icon: Icons.loop_rounded,
    color: AppColors.habits,
    description: 'Build better habits',
  ),
  AppSection(
    id: 'workouts',
    label: 'WORKOUT',
    icon: Icons.fitness_center_rounded,
    color: AppColors.workouts,
    description: 'Track your fitness',
  ),
  AppSection(
    id: 'abstain',
    label: 'ABSTAIN',
    icon: Icons.block_rounded,
    color: AppColors.abstinences,
    description: 'Break bad habits',
  ),
  AppSection(
    id: 'reading',
    label: 'READING',
    icon: Icons.menu_book_rounded,
    color: AppColors.reading,
    description: 'Track your reading',
  ),
  AppSection(
    id: 'budget',
    label: 'BUDGET',
    icon: Icons.account_balance_wallet_rounded,
    color: AppColors.budget,
    description: 'Manage finances',
  ),
  AppSection(
    id: 'food',
    label: 'FOOD',
    icon: Icons.restaurant_rounded,
    color: AppColors.food,
    description: 'Track nutrition',
  ),
  AppSection(
    id: 'collect',
    label: 'COLLECT',
    icon: Icons.stars_rounded,
    color: AppColors.collection,
    description: 'Your achievements',
  ),
  AppSection(
    id: 'profile',
    label: 'PROFILE',
    icon: Icons.person_rounded,
    color: AppColors.profile,
    description: 'Your progress',
  ),
];
