import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../models/game_state.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';

// ── Screen ───────────────────────────────────────────────────────────────────

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  void _toggle(Habit habit) {
    HapticFeedback.mediumImpact();
    final wasDone = habit.isDoneToday();
    setState(() => habit.toggleToday());
    if (!wasDone) {
      GameState.instance.recordCompletion();
      GameState.instance.addXp(habit.xpPerCheck);
    }
  }

  void _delete(String id) {
    HapticFeedback.lightImpact();
    setState(() => HabitStore.habits.removeWhere((h) => h.id == id));
  }

  void _showAdd() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withAlpha(140),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (ctx, _, __) => _AddHabitSheet(
        onAdd: (habit) {
          setState(() => HabitStore.habits.insert(0, habit));
          Navigator.of(ctx).pop();
        },
        nextId: '${HabitStore.nextId++}',
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = HabitStore.habits;
    final doneToday = habits.where((h) => h.isDoneToday()).length;
    final total = habits.length;
    final pending = habits.where((h) => !h.isDoneToday()).toList();
    final completed = habits.where((h) => h.isDoneToday()).toList();

    return SwipeToPop(child: Scaffold(
      backgroundColor: const Color(0xFF0E0A16),
      body: Stack(
        children: [
          // ── Blurred bg ──────────────────────────────────
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Opacity(
                opacity: 0.3,
                child: Image.asset('assets/collection/Tasks menu/Live.jpg',
                    fit: BoxFit.cover),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: [
                          Text('HABITS',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 26, fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                              color: const Color(0xFFE8D4F0),
                            )),
                          const SizedBox(height: 3),
                          if (total > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  doneToday == total
                                      ? Icons.check_circle_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 12,
                                  color: doneToday == total
                                      ? AppColors.success
                                      : Colors.white.withAlpha(140)),
                                const SizedBox(width: 5),
                                Text('$doneToday / $total today',
                                  style: GoogleFonts.inter(
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: doneToday == total
                                        ? AppColors.success
                                        : Colors.white.withAlpha(160),
                                  )),
                                if (GameState.instance.streak >= 2) ...[
                                  const SizedBox(width: 10),
                                  Icon(Icons.local_fire_department_rounded,
                                      size: 12, color: const Color(0xFFF59E0B)),
                                  const SizedBox(width: 2),
                                  Text('${GameState.instance.streak}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF59E0B),
                                    )),
                                ],
                              ],
                            ),
                        ],
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
                ),

                const SizedBox(height: 14),
                Container(height: 1, color: Colors.white.withAlpha(12)),

                // ── Realtime Dashboard ─────────────────────
                if (total > 0)
                  _MotivationDashboard(
                    habits: habits,
                    doneToday: doneToday,
                    total: total,
                  ),

                // ── Habit list ─────────────────────────────
                Expanded(
                  child: habits.isEmpty
                      ? _EmptyHabits()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: [
                            // Pending habits
                            ...pending.asMap().entries.map((e) =>
                              _staggered(e.key, _dismissible(e.value))),
                            // Completed divider + done habits
                            if (completed.isNotEmpty) ...[
                              _DoneDivider(count: completed.length),
                              ...completed.asMap().entries.map((e) =>
                                _staggered(pending.length + e.key,
                                    _dismissible(e.value))),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),

          // ── FAB ──────────────────────────────────────────
          Positioned(
            bottom: 36, left: 52, right: 52,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: GestureDetector(
                  onTap: _showAdd,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(22),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.habits,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                color: AppColors.habits.withAlpha(100),
                                blurRadius: 12, spreadRadius: 1,
                              )],
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('NEW  HABIT',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: Colors.white.withAlpha(200),
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _staggered(int index, Widget child) {
    final delay = (index * 50).clamp(0, 400);
    return TweenAnimationBuilder<double>(
      key: ValueKey('hs_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)), child: child),
      ),
      child: child,
    );
  }

  Widget _dismissible(Habit habit) {
    final done = habit.isDoneToday();
    return Dismissible(
      key: ValueKey(habit.id),
      direction: done
          ? DismissDirection.endToStart
          : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && !done) {
          _toggle(habit);
          return false;
        }
        return true;
      },
      onDismissed: (_) => _delete(habit.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 18),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(25),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(Icons.check_rounded, color: AppColors.success, size: 20),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(20),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.red, size: 16),
      ),
      child: _HabitCard(habit: habit, onToggle: () => _toggle(habit)),
    );
  }
}

