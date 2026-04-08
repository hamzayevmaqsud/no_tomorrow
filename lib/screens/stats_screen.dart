import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../models/task.dart';
import '../widgets/swipe_to_pop.dart';
import 'tasks_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    final tasks = TaskStore.tasks;
    final habits = HabitStore.habits;
    final doneTasks = tasks.where((t) => t.isCompleted).length;
    final totalTasks = tasks.length;
    final completionRate = totalTasks == 0 ? 0.0 : doneTasks / totalTasks;

    return SwipeToPop(child: Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            // ── Header ─────────────────────────────────
            Stack(alignment: Alignment.center, children: [
              Text('STATISTICS', style: GoogleFonts.playfairDisplay(
                fontSize: 26, fontWeight: FontWeight.w800,
                letterSpacing: 3, color: const Color(0xFFF0E6D3))),
              Align(alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withAlpha(40))),
                    child: Icon(Icons.chevron_left_rounded,
                        size: 22, color: Colors.white.withAlpha(200))))),
            ]),

            const SizedBox(height: 28),

            // ── XP Over Time (bar chart) ───────────────
            _SectionLabel(label: 'XP JOURNEY'),
            const SizedBox(height: 12),
            _XpBarChart(totalXp: gs.totalXp, level: gs.level),

            const SizedBox(height: 28),

            // ── Completion Rate ─────────────────────────
            _SectionLabel(label: 'COMPLETION RATE'),
            const SizedBox(height: 12),
            _CompletionRing(rate: completionRate, done: doneTasks, total: totalTasks),

            const SizedBox(height: 28),

            // ── Streak History ──────────────────────────
            _SectionLabel(label: 'STREAK HISTORY'),
            const SizedBox(height: 12),
            _StreakCard(current: gs.streak, best: gs.bestStreak),

            const SizedBox(height: 28),

            // ── Most Productive Day ─────────────────────
            _SectionLabel(label: 'ACTIVITY HEATMAP'),
            const SizedBox(height: 12),
            _ActivityHeatmap(tasks: tasks),

            const SizedBox(height: 28),

            // ── Quick Stats Grid ────────────────────────
            _SectionLabel(label: 'OVERVIEW'),
            const SizedBox(height: 12),
            Row(children: [
              _QuickStat(value: '${gs.totalXp}', label: 'TOTAL XP',
                  icon: Icons.star_rounded, color: AppColors.gold),
              const SizedBox(width: 10),
              _QuickStat(value: 'LVL ${gs.level}', label: 'RANK',
                  icon: Icons.shield_rounded, color: AppColors.action),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _QuickStat(value: '$doneTasks', label: 'TASKS DONE',
                  icon: Icons.check_circle_rounded, color: AppColors.success),
              const SizedBox(width: 10),
              _QuickStat(value: '${habits.length}', label: 'HABITS',
                  icon: Icons.loop_rounded, color: AppColors.habits),
            ]),
          ],
        ),
      ),
    ));
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label, style: GoogleFonts.jetBrainsMono(
    fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.action));
}

// ── XP Bar Chart ─────────────────────────────────────────────────────────────

class _XpBarChart extends StatelessWidget {
  final int totalXp;
  final int level;
  const _XpBarChart({required this.totalXp, required this.level});

  @override
  Widget build(BuildContext context) {
    // Show XP per level as bars
    final bars = <int>[];
    int remaining = totalXp;
    for (int l = 1; l <= level + 2 && l <= 15; l++) {
      final needed = GameState.xpForLevel(l);
      if (remaining >= needed) {
        bars.add(needed);
        remaining -= needed;
      } else {
        bars.add(remaining.clamp(0, needed));
        remaining = 0;
      }
    }
    final maxBar = bars.isEmpty ? 1 : bars.reduce(max);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25),
          blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${totalXp} XP earned across ${level} levels',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500,
              color: const Color(0xFF8A8070))),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.asMap().entries.map((e) {
                final i = e.key;
                final v = e.value;
                final h = maxBar == 0 ? 0.0 : (v / maxBar * 100).clamp(4.0, 100.0);
                final filled = i < level;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${v}', style: GoogleFonts.jetBrainsMono(
                          fontSize: 7, fontWeight: FontWeight.w600,
                          color: const Color(0xFF8A8070))),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: h,
                          decoration: BoxDecoration(
                            color: filled
                                ? AppColors.action
                                : AppColors.action.withAlpha(40),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('L${i + 1}', style: GoogleFonts.jetBrainsMono(
                          fontSize: 7, fontWeight: FontWeight.w600,
                          color: filled ? AppColors.action : const Color(0xFF8A8070).withAlpha(100))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion Ring ──────────────────────────────────────────────────────────

class _CompletionRing extends StatelessWidget {
  final double rate;
  final int done, total;
  const _CompletionRing({required this.rate, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25),
          blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        SizedBox(width: 80, height: 80,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 80, height: 80,
              child: CircularProgressIndicator(
                value: rate, strokeWidth: 6,
                backgroundColor: const Color(0xFF2A2318).withAlpha(12),
                valueColor: AlwaysStoppedAnimation(
                  rate >= 1.0 ? AppColors.success : AppColors.action))),
            Text('${(rate * 100).round()}%', style: GoogleFonts.jetBrainsMono(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: const Color(0xFF2A2318))),
          ])),
        const SizedBox(width: 20),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$done of $total tasks completed', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: const Color(0xFF2A2318))),
            const SizedBox(height: 6),
            Text(rate >= 1.0 ? 'All missions complete!' :
                 rate >= 0.5 ? 'Great progress, keep going!' :
                 rate > 0 ? 'Getting started...' :
                 'No tasks completed yet',
              style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF8A8070))),
          ],
        )),
      ]),
    );
  }
}

