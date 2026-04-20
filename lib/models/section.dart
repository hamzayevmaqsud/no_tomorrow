import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/app_locale.dart';

class AppSection {
  final String id;
  final String Function() _label;
  final IconData icon;
  final Color color;
  final String Function() _description;

  String get label => _label();
  String get description => _description();

  const AppSection({
    required this.id,
    required String Function() label,
    required this.icon,
    required this.color,
    required String Function() description,
  }) : _label = label, _description = description;
}

List<AppSection> get kSections => [
  AppSection(
    id: 'tasks',
    label: () => t('TASKS', 'ЗАДАНИЯ'),
    icon: Icons.check_box_outlined,
    color: AppColors.tasks,
    description: () => t('Daily & recurring tasks', 'Ежедневные задания'),
  ),
  AppSection(
    id: 'habits',
    label: () => t('HABITS', 'ПРИВЫЧКИ'),
    icon: Icons.loop_rounded,
    color: AppColors.habits,
    description: () => t('Build better habits', 'Формируй привычки'),
  ),
  AppSection(
    id: 'workouts',
    label: () => t('WORKOUT', 'ТРЕНИРОВКА'),
    icon: Icons.fitness_center_rounded,
    color: AppColors.workouts,
    description: () => t('Track your fitness', 'Отслеживай тренировки'),
  ),
  AppSection(
    id: 'abstain',
    label: () => t('ABSTAIN', 'ВОЗДЕРЖАНИЕ'),
    icon: Icons.block_rounded,
    color: AppColors.abstinences,
    description: () => t('Break bad habits', 'Избавляйся от вредного'),
  ),
  AppSection(
    id: 'reading',
    label: () => t('READING', 'ЧТЕНИЕ'),
    icon: Icons.menu_book_rounded,
    color: AppColors.reading,
    description: () => t('Track your reading', 'Отслеживай чтение'),
  ),
  AppSection(
    id: 'budget',
    label: () => t('BUDGET', 'БЮДЖЕТ'),
    icon: Icons.account_balance_wallet_rounded,
    color: AppColors.budget,
    description: () => t('Manage finances', 'Управляй финансами'),
  ),
  AppSection(
    id: 'food',
    label: () => t('FOOD', 'ПИТАНИЕ'),
    icon: Icons.restaurant_rounded,
    color: AppColors.food,
    description: () => t('Track nutrition', 'Следи за питанием'),
  ),
  AppSection(
    id: 'collect',
    label: () => t('COLLECT', 'КОЛЛЕКЦИЯ'),
    icon: Icons.stars_rounded,
    color: AppColors.collection,
    description: () => t('Your achievements', 'Твои достижения'),
  ),
  AppSection(
    id: 'profile',
    label: () => t('PROFILE', 'ПРОФИЛЬ'),
    icon: Icons.person_rounded,
    color: AppColors.profile,
    description: () => t('Your progress', 'Твой прогресс'),
  ),
];