// ── Done divider ─────────────────────────────────────────────────────────────

// ── Motivation dashboard ─────────────────────────────────────────────────────

class _MotivationDashboard extends StatefulWidget {
  final List<Habit> habits;
  final int doneToday;
  final int total;
  const _MotivationDashboard({
    required this.habits,
    required this.doneToday,
    required this.total,
  });

  @override
  State<_MotivationDashboard> createState() => _MotivationDashboardState();
}

class _MotivationDashboardState extends State<_MotivationDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void didUpdateWidget(_MotivationDashboard old) {
    super.didUpdateWidget(old);
    if (old.doneToday != widget.doneToday) {
      _ring.forward(from: 0);
    }
  }

  @override
  void dispose() { _ring.dispose(); super.dispose(); }

  String get _motivationMsg {
    final p = widget.total == 0 ? 0.0 : widget.doneToday / widget.total;
    if (p >= 1.0) return 'ALL HABITS DONE. LEGENDARY.';
    if (p >= 0.7) return 'ALMOST THERE. FINISH STRONG.';
    if (p >= 0.4) return 'GOOD MOMENTUM. KEEP GOING.';
    if (p > 0)    return 'STARTED. DON\'T STOP NOW.';
    return 'NEW DAY. TIME TO GRIND.';
  }

  int get _bestStreak {
    int best = 0;
    for (final h in widget.habits) {
      if (h.streak > best) best = h.streak;
    }
    return best;
  }

  int get _totalWeeklyChecks {
    int sum = 0;
    for (final h in widget.habits) { sum += h.weeklyCount; }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.total == 0 ? 0.0 : widget.doneToday / widget.total;
    final weekMax = widget.total * 7;
    final weekPct = weekMax == 0 ? 0 : (_totalWeeklyChecks * 100 / weekMax).round();
    final todayXp = widget.doneToday * 15;
    final allDone = progress >= 1.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F2EB),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 12, offset: const Offset(0, 5)),
            BoxShadow(
              color: Colors.white.withAlpha(180),
              blurRadius: 1, offset: const Offset(0, -0.5)),
          ],
        ),
        child: Column(
          children: [
            // ── Top row: ring + stats ───────────────────
            Row(
              children: [
                // Animated ring
                SizedBox(
                  width: 70, height: 70,
                  child: AnimatedBuilder(
                    animation: _ring,
                    builder: (context, _) {
                      final animProgress = progress *
                          Curves.easeOutCubic.transform(
                              _ring.value.clamp(0.0, 1.0));
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 70, height: 70,
                            child: CircularProgressIndicator(
                              value: animProgress,
                              strokeWidth: 5,
                              backgroundColor: const Color(0xFF2A2318).withAlpha(15),
                              valueColor: AlwaysStoppedAnimation(
                                allDone ? AppColors.success : AppColors.habits),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${widget.doneToday}/${widget.total}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2A2318),
                                )),
                              Text(allDone ? 'DONE' : 'TODAY',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 7, fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: allDone
                                      ? AppColors.success
                                      : const Color(0xFF8A8070),
                                )),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Stats column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Today's XP + Best streak
                      Row(
                        children: [
                          _MiniStat(
                            icon: Icons.star_rounded,
                            label: 'TODAY XP',
                            value: '+$todayXp',
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 12),
                          _MiniStat(
                            icon: Icons.local_fire_department_rounded,
                            label: 'BEST STREAK',
                            value: '$_bestStreak',
                            color: AppColors.action,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Row 2: Week consistency
                      Row(
                        children: [
                          _MiniStat(
                            icon: Icons.insights_rounded,
                            label: 'THIS WEEK',
                            value: '$weekPct%',
                            color: AppColors.habits,
                          ),
                          const SizedBox(width: 12),
                          _MiniStat(
                            icon: Icons.repeat_rounded,
                            label: 'TOTAL',
                            value: '$_totalWeeklyChecks/${weekMax}',
                            color: const Color(0xFF2A2318),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Motivation message ─────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: allDone
                    ? AppColors.success.withAlpha(15)
                    : AppColors.habits.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: allDone
                      ? AppColors.success.withAlpha(50)
                      : AppColors.habits.withAlpha(30)),
              ),
              child: Text(_motivationMsg,
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: allDone
                      ? AppColors.success
                      : const Color(0xFF594536),
                )),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: color,
                )),
              Text(label,
                style: GoogleFonts.inter(
                  fontSize: 7, fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: const Color(0xFF8A8070),
                )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Done divider ─────────────────────────────────────────────────────────────

class _DoneDivider extends StatelessWidget {
  final int count;
  const _DoneDivider({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        children: [
          Expanded(child: Container(height: 1,
              color: AppColors.success.withAlpha(40))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 11, color: AppColors.success),
                const SizedBox(width: 5),
                Text('DONE  $count',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    letterSpacing: 1, color: AppColors.success,
                  )),
              ],
            ),
          ),
          Expanded(child: Container(height: 1,
              color: AppColors.success.withAlpha(40))),
        ],
      ),
    );
  }
}

// ── Habit card ───────────────────────────────────────────────────────────────

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;

  const _HabitCard({required this.habit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final done = habit.isDoneToday();
    final color = habitCatColor(habit.category);
    final streak = habit.streak;
    final weekly = habit.weeklyCount;

    const cardBg = Color(0xFFF5F2EB);
    const textCol = Color(0xFF2A2318);
    const subCol = Color(0xFF8A8070);

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: done ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 12, offset: const Offset(0, 5)),
              BoxShadow(
                color: Colors.white.withAlpha(180),
                blurRadius: 1, offset: const Offset(0, -0.5)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left content ─────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withAlpha(15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: color.withAlpha(40), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(habitCatIcon(habit.category),
                                    size: 10, color: color),
                                const SizedBox(width: 4),
                                Text(habitCatLabel(habit.category),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8, fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8, color: color,
                                  )),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Title
                          Text(habit.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18, fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              height: 1.2, color: textCol,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: textCol.withAlpha(100),
                            )),

                          const SizedBox(height: 10),

                          // Weekly progress bar + streak
                          Row(
                            children: [
                              // 7-day bar
                              ...List.generate(7, (i) {
                                final d = DateTime.now().subtract(
                                    Duration(days: 6 - i));
                                final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                                final filled = habit.completedDates.contains(key);
                                final isToday = i == 6;
                                return Container(
                                  width: 16, height: 6,
                                  margin: const EdgeInsets.only(right: 3),
                                  decoration: BoxDecoration(
                                    color: filled
                                        ? color
                                        : textCol.withAlpha(18),
                                    borderRadius: BorderRadius.circular(2),
                                    border: isToday && !filled
                                        ? Border.all(
                                            color: color.withAlpha(80),
                                            width: 0.8)
                                        : null,
                                  ),
                                );
                              }),
                              const SizedBox(width: 6),
                              Text('$weekly/7',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9, fontWeight: FontWeight.w600,
                                  color: subCol)),

                              if (streak >= 2) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.local_fire_department_rounded,
                                    size: 12,
                                    color: streak >= 7
                                        ? AppColors.action
                                        : const Color(0xFFF59E0B)),
                                const SizedBox(width: 2),
                                Text('$streak',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9, fontWeight: FontWeight.w700,
                                    color: streak >= 7
                                        ? AppColors.action
                                        : const Color(0xFFF59E0B),
                                  )),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Right accent block ────────────────────
                  Container(
                    width: 56,
                    color: done
                        ? const Color(0xFFCCCAC4)
                        : color.withAlpha(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Check circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: done
                                ? color.withAlpha(60)
                                : color.withAlpha(20),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: done
                                  ? color.withAlpha(160)
                                  : color.withAlpha(60),
                              width: 1.5,
                            ),
                          ),
                          child: done
                              ? Icon(Icons.check_rounded,
                                  size: 16, color: color)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        // XP
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            done ? '✓' : '+${habit.xpPerCheck}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8, fontWeight: FontWeight.w700,
                              color: done ? subCol : AppColors.gold,
                            )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyHabits extends StatefulWidget {
  @override
  State<_EmptyHabits> createState() => _EmptyHabitsState();
}