// ── Streak Card ──────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int current, best;
  const _StreakCard({required this.current, required this.best});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25),
          blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        // Current streak
        Expanded(child: Column(children: [
          Icon(Icons.local_fire_department_rounded, size: 28,
              color: current >= 7 ? AppColors.action : const Color(0xFFF59E0B)),
          const SizedBox(height: 6),
          Text('$current', style: GoogleFonts.jetBrainsMono(
            fontSize: 28, fontWeight: FontWeight.w700,
            color: const Color(0xFF2A2318))),
          Text('CURRENT', style: GoogleFonts.jetBrainsMono(
            fontSize: 8, fontWeight: FontWeight.w700,
            letterSpacing: 1.5, color: const Color(0xFF8A8070))),
        ])),
        Container(width: 1, height: 60, color: const Color(0xFF2A2318).withAlpha(15)),
        // Best streak
        Expanded(child: Column(children: [
          Icon(Icons.emoji_events_rounded, size: 28, color: AppColors.gold),
          const SizedBox(height: 6),
          Text('$best', style: GoogleFonts.jetBrainsMono(
            fontSize: 28, fontWeight: FontWeight.w700,
            color: const Color(0xFF2A2318))),
          Text('BEST', style: GoogleFonts.jetBrainsMono(
            fontSize: 8, fontWeight: FontWeight.w700,
            letterSpacing: 1.5, color: const Color(0xFF8A8070))),
        ])),
      ]),
    );
  }
}

// ── Activity Heatmap (14 days) ───────────────────────────────────────────────

class _ActivityHeatmap extends StatelessWidget {
  final List<Task> tasks;
  const _ActivityHeatmap({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25),
          blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 14 days', style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF8A8070))),
          const SizedBox(height: 12),
          Row(
            children: List.generate(14, (i) {
              final day = now.subtract(Duration(days: 13 - i));
              final isToday = i == 13;
              final count = tasks.where((t) =>
                t.isCompleted && t.dueDate != null &&
                t.dueDate!.day == day.day &&
                t.dueDate!.month == day.month
              ).length;
              final intensity = count == 0 ? 0.0
                  : count == 1 ? 0.3
                  : count == 2 ? 0.6
                  : 1.0;

              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: intensity > 0
                          ? Color.lerp(AppColors.action.withAlpha(40), AppColors.action, intensity)
                          : const Color(0xFF2A2318).withAlpha(10),
                      borderRadius: BorderRadius.circular(3),
                      border: isToday
                          ? Border.all(color: AppColors.action, width: 1.2)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${day.day}', style: GoogleFonts.jetBrainsMono(
                    fontSize: 6, fontWeight: FontWeight.w500,
                    color: isToday
                        ? AppColors.action
                        : const Color(0xFF8A8070).withAlpha(100))),
                ]),
              ));
            }),
          ),
        ],
      ),
    );
  }
}

// ── Quick Stat ───────────────────────────────────────────────────────────────

class _QuickStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _QuickStat({required this.value, required this.label,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.jetBrainsMono(
            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(label, style: GoogleFonts.inter(
            fontSize: 7, fontWeight: FontWeight.w600,
            letterSpacing: 0.5, color: Colors.white.withAlpha(100))),
        ]),
      ]),
    ));
  }
}
