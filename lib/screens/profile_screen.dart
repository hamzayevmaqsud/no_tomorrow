import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';
import 'tasks_screen.dart';
import 'stats_screen.dart';

void _confirmSignOut(BuildContext context) async {
  HapticFeedback.mediumImpact();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1C1C27),
      title: Text('Sign out?',
        style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: Colors.white)),
      content: Text('You can sign back in anytime — your data stays in the cloud.',
        style: GoogleFonts.inter(
          fontSize: 13, color: Colors.white.withAlpha(180))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel',
            style: GoogleFonts.inter(color: Colors.white.withAlpha(160)))),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Sign out',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFDC2626)))),
      ],
    ),
  );
  if (confirmed == true) {
    await FirebaseAuth.instance.signOut();
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    final totalTasks = TaskStore.tasks.length;
    final doneTasks = TaskStore.tasks.where((t) => t.isCompleted).length;
    final totalHabits = HabitStore.habits.length;
    final habitsToday = HabitStore.habits.where((h) => h.isDoneToday()).length;

    return SwipeToPop(child: Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(children: [
        // Bg gradient
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(gradient: RadialGradient(
            center: Alignment(0, -0.4), radius: 1.2,
            colors: [Color(0xFF141420), Color(0xFF0A0A0F)],
          )),
        )),

        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // ── Header ─────────────────────────────────
              Stack(
                alignment: Alignment.center,
                children: [
                  Column(children: [
                    Text(
                      (gs.username?.isNotEmpty ?? false)
                        ? gs.username!.toUpperCase()
                        : 'PROFILE',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26, fontWeight: FontWeight.w800,
                        letterSpacing: 3, color: const Color(0xFFF0E6D3))),
                  ]),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const StatsScreen())),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.action.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.action.withAlpha(50)),
                          ),
                          child: Icon(Icons.insights_rounded,
                              size: 18, color: AppColors.action),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _confirmSignOut(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDC2626).withAlpha(50)),
                          ),
                          child: const Icon(Icons.logout_rounded,
                              size: 16, color: Color(0xFFDC2626)),
                        ),
                      ),
                    ]),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(40)),
                        ),
                        child: Icon(Icons.chevron_left_rounded,
                            size: 22, color: Colors.white.withAlpha(200)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Avatar + Level ─────────────────────────
              Center(
                child: Column(children: [
                  // Avatar with XP ring
                  SizedBox(
                    width: 100, height: 100,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox(width: 100, height: 100,
                        child: CircularProgressIndicator(
                          value: gs.levelProgress,
                          strokeWidth: 4,
                          backgroundColor: Colors.white.withAlpha(15),
                          valueColor: const AlwaysStoppedAnimation(AppColors.action),
                        )),
                      Container(
                        width: 84, height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: AppColors.action.withAlpha(50),
                            blurRadius: 16, spreadRadius: 2)],
                        ),
                        child: ClipOval(
                          child: Image.asset('assets/images/avatar.png',
                            width: 84, height: 84, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1A1008),
                              child: Center(child: Text('H', style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))))),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Text('HAMZA', style: GoogleFonts.playfairDisplay(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    letterSpacing: 3, color: Colors.white)),
                  const SizedBox(height: 6),
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFCA8A04), Color(0xFFE8A94E), Color(0xFFCA8A04)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                        color: AppColors.gold.withAlpha(80),
                        blurRadius: 12, spreadRadius: 1)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.shield_rounded, size: 14, color: Color(0xFF1A0E08)),
                      const SizedBox(width: 5),
                      Text('LEVEL ${gs.level}', style: GoogleFonts.jetBrainsMono(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5, color: const Color(0xFF1A0E08))),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text('${gs.xpInLevel} / ${gs.xpForNextLevel} XP to next level',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, fontWeight: FontWeight.w500,
                      color: Colors.white.withAlpha(120))),
                ]),
              ),

              const SizedBox(height: 28),

              // ── Stats Grid ─────────────────────────────
              _SectionTitle(label: 'STATISTICS'),
              const SizedBox(height: 12),
              Row(children: [
                _StatCard(icon: Icons.star_rounded, label: 'TOTAL XP',
                  value: '${gs.totalXp}', color: AppColors.gold),
                const SizedBox(width: 10),
                _StatCard(icon: Icons.local_fire_department_rounded, label: 'BEST STREAK',
                  value: '${gs.bestStreak}d', color: AppColors.action),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _StatCard(icon: Icons.check_circle_rounded, label: 'COMPLETIONS',
                  value: '${gs.totalCompletions}', color: AppColors.success),
                const SizedBox(width: 10),
                _StatCard(icon: Icons.local_fire_department_rounded, label: 'CURRENT STREAK',
                  value: '${gs.streak}d', color: const Color(0xFFF59E0B)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _StatCard(icon: Icons.task_alt_rounded, label: 'TASKS',
                  value: '$doneTasks / $totalTasks', color: AppColors.tasks),
                const SizedBox(width: 10),
                _StatCard(icon: Icons.loop_rounded, label: 'HABITS TODAY',
                  value: '$habitsToday / $totalHabits', color: AppColors.habits),
              ]),

              const SizedBox(height: 28),

              // ── Next Level Preview ─────────────────────
              _SectionTitle(label: 'LEVEL REWARDS'),
              const SizedBox(height: 12),
              _LevelRewardsPreview(currentLevel: gs.level),

              const SizedBox(height: 28),

              // ── Achievements ───────────────────────────
              _SectionTitle(label: 'ACHIEVEMENTS'),
              const SizedBox(height: 4),
              Text('${gs.unlockedBadges.length} / ${GameState.badgeInfo.length} unlocked',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9, fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(100))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: GameState.badgeInfo.entries.map((e) {
                  final unlocked = gs.unlockedBadges.contains(e.key);
                  final (title, desc, emoji) = e.value;
                  return _BadgeCard(
                    title: title, desc: desc, emoji: emoji,
                    unlocked: unlocked,
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // ── Activity Summary ───────────────────────
              _SectionTitle(label: 'THIS WEEK'),
              const SizedBox(height: 12),
              _WeeklyActivity(),

              const SizedBox(height: 28),

              // ── Milestones ─────────────────────────────
              _SectionTitle(label: 'MILESTONES'),
              const SizedBox(height: 12),
              _MilestoneRow(label: 'First Task', target: 1, current: gs.totalCompletions, icon: Icons.flag_rounded),
              _MilestoneRow(label: '10 Completions', target: 10, current: gs.totalCompletions, icon: Icons.trending_up_rounded),
              _MilestoneRow(label: '50 Completions', target: 50, current: gs.totalCompletions, icon: Icons.rocket_launch_rounded),
              _MilestoneRow(label: '100 XP', target: 100, current: gs.totalXp, icon: Icons.star_rounded),
              _MilestoneRow(label: '500 XP', target: 500, current: gs.totalXp, icon: Icons.star_rounded),
              _MilestoneRow(label: '7-Day Streak', target: 7, current: gs.bestStreak, icon: Icons.local_fire_department_rounded),
              _MilestoneRow(label: 'Level 5', target: 5, current: gs.level, icon: Icons.shield_rounded),
              _MilestoneRow(label: 'Level 10', target: 10, current: gs.level, icon: Icons.shield_rounded),
            ],
          ),
        ),
      ]),
    ));
  }
}

// ── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label, style: GoogleFonts.jetBrainsMono(
      fontSize: 10, fontWeight: FontWeight.w700,
      letterSpacing: 2, color: AppColors.action));
  }
}

// ── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label,
    required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F2EB),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(value,
                  key: ValueKey(value),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: const Color(0xFF2A2318))),
              ),
              Text(label, style: GoogleFonts.inter(
                fontSize: 8, fontWeight: FontWeight.w600,
                letterSpacing: 0.5, color: const Color(0xFF8A8070))),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Badge card ───────────────────────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  final String title, desc, emoji;
  final bool unlocked;
  const _BadgeCard({required this.title, required this.desc,
    required this.emoji, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 50) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked
            ? const Color(0xFFF5F2EB)
            : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? AppColors.gold.withAlpha(80)
              : Colors.white.withAlpha(15),
          width: unlocked ? 1.5 : 0.8,
        ),
        boxShadow: unlocked
            ? [BoxShadow(color: AppColors.gold.withAlpha(20),
                blurRadius: 10, spreadRadius: 1)]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: TextStyle(
              fontSize: 18,
              color: unlocked ? null : Colors.white.withAlpha(40),
            )),
            const Spacer(),
            if (unlocked)
              Icon(Icons.check_circle_rounded, size: 14,
                  color: AppColors.gold),
          ]),
          const SizedBox(height: 6),
          Text(title, style: GoogleFonts.jetBrainsMono(
            fontSize: 10, fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: unlocked
                ? const Color(0xFF2A2318)
                : Colors.white.withAlpha(50),
          )),
          const SizedBox(height: 2),
          Text(desc, style: GoogleFonts.inter(
            fontSize: 9,
            color: unlocked
                ? const Color(0xFF8A8070)
                : Colors.white.withAlpha(30),
          )),
        ],
      ),
    );
  }
}

// ── Weekly activity ──────────────────────────────────────────────────────────