class _EmptyHabitsState extends State<_EmptyHabits>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final y = sin(_ctrl.value * pi) * 8;
          final opacity = 0.7 + 0.3 * sin(_ctrl.value * pi);
          return Transform.translate(
            offset: Offset(0, -y),
            child: Opacity(opacity: opacity, child: child),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(18),
                border: Border.all(
                    color: Colors.white.withAlpha(80), width: 1.5),
              ),
              child: Icon(Icons.loop_rounded,
                  size: 26, color: Colors.white.withAlpha(180)),
            ),
            const SizedBox(height: 18),
            Text('no habits yet',
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(200),
              )),
            const SizedBox(height: 6),
            Text('build your daily routine',
              style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white.withAlpha(160),
              )),
          ],
        ),
      ),
    );
  }
}

// ── Add habit sheet ──────────────────────────────────────────────────────────

class _AddHabitSheet extends StatefulWidget {
  final void Function(Habit) onAdd;
  final String nextId;
  const _AddHabitSheet({required this.onAdd, required this.nextId});

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _ctrl = TextEditingController();
  HabitCategory _cat = HabitCategory.health;

  static const _kSheetBg     = Color(0xFFF5F1E8);
  static const _kRowBg       = Color(0xFFEFEBE0);
  static const _kDivider     = Color(0xFFDDD8CB);
  static const _kCocoa       = Color(0xFF594536);
  static const _kCoconutMilk = Color(0xFFF0EDE5);

