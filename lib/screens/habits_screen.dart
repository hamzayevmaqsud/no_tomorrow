import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../models/game_state.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';

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
          begin: const Offset(0, 1),
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

    return SwipeToPop(child: Scaffold(
      backgroundColor: const Color(0xFF0C0A14),
      body: Stack(
        children: [
          // ── Gradient bg ──────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.4),
                  radius: 1.2,
                  colors: [Color(0xFF1A1028), Color(0xFF0C0A14)],
                ),
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
                              color: const Color(0xFFE0D4F0),
                            )),
                          const SizedBox(height: 3),
                          if (total > 0)
                            Text('$doneToday / $total today',
                              style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: Colors.white.withAlpha(160),
                              )),
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

                // ── Daily progress ring ────────────────────
                if (total > 0) ...[
                  const SizedBox(height: 24),
                  _DailyRing(done: doneToday, total: total),
                  const SizedBox(height: 24),
                ],

                // ── Habit list ─────────────────────────────
                Expanded(
                  child: habits.isEmpty
                      ? _EmptyHabits()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: habits.length,
                          itemBuilder: (ctx, i) {
                            final h = habits[i];
                            return Dismissible(
                              key: ValueKey(h.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _delete(h.id),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 18),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(20),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red, size: 16),
                              ),
                              child: _HabitCard(
                                habit: h,
                                onToggle: () => _toggle(h),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // ── FAB ──────────────────────────────────────────
          Positioned(
            bottom: 36, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _showAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.habits,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.habits.withAlpha(100),
                        blurRadius: 20, spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('NEW HABIT',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          letterSpacing: 1, color: Colors.white,
                        )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

// ── Daily progress ring ──────────────────────────────────────────────────────

class _DailyRing extends StatelessWidget {
  final int done;
  final int total;
  const _DailyRing({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    return SizedBox(
      width: 90, height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90, height: 90,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              backgroundColor: Colors.white.withAlpha(15),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? AppColors.success : AppColors.habits),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$done/$total',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
              Text(progress >= 1.0 ? 'ALL DONE' : 'TODAY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8, fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: progress >= 1.0
                      ? AppColors.success
                      : Colors.white.withAlpha(100),
                )),
            ],
          ),
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

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: done
              ? color.withAlpha(18)
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done ? color.withAlpha(80) : Colors.white.withAlpha(20),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Check circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? color.withAlpha(40) : Colors.white.withAlpha(8),
                border: Border.all(
                  color: done ? color : Colors.white.withAlpha(40),
                  width: done ? 2 : 1.2,
                ),
              ),
              child: done
                  ? Icon(Icons.check_rounded, size: 20, color: color)
                  : Icon(habitCatIcon(habit.category),
                      size: 18, color: Colors.white.withAlpha(80)),
            ),

            const SizedBox(width: 14),

            // Title + streak
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.title,
                    style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: done
                          ? Colors.white.withAlpha(120)
                          : Colors.white.withAlpha(220),
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: Colors.white.withAlpha(60),
                    )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(habitCatLabel(habit.category),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8, fontWeight: FontWeight.w700,
                            letterSpacing: 1, color: color,
                          )),
                      ),
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
                            fontSize: 10, fontWeight: FontWeight.w700,
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

            // Weekly mini dots
            Row(
              children: List.generate(7, (i) {
                final d = DateTime.now().subtract(Duration(days: 6 - i));
                final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                final filled = habit.completedDates.contains(key);
                return Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? color : Colors.white.withAlpha(18),
                  ),
                );
              }),
            ),

            const SizedBox(width: 6),

            // XP
            Text('+${habit.xpPerCheck}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: AppColors.gold,
              )),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyHabits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.loop_rounded, size: 40, color: Colors.white.withAlpha(60)),
          const SizedBox(height: 16),
          Text('no habits yet',
            style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha(180),
            )),
          const SizedBox(height: 6),
          Text('build your daily routine',
            style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white.withAlpha(120),
            )),
        ],
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
    final kb = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, kb > 0 ? kb + 12 : 36),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1828),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withAlpha(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 30, offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEW HABIT',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
                const SizedBox(height: 16),

                // Title field
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Meditate 10 minutes',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 16, color: Colors.white.withAlpha(60)),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: 16),

                // Category chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: HabitCategory.values.map((c) {
                    final active = _cat == c;
                    final color = habitCatColor(c);
                    return GestureDetector(
                      onTap: () => setState(() => _cat = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? color.withAlpha(30) : Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: active ? color.withAlpha(160) : Colors.white.withAlpha(25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(habitCatIcon(c), size: 14,
                                color: active ? color : Colors.white.withAlpha(100)),
                            const SizedBox(width: 6),
                            Text(habitCatLabel(c),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9, fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: active ? color : Colors.white.withAlpha(120),
                              )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Submit
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.habits,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                        color: AppColors.habits.withAlpha(80),
                        blurRadius: 14, offset: const Offset(0, 4),
                      )],
                    ),
                    child: Center(
                      child: Text('CREATE HABIT',
                        style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w800,
                          letterSpacing: 1.2, color: Colors.white,
                        )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