class _WeeklyActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EB),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withAlpha(25),
          blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: List.generate(7, (i) {
          final day = monday.add(Duration(days: i));
          final isToday = day.day == now.day && day.month == now.month;
          final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
          // Count tasks completed on this day
          final count = TaskStore.tasks.where((t) =>
            t.isCompleted && t.dueDate != null &&
            t.dueDate!.day == day.day && t.dueDate!.month == day.month
          ).length;
          final intensity = count == 0 ? 0.0
              : count == 1 ? 0.3
              : count == 2 ? 0.6
              : 1.0;

          return Expanded(child: Column(children: [
            Text(dayNames[i], style: GoogleFonts.jetBrainsMono(
              fontSize: 7, fontWeight: FontWeight.w600,
              color: const Color(0xFF8A8070).withAlpha(140))),
            const SizedBox(height: 6),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: intensity > 0
                    ? Color.lerp(AppColors.action.withAlpha(40), AppColors.action, intensity)
                    : isToday
                        ? Colors.transparent
                        : const Color(0xFF2A2318).withAlpha(10),
                borderRadius: BorderRadius.circular(6),
                border: isToday
                    ? Border.all(color: AppColors.action.withAlpha(160), width: 1.5)
                    : null,
              ),
              child: count > 0
                  ? Center(child: Text('$count', style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: intensity > 0.5 ? Colors.white : const Color(0xFF2A2318))))
                  : null,
            ),
            const SizedBox(height: 4),
            Text('${day.day}', style: GoogleFonts.inter(
              fontSize: 8, fontWeight: FontWeight.w500,
              color: isToday ? AppColors.action : const Color(0xFF8A8070))),
          ]));
        }),
      ),
    );
  }
}

// ── Milestone row ────────────────────────────────────────────────────────────

// ── Level rewards preview ─────────────────────────────────────────────────────

class _LevelRewardsPreview extends StatelessWidget {
  final int currentLevel;
  const _LevelRewardsPreview({required this.currentLevel});

  static const _rewards = {
    2: ('Custom Themes', Icons.palette_rounded),
    3: ('Habit Categories', Icons.category_rounded),
    5: ('Dark Mode Pro', Icons.dark_mode_rounded),
    7: ('Weekly Analytics', Icons.insights_rounded),
    10: ('Custom Avatars', Icons.face_rounded),
    15: ('Streak Shields', Icons.shield_rounded),
    20: ('Legendary Title', Icons.military_tech_rounded),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EB),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withAlpha(25),
          blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: _rewards.entries.map((e) {
          final lvl = e.key;
          final (label, icon) = e.value;
          final unlocked = currentLevel >= lvl;
          final isNext = !unlocked && (lvl == _rewards.keys.firstWhere((k) => k > currentLevel, orElse: () => 999));
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: unlocked
                      ? AppColors.gold.withAlpha(25)
                      : isNext
                          ? AppColors.action.withAlpha(15)
                          : const Color(0xFF2A2318).withAlpha(8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: unlocked
                        ? AppColors.gold.withAlpha(80)
                        : isNext
                            ? AppColors.action.withAlpha(50)
                            : const Color(0xFF2A2318).withAlpha(15)),
                ),
                child: Icon(icon, size: 14,
                  color: unlocked
                      ? AppColors.gold
                      : isNext
                          ? AppColors.action
                          : const Color(0xFF8A8070).withAlpha(80)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: unlocked
                      ? const Color(0xFF2A2318)
                      : const Color(0xFF8A8070).withAlpha(unlocked ? 255 : 140),
                )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: unlocked
                      ? AppColors.gold.withAlpha(15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: unlocked
                        ? AppColors.gold.withAlpha(50)
                        : const Color(0xFF2A2318).withAlpha(15)),
                ),
                child: Text(unlocked ? '✓ LVL $lvl' : 'LVL $lvl',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: unlocked
                        ? AppColors.gold
                        : isNext
                            ? AppColors.action
                            : const Color(0xFF8A8070).withAlpha(100),
                  )),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ── Milestone row ────────────────────────────────────────────────────────────

class _MilestoneRow extends StatelessWidget {
  final String label;
  final int target, current;
  final IconData icon;
  const _MilestoneRow({required this.label, required this.target,
    required this.current, required this.icon});

  @override
  Widget build(BuildContext context) {
    final done = current >= target;
    final progress = (current / target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: done
            ? AppColors.gold.withAlpha(10)
            : Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppColors.gold.withAlpha(50)
              : Colors.white.withAlpha(15)),
      ),
      child: Row(children: [
        Icon(icon, size: 16,
            color: done ? AppColors.gold : Colors.white.withAlpha(60)),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: done ? Colors.white : Colors.white.withAlpha(160))),
            const SizedBox(height: 4),
            Stack(children: [
              Container(height: 4, decoration: BoxDecoration(
                color: Colors.white.withAlpha(12),
                borderRadius: BorderRadius.circular(2))),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(height: 4, decoration: BoxDecoration(
                  color: done ? AppColors.gold : AppColors.action,
                  borderRadius: BorderRadius.circular(2)))),
            ]),
          ],
        )),
        const SizedBox(width: 10),
        done
            ? Icon(Icons.check_circle_rounded, size: 18, color: AppColors.gold)
            : Text('$current/$target', style: GoogleFonts.jetBrainsMono(
                fontSize: 9, fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(100))),
      ]),
    );
  }
}