  void _submit() {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return;
    widget.onAdd(Habit(
      id: widget.nextId,
      title: title,
      category: _cat,
      createdAt: DateTime.now(),
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final kb = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 48, 40, kb > 0 ? kb + 12 : 48),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Container(
              width: sw * 0.82,
              decoration: BoxDecoration(
                color: _kSheetBg,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 40, offset: const Offset(6, 8),
                )],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.habits.withAlpha(25),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(36)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.habits,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.loop_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NEW HABIT',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2, color: _kCocoa,
                                )),
                              Text('+${Habit(id: '', title: '', createdAt: DateTime.now()).xpPerCheck} XP / day',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9, fontWeight: FontWeight.w600,
                                  color: _kCocoa.withAlpha(140),
                                )),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: _kDivider,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.close_rounded,
                                  color: _kCocoa.withAlpha(150), size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Title field ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 12, color: _kCocoa.withAlpha(130)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              autofocus: true,
                              style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.w600,
                                color: _kCocoa,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g. Meditate 10 min',
                                hintStyle: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: _kCocoa.withAlpha(100)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, thickness: 1, color: _kDivider),

                    // ── Category picker ─────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.category_rounded,
                                  size: 12, color: _kCocoa.withAlpha(130)),
                              const SizedBox(width: 6),
                              Text('CATEGORY',
                                style: GoogleFonts.inter(
                                  fontSize: 9, fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: _kCocoa.withAlpha(140),
                                )),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: HabitCategory.values.map((c) {
                              final active = _cat == c;
                              final color = habitCatColor(c);
                              return GestureDetector(
                                onTap: () => setState(() => _cat = c),
                                child: AnimatedScale(
                                  scale: active ? 1.08 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutBack,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? color.withAlpha(25)
                                          : _kRowBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: active
                                            ? color.withAlpha(150)
                                            : _kDivider,
                                        width: active ? 1.5 : 1.0,
                                      ),
                                      boxShadow: active
                                          ? [BoxShadow(
                                              color: color.withAlpha(60),
                                              blurRadius: 8, spreadRadius: 1)]
                                          : [],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(habitCatIcon(c), size: 13,
                                            color: active
                                                ? color
                                                : _kCocoa.withAlpha(100)),
                                        const SizedBox(width: 5),
                                        Text(habitCatLabel(c),
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: active
                                                ? color
                                                : _kCocoa.withAlpha(130),
                                          )),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // ── Submit ──────────────────────────────
                    Divider(height: 1, thickness: 1, color: _kDivider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                      child: GestureDetector(
                        onTap: _submit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.habits,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [BoxShadow(
                              color: AppColors.habits.withAlpha(70),
                              blurRadius: 14, offset: const Offset(0, 4),
                            )],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('CREATE HABIT',
                                style: GoogleFonts.inter(
                                  fontSize: 12, fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4, color: Colors.white,
                                )),
                              const SizedBox(width: 8),
                              Text('+15 XP',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9, fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(200),
                                )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
