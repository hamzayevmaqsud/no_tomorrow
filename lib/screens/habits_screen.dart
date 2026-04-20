import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../models/game_state.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';
import '../widgets/jelly_button.dart';
import '../l10n/app_locale.dart';

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

    // If habit has timer and not done yet — open timer instead
    if (!wasDone && habit.timerMinutes > 0) {
      _openTimer(habit);
      return;
    }

    setState(() => habit.toggleToday());
    if (!wasDone) {
      GameState.instance.recordCompletion();
      GameState.instance.addXp(habit.xpPerCheck);
      // Check-in celebration
      _showCheckCelebration(habit);
      // Streak milestone check
      if (habit.streak == 7 || habit.streak == 30 || habit.streak == 100) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _showStreakMilestone(habit.streak);
        });
      }
    }
  }

  void _showCheckCelebration(Habit habit) {
    final overlay = Overlay.of(context);
    late OverlayEntry e;
    e = OverlayEntry(builder: (_) => _CheckCelebration(
      color: habitCatColor(habit.category),
      onDone: () => e.remove(),
    ));
    overlay.insert(e);
  }

  void _showStreakMilestone(int streak) {
    final overlay = Overlay.of(context);
    late OverlayEntry e;
    e = OverlayEntry(builder: (_) => _StreakMilestone(
      streak: streak, onDone: () => e.remove(),
    ));
    overlay.insert(e);
  }

  void _openTimer(Habit habit) {
    Navigator.push(context, PageRouteBuilder(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) => _HabitTimerScreen(
        habit: habit,
        onComplete: () {
          Navigator.pop(ctx);
          setState(() => habit.toggleToday());
          GameState.instance.recordCompletion();
          GameState.instance.addXp(habit.xpPerCheck);
          _showCheckCelebration(habit);
          if (habit.streak == 7 || habit.streak == 30 || habit.streak == 100) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) _showStreakMilestone(habit.streak);
            });
          }
        },
      ),
      transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child),
    ));
  }

  void _showNoteDialog(Habit habit) {
    final ctrl = TextEditingController(
      text: habit.notes[Habit.dateKeyPublic(DateTime.now())] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF5F2EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t('Note', 'Заметка'), style: GoogleFonts.playfairDisplay(
          fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF2A2318))),
        content: TextField(
          controller: ctrl, maxLines: 3, autofocus: true,
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2A2318)),
          decoration: InputDecoration(
            hintText: t('How did it go?', 'Как прошло?'),
            hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF8A8070)),
            border: InputBorder.none)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(t('Cancel', 'Отмена'), style: GoogleFonts.inter(color: const Color(0xFF8A8070)))),
          TextButton(onPressed: () {
            habit.notes[Habit.dateKeyPublic(DateTime.now())] = ctrl.text.trim();
            Navigator.pop(ctx);
            setState(() {});
          }, child: Text(t('Save', 'Сохранить'), style: GoogleFonts.inter(
            fontWeight: FontWeight.w700, color: AppColors.habits))),
        ],
      ),
    );
  }

  void _delete(String id) {
    HapticFeedback.lightImpact();
    final idx = HabitStore.habits.indexWhere((h) => h.id == id);
    if (idx < 0) return;
    final removed = HabitStore.habits.removeAt(idx);
    setState(() {});
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t('Deleted "${removed.title}"', 'Удалено "${removed.title}"')),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(label: t('UNDO', 'ОТМЕНИТЬ'), onPressed: () {
        setState(() => HabitStore.habits.insert(idx.clamp(0, HabitStore.habits.length), removed));
      }),
    ));
  }

  void _showDetail(Habit habit) {
    HapticFeedback.lightImpact();
    Navigator.push(context, PageRouteBuilder(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, _, __) => _HabitDetailView(
        habit: habit,
        onToggle: () { _toggle(habit); },
      ),
      transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    ));
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

    // Group by routine
    final morning = pending.where((h) => h.routineSlot == 'morning').toList();
    final evening = pending.where((h) => h.routineSlot == 'evening').toList();
    final anytime = pending.where((h) => h.routineSlot.isEmpty).toList();

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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
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
                      const Spacer(),
                      Text(t('HABITS', 'ПРИВЫЧКИ'),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 2,
                          color: const Color(0xFFE8D4F0),
                        )),
                    ],
                  ),
                ),

                // ── Today stats row ─────────────────────────
                if (total > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Row(
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
                        Text('$doneToday / $total ${t('today', 'сегодня')}',
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
                  ),

                const SizedBox(height: 10),

                // ── Always-on calendar + stats ────────────
                _HabitCalendarBar(habits: habits),

                const SizedBox(height: 8),

                // ── Inline stats row ──────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    _InlineStat(icon: Icons.check_circle_rounded,
                      value: '$doneToday/$total', label: t('TODAY', 'СЕГОДНЯ'),
                      color: doneToday == total && total > 0
                          ? AppColors.success : AppColors.habits),
                    const SizedBox(width: 8),
                    _InlineStat(icon: Icons.local_fire_department_rounded,
                      value: '${GameState.instance.streak}',
                      label: t('STREAK', 'СЕРИЯ'),
                      color: GameState.instance.streak >= 7
                          ? AppColors.action : const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _InlineStat(icon: Icons.star_rounded,
                      value: '+${doneToday * 15}',
                      label: t('XP TODAY', 'XP СЕГОДНЯ'), color: AppColors.gold),
                  ]),
                ),

                const SizedBox(height: 8),

                // ── Daily progress bar ────────────────────
                if (total > 0) Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(children: [
                        Container(height: 6, decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(3))),
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          widthFactor: total == 0 ? 0 : doneToday / total,
                          child: Container(height: 6, decoration: BoxDecoration(
                            color: doneToday == total
                                ? AppColors.success
                                : AppColors.habits,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [BoxShadow(
                              color: (doneToday == total
                                  ? AppColors.success
                                  : AppColors.habits).withAlpha(80),
                              blurRadius: 8)]))),
                      ]),
                      const SizedBox(height: 4),
                      Text(doneToday == total && total > 0
                          ? t('ALL DONE TODAY!', 'ВСЁ СДЕЛАНО СЕГОДНЯ!')
                          : '$doneToday ${t('of', 'из')} $total ${t('completed', 'выполнено')}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8, fontWeight: FontWeight.w600,
                          color: doneToday == total && total > 0
                              ? AppColors.success
                              : Colors.white.withAlpha(100))),
                    ],
                  ),
                ),

                // ── Habit list ─────────────────────────────
                Expanded(
                  child: habits.isEmpty
                      ? _EmptyHabits()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: [
                            // Morning routine
                            if (morning.isNotEmpty) ...[
                              _RoutineHeader(icon: Icons.wb_sunny_rounded, label: t('MORNING', 'УТРО')),
                              ...morning.asMap().entries.map((e) =>
                                _staggered(e.key, _dismissible(e.value))),
                            ],
                            // Evening routine
                            if (evening.isNotEmpty) ...[
                              _RoutineHeader(icon: Icons.nightlight_round, label: t('EVENING', 'ВЕЧЕР')),
                              ...evening.asMap().entries.map((e) =>
                                _staggered(morning.length + e.key, _dismissible(e.value))),
                            ],
                            // Anytime
                            if (anytime.isNotEmpty) ...[
                              if (morning.isNotEmpty || evening.isNotEmpty)
                                _RoutineHeader(icon: Icons.access_time_rounded, label: t('ANYTIME', 'ЛЮБОЕ ВРЕМЯ')),
                              ...anytime.asMap().entries.map((e) =>
                                _staggered(morning.length + evening.length + e.key,
                                    _dismissible(e.value))),
                            ],
                            // Completed
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
                child: JellyButton(
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
                          Text(t('NEW  HABIT', 'НОВАЯ  ПРИВЫЧКА'),
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
      child: _HabitCard(
        habit: habit,
        onToggle: () => _toggle(habit),
        onDetail: () => _showDetail(habit),
        onNote: () => _showNoteDialog(habit),
      ),
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
    if (widget.total == 0) return t('ADD YOUR FIRST HABIT. BEGIN.', 'ДОБАВЬ ПЕРВУЮ ПРИВЫЧКУ. НАЧНИ.');
    final p = widget.doneToday / widget.total;
    if (p >= 1.0) return t('ALL HABITS DONE. LEGENDARY.', 'ВСЕ ПРИВЫЧКИ ВЫПОЛНЕНЫ. ЛЕГЕНДА.');
    if (p >= 0.7) return t('ALMOST THERE. FINISH STRONG.', 'ПОЧТИ ГОТОВО. ФИНИШИРУЙ СИЛЬНО.');
    if (p >= 0.4) return t('GOOD MOMENTUM. KEEP GOING.', 'ХОРОШИЙ ТЕМП. ПРОДОЛЖАЙ.');
    if (p > 0)    return t('STARTED. DON\'T STOP NOW.', 'НАЧАЛО ПОЛОЖЕНО. НЕ ОСТАНАВЛИВАЙСЯ.');
    return t('NEW DAY. TIME TO GRIND.', 'НОВЫЙ ДЕНЬ. ВРЕМЯ ДЕЙСТВОВАТЬ.');
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
                              Text(allDone ? t('DONE', 'ГОТОВО') : t('TODAY', 'СЕГОДНЯ'),
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
                            label: t('TODAY XP', 'XP СЕГОДНЯ'),
                            value: '+$todayXp',
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 12),
                          _MiniStat(
                            icon: Icons.local_fire_department_rounded,
                            label: t('BEST STREAK', 'ЛУЧШАЯ СЕРИЯ'),
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
                            label: t('THIS WEEK', 'ЭТА НЕДЕЛЯ'),
                            value: '$weekPct%',
                            color: AppColors.habits,
                          ),
                          const SizedBox(width: 12),
                          _MiniStat(
                            icon: Icons.repeat_rounded,
                            label: t('TOTAL', 'ВСЕГО'),
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

            // ── Weekly bar chart ───────────────────
            if (widget.total > 0) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(t('THIS WEEK', 'ЭТА НЕДЕЛЯ'), style: GoogleFonts.jetBrainsMono(
                    fontSize: 8, fontWeight: FontWeight.w700,
                    letterSpacing: 1.5, color: const Color(0xFF8A8070))),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final now = DateTime.now();
                    final monday = now.subtract(Duration(days: now.weekday - 1));
                    final day = monday.add(Duration(days: i));
                    final isToday = day.day == now.day && day.month == now.month;
                    final dayNames = [t('M','П'), t('T','В'), t('W','С'), t('T','Ч'), t('F','П'), t('S','С'), t('S','В')];

                    // Count how many habits were done on this day
                    final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                    int dayDone = 0;
                    for (final h in widget.habits) {
                      if (h.completedDates.contains(key)) dayDone++;
                    }
                    final maxH = widget.total;
                    final barPct = maxH == 0 ? 0.0 : (dayDone / maxH).clamp(0.0, 1.0);

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (dayDone > 0)
                              Text('$dayDone', style: GoogleFonts.jetBrainsMono(
                                fontSize: 7, fontWeight: FontWeight.w600,
                                color: const Color(0xFF8A8070))),
                            const SizedBox(height: 2),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: (barPct * 30).clamp(3.0, 30.0),
                              decoration: BoxDecoration(
                                color: barPct >= 1.0
                                    ? AppColors.success
                                    : barPct > 0
                                        ? AppColors.habits
                                        : const Color(0xFF2A2318).withAlpha(12),
                                borderRadius: BorderRadius.circular(4),
                                border: isToday
                                    ? Border.all(color: AppColors.habits.withAlpha(160), width: 1.2)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(dayNames[i], style: GoogleFonts.jetBrainsMono(
                              fontSize: 7, fontWeight: FontWeight.w600,
                              color: isToday
                                  ? AppColors.habits
                                  : const Color(0xFF8A8070).withAlpha(140))),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
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

// ── Habit Full Calendar (monthly, pie charts per day) ─────────────────────────

class _HabitCalendarBar extends StatefulWidget {
  final List<Habit> habits;
  const _HabitCalendarBar({required this.habits});

  @override
  State<_HabitCalendarBar> createState() => _HabitCalendarBarState();
}

class _HabitCalendarBarState extends State<_HabitCalendarBar> {
  late DateTime _month;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  static String _dk(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final habits = widget.habits;
    final total = habits.length;
    final months = [t('JANUARY','ЯНВАРЬ'),t('FEBRUARY','ФЕВРАЛЬ'),t('MARCH','МАРТ'),t('APRIL','АПРЕЛЬ'),t('MAY','МАЙ'),t('JUNE','ИЮНЬ'),
      t('JULY','ИЮЛЬ'),t('AUGUST','АВГУСТ'),t('SEPTEMBER','СЕНТЯБРЬ'),t('OCTOBER','ОКТЯБРЬ'),t('NOVEMBER','НОЯБРЬ'),t('DECEMBER','ДЕКАБРЬ')];

    final firstDay = DateTime(_month.year, _month.month, 1);
    final startWeekday = firstDay.weekday;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    const cardBg = Color(0xFFF5F2EB);
    const textCol = Color(0xFF2A2318);
    const subCol = Color(0xFF8A8070);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(15),
              blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.white.withAlpha(200),
              blurRadius: 1, offset: const Offset(0, -1)),
          ],
        ),
        child: Column(children: [
          // Month nav (tap center to expand/collapse)
          Row(children: [
            GestureDetector(
              onTap: _expanded
                ? () => setState(() => _month = DateTime(_month.year, _month.month - 1))
                : null,
              child: Icon(Icons.chevron_left_rounded, size: 22,
                color: _expanded ? textCol : textCol.withAlpha(60))),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _expanded = !_expanded);
              },
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${months[_month.month - 1]}  ${_month.year}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    letterSpacing: 2, color: textCol)),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.expand_more_rounded,
                    size: 18, color: textCol.withAlpha(160)),
                ),
              ]),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _expanded
                ? () => setState(() => _month = DateTime(_month.year, _month.month + 1))
                : null,
              child: Icon(Icons.chevron_right_rounded, size: 22,
                color: _expanded ? textCol : textCol.withAlpha(60))),
          ]),

          // Collapsible body — day headers + grid
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
              ? Column(children: [
                  const SizedBox(height: 14),
                  // Day headers
                  Row(children: [t('Mon','Пн'),t('Tue','Вт'),t('Wed','Ср'),t('Thu','Чт'),t('Fri','Пт'),t('Sat','Сб'),t('Sun','Вс')].map((d) =>
                    Expanded(child: Center(child: Text(d,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8, fontWeight: FontWeight.w600,
                        color: const Color(0xFF4C1D95).withAlpha(120)))))).toList()),
                  const SizedBox(height: 8),
                  ..._buildGrid(now, habits, total, subCol, textCol,
                    firstDay: firstDay, startWeekday: startWeekday, daysInMonth: daysInMonth),
                ])
              : const SizedBox.shrink(),
          ),
        ]),
      ),
    );
  }

  /// Weeks of the currently shown month (factored out so collapse stays clean).
  List<Widget> _buildGrid(DateTime now, List<Habit> habits, int total,
      Color subCol, Color textCol,
      {required DateTime firstDay, required int startWeekday, required int daysInMonth}) {
    return List.generate(6, (week) {
            return Row(
              children: List.generate(7, (dayOfWeek) {
                final dayIndex = week * 7 + dayOfWeek - (startWeekday - 1);
                if (dayIndex < 0 || dayIndex >= daysInMonth) {
                  return const Expanded(child: SizedBox(height: 38));
                }
                final day = dayIndex + 1;
                final date = DateTime(_month.year, _month.month, day);
                final key = _dk(date);
                final isToday = date.day == now.day &&
                    date.month == now.month && date.year == now.year;
                final isFuture = date.isAfter(now);

                // Per-category completion
                int dayDone = 0;
                final Map<HabitCategory, int> catDone = {};
                for (final h in habits) {
                  if (h.completedDates.contains(key)) {
                    dayDone++;
                    catDone[h.category] = (catDone[h.category] ?? 0) + 1;
                  }
                }
                final allDone = total > 0 && dayDone >= total;

                return Expanded(child: SizedBox(
                  height: 38,
                  child: Center(child: total == 0 || isFuture
                    ? Text('$day', style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isFuture ? subCol.withAlpha(50) : subCol))
                    : SizedBox(
                        width: 34, height: 34,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pie chart or empty circle
                            if (dayDone > 0)
                              CustomPaint(
                                size: const Size(34, 34),
                                painter: _PiePainter(
                                  categories: catDone,
                                  total: total,
                                  allDone: allDone,
                                ),
                              )
                            else
                              Container(width: 34, height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: textCol.withAlpha(8),
                                )),
                            // Today ring
                            if (isToday)
                              Container(width: 34, height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.habits, width: 2.5),
                                )),
                            // Day number
                            Text('$day', style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: isToday || allDone ? FontWeight.w700 : FontWeight.w500,
                              color: allDone ? Colors.white : textCol)),
                          ],
                        ),
                      ),
                  ),
                ));
              }),
            );
          });
  }
}

// ── Pie chart painter (category colors per day) ──────────────────────────────

class _PiePainter extends CustomPainter {
  final Map<HabitCategory, int> categories;
  final int total;
  final bool allDone;

  _PiePainter({required this.categories, required this.total, required this.allDone});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (allDone) {
      canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF22C55E));
      return;
    }

    // Background
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF2A2318).withAlpha(10));

    // Pie segments per category
    final totalDone = categories.values.fold(0, (s, v) => s + v);
    if (totalDone == 0) return;

    double startAngle = -pi / 2;
    for (final cat in HabitCategory.values) {
      final count = categories[cat] ?? 0;
      if (count == 0) continue;
      final sweep = (count / totalDone) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep, true,
        Paint()..color = habitCatColor(cat));
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) => true;
}

// ── Inline stat pill ─────────────────────────────────────────────────────────

class _InlineStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _InlineStat({required this.icon, required this.value,
    required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.jetBrainsMono(
            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(label, style: GoogleFonts.jetBrainsMono(
            fontSize: 7, fontWeight: FontWeight.w600,
            letterSpacing: 1, color: Colors.white.withAlpha(80))),
        ]),
      ),
    );
  }
}

// ── Done divider ─────────────────────────────────────────────────────────────

class _RoutineHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RoutineHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.white.withAlpha(120)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.jetBrainsMono(
          fontSize: 9, fontWeight: FontWeight.w700,
          letterSpacing: 2, color: Colors.white.withAlpha(120))),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: Colors.white.withAlpha(20))),
      ]),
    );
  }
}

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
                Text('${t('DONE', 'ГОТОВО')}  $count',
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
  final VoidCallback? onDetail;
  final VoidCallback? onNote;

  const _HabitCard({required this.habit, required this.onToggle, this.onDetail, this.onNote});

  @override
  Widget build(BuildContext context) {
    final done = habit.isDoneToday();
    final color = habitCatColor(habit.category);
    final streak = habit.streak;
    final hasSchedule = habit.scheduleDays.isNotEmpty;
    final weeklyDone = hasSchedule ? habit.weeklyScheduledDone : habit.weeklyCount;
    final weeklyTotal = habit.scheduledInWeek;

    const cardBg = Color(0xFFF5F2EB);
    const textCol = Color(0xFF2A2318);
    const subCol = Color(0xFF8A8070);

    return GestureDetector(
      onTap: onToggle,
      onLongPress: onDetail,
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
                              // 7-day bar (scheduled days stand out)
                              ...List.generate(7, (i) {
                                final d = DateTime.now().subtract(
                                    Duration(days: 6 - i));
                                final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                                final filled = habit.completedDates.contains(key);
                                final isToday = i == 6;
                                final scheduled = !hasSchedule ||
                                    habit.scheduleDays.contains(d.weekday);
                                const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 3),
                                  child: Column(mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: scheduled ? 6 : 3,
                                        decoration: BoxDecoration(
                                          color: filled
                                              ? color
                                              : scheduled
                                                  ? textCol.withAlpha(22)
                                                  : textCol.withAlpha(8),
                                          borderRadius: BorderRadius.circular(2),
                                          border: isToday && !filled && scheduled
                                              ? Border.all(
                                                  color: color.withAlpha(120),
                                                  width: 0.8)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(letters[d.weekday - 1],
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 7,
                                          fontWeight: scheduled
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: scheduled
                                              ? (isToday ? color : subCol)
                                              : subCol.withAlpha(70))),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(width: 6),
                              Text('$weeklyDone/$weeklyTotal',
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

                          // Timer indicator
                          if (habit.timerMinutes > 0) ...[
                            const SizedBox(height: 6),
                            Row(children: [
                              Icon(Icons.timer_rounded, size: 10, color: color),
                              const SizedBox(width: 4),
                              Text('${habit.timerMinutes} ${t('min', 'мин')}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8, fontWeight: FontWeight.w700, color: color)),
                            ]),
                          ],
                          // Schedule + routine
                          if (habit.scheduleDays.isNotEmpty || habit.routineSlot.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(children: [
                              if (habit.scheduleDays.isNotEmpty) ...[
                                Icon(Icons.repeat_rounded, size: 9, color: subCol),
                                const SizedBox(width: 3),
                                Text(habit.scheduleLabel,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8, fontWeight: FontWeight.w600, color: subCol)),
                              ],
                              if (habit.routineSlot.isNotEmpty) ...[
                                if (habit.scheduleDays.isNotEmpty) const SizedBox(width: 8),
                                Icon(
                                  habit.routineSlot == 'morning'
                                      ? Icons.wb_sunny_rounded
                                      : Icons.nightlight_round,
                                  size: 9, color: subCol),
                                const SizedBox(width: 3),
                                Text(habit.routineSlot == 'morning' ? t('MORNING', 'УТРО') : t('EVENING', 'ВЕЧЕР'),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8, fontWeight: FontWeight.w600, color: subCol)),
                              ],
                            ]),
                          ],
                          // Note indicator
                          if (done && onNote != null) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: onNote,
                              child: Row(children: [
                                Icon(Icons.edit_note_rounded, size: 12, color: subCol.withAlpha(120)),
                                const SizedBox(width: 4),
                                Text(
                                  habit.notes[Habit.dateKeyPublic(DateTime.now())]?.isNotEmpty == true
                                      ? t('View note', 'Посмотреть заметку') : t('Add note', 'Добавить заметку'),
                                  style: GoogleFonts.inter(
                                    fontSize: 9, fontWeight: FontWeight.w500,
                                    color: subCol.withAlpha(120))),
                              ]),
                            ),
                          ],
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
            Text(t('no habits yet', 'привычек пока нет'),
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(200),
              )),
            const SizedBox(height: 6),
            Text(t('build your daily routine', 'создай свой распорядок дня'),
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
  final Set<int> _days = {}; // empty = every day
  String _routine = ''; // '', 'morning', 'evening'
  int _timer = 0; // minutes, 0 = no timer

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
      scheduleDays: _days.toList()..sort(),
      routineSlot: _routine,
      timerMinutes: _timer,
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
                              Text(t('NEW HABIT', 'НОВАЯ ПРИВЫЧКА'),
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2, color: _kCocoa,
                                )),
                              Text('+${Habit(id: '', title: '', createdAt: DateTime.now()).xpPerCheck} ${t('XP / day', 'XP / день')}',
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

                    // ── Quick-add presets ───────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                      child: Wrap(
                        spacing: 6, runSpacing: 6,
                        children: [
                          (t('Meditate', 'Медитация'), Icons.self_improvement_rounded, HabitCategory.mindset),
                          (t('Drink Water', 'Пить воду'), Icons.water_drop_rounded, HabitCategory.health),
                          (t('Exercise', 'Упражнения'), Icons.fitness_center_rounded, HabitCategory.health),
                          (t('Read', 'Чтение'), Icons.menu_book_rounded, HabitCategory.productivity),
                          (t('Journal', 'Дневник'), Icons.edit_note_rounded, HabitCategory.mindset),
                          (t('Walk', 'Прогулка'), Icons.directions_walk_rounded, HabitCategory.health),
                        ].map((p) {
                          final (label, icon, cat) = p;
                          return GestureDetector(
                            onTap: () {
                              _ctrl.text = label;
                              setState(() => _cat = cat);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _kRowBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _kDivider)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(icon, size: 12, color: habitCatColor(cat)),
                                const SizedBox(width: 5),
                                Text(label, style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: _kCocoa.withAlpha(160))),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: _kDivider),

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
                                hintText: t('e.g. Meditate 10 min', 'напр. Медитация 10 мин'),
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
                              Text(t('CATEGORY', 'КАТЕГОРИЯ'),
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

                    // ── Timer ────────────────────────────────
                    Divider(height: 1, thickness: 1, color: _kDivider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                      child: Row(children: [
                        Icon(Icons.timer_rounded, size: 12, color: _kCocoa.withAlpha(130)),
                        const SizedBox(width: 6),
                        Text(t('TIMER', 'ТАЙМЕР'), style: GoogleFonts.inter(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          letterSpacing: 1.2, color: _kCocoa.withAlpha(140))),
                        const Spacer(),
                        ...([0, 5, 10, 15, 30].map((m) {
                          final active = _timer == m;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => _timer = m),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: active ? AppColors.habits.withAlpha(20) : _kRowBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: active ? AppColors.habits.withAlpha(120) : _kDivider)),
                                child: Text(m == 0 ? t('OFF', 'ВЫКЛ') : '${m}${t('m', 'м')}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9, fontWeight: FontWeight.w700,
                                    color: active ? AppColors.habits : _kCocoa.withAlpha(100))),
                              ),
                            ),
                          );
                        })),
                      ]),
                    ),

                    // ── Schedule days ────────────────────────
                    Divider(height: 1, thickness: 1, color: _kDivider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.calendar_today_rounded, size: 12,
                                color: _kCocoa.withAlpha(130)),
                            const SizedBox(width: 6),
                            Text(t('REPEAT', 'ПОВТОР'), style: GoogleFonts.inter(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              letterSpacing: 1.2, color: _kCocoa.withAlpha(140))),
                            const Spacer(),
                            Text(_days.isEmpty ? t('Every day', 'Каждый день') : '${_days.length} ${t('days', 'дн.')}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9, fontWeight: FontWeight.w600,
                                color: _kCocoa.withAlpha(100))),
                          ]),
                          const SizedBox(height: 10),
                          Row(
                            children: [1, 2, 3, 4, 5, 6, 7].map((d) {
                              final active = _days.contains(d);
                              final labels = ['', t('M','П'), t('T','В'), t('W','С'), t('T','Ч'), t('F','П'), t('S','С'), t('S','В')];
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    if (active) { _days.remove(d); }
                                    else { _days.add(d); }
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: EdgeInsets.only(right: d < 7 ? 4 : 0),
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.habits.withAlpha(25)
                                          : _kRowBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: active
                                            ? AppColors.habits.withAlpha(120)
                                            : _kDivider),
                                    ),
                                    child: Center(
                                      child: Text(labels[d],
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10, fontWeight: FontWeight.w700,
                                          color: active
                                              ? AppColors.habits
                                              : _kCocoa.withAlpha(100))),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // ── Routine slot ─────────────────────────
                    Divider(height: 1, thickness: 1, color: _kDivider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.wb_sunny_rounded, size: 12,
                                color: _kCocoa.withAlpha(130)),
                            const SizedBox(width: 6),
                            Text(t('ROUTINE', 'РАСПОРЯДОК'), style: GoogleFonts.inter(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              letterSpacing: 1.2, color: _kCocoa.withAlpha(140))),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            _RoutineChip(label: t('MORNING', 'УТРО'), icon: Icons.wb_sunny_rounded,
                              active: _routine == 'morning',
                              onTap: () => setState(() => _routine = _routine == 'morning' ? '' : 'morning')),
                            const SizedBox(width: 8),
                            _RoutineChip(label: t('EVENING', 'ВЕЧЕР'), icon: Icons.nightlight_round,
                              active: _routine == 'evening',
                              onTap: () => setState(() => _routine = _routine == 'evening' ? '' : 'evening')),
                          ]),
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
                              Text(t('CREATE HABIT', 'СОЗДАТЬ ПРИВЫЧКУ'),
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

// ── Edit habit sheet (title / category / schedule / routine / timer / delete) ─

class _EditHabitSheet extends StatefulWidget {
  final Habit habit;
  const _EditHabitSheet({required this.habit});

  @override
  State<_EditHabitSheet> createState() => _EditHabitSheetState();
}

class _EditHabitSheetState extends State<_EditHabitSheet> {
  late final TextEditingController _ctrl;
  late HabitCategory _cat;
  late Set<int> _days;
  late String _routine;
  late int _timer;

  static const _kSheetBg = Color(0xFFF5F1E8);
  static const _kRowBg   = Color(0xFFEFEBE0);
  static const _kDivider = Color(0xFFDDD8CB);
  static const _kCocoa   = Color(0xFF594536);

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _ctrl = TextEditingController(text: h.title);
    _cat = h.category;
    _days = h.scheduleDays.toSet();
    _routine = h.routineSlot;
    _timer = h.timerMinutes;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _save() {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return;
    HapticFeedback.mediumImpact();
    final h = widget.habit;
    h.title = title;
    h.category = _cat;
    h.scheduleDays
      ..clear()
      ..addAll(_days.toList()..sort());
    h.routineSlot = _routine;
    h.timerMinutes = _timer;
    Navigator.pop(context, true);
  }

  void _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t('Delete habit?', 'Удалить привычку?'),
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: _kCocoa)),
        content: Text(t('All check-ins and notes will be lost.',
            'Все отметки и заметки будут удалены.'),
          style: GoogleFonts.inter(fontSize: 13, color: _kCocoa.withAlpha(180))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('Cancel', 'Отмена'),
              style: GoogleFonts.inter(color: _kCocoa.withAlpha(160)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('Delete', 'Удалить'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDC2626)))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    HabitStore.habits.removeWhere((x) => x.id == widget.habit.id);
    if (mounted) {
      Navigator.pop(context, true); // close edit sheet
      Navigator.pop(context);        // close detail view (back to list)
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final kb = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 40, 12, kb > 0 ? kb + 12 : 40),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: sw < 420 ? sw - 24 : 380,
              decoration: BoxDecoration(
                color: _kSheetBg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(90),
                  blurRadius: 40, offset: const Offset(6, 8))],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.habits.withAlpha(25),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28))),
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      child: Row(children: [
                        Container(width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.habits,
                            borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 18)),
                        const SizedBox(width: 10),
                        Text(t('EDIT HABIT', 'РЕДАКТИРОВАТЬ'),
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            letterSpacing: 1.2, color: _kCocoa)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context, false),
                          child: Container(width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: _kDivider,
                              borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.close_rounded,
                                color: _kCocoa.withAlpha(150), size: 14))),
                      ]),
                    ),

                    // Title field
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kRowBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kDivider)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: TextField(
                          controller: _ctrl,
                          style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: _kCocoa),
                          decoration: InputDecoration(
                            hintText: t('Title', 'Название'),
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14, color: _kCocoa.withAlpha(100)),
                            border: InputBorder.none,
                            isDense: true),
                          onSubmitted: (_) => _save(),
                        ),
                      ),
                    ),

                    // Category picker
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                      child: Row(
                        children: HabitCategory.values.map((c) {
                          final active = _cat == c;
                          final col = habitCatColor(c);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: GestureDetector(
                                onTap: () => setState(() => _cat = c),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: active ? col.withAlpha(35) : _kRowBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: active ? col : _kDivider,
                                      width: active ? 1.4 : 1)),
                                  child: Column(children: [
                                    Icon(habitCatIcon(c), size: 14,
                                        color: active ? col : _kCocoa.withAlpha(140)),
                                    const SizedBox(height: 3),
                                    Text(habitCatLabel(c),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 7.5, fontWeight: FontWeight.w700,
                                        color: active ? col : _kCocoa.withAlpha(140))),
                                  ]),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Schedule days
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.calendar_today_rounded,
                              size: 12, color: _kCocoa.withAlpha(130)),
                            const SizedBox(width: 6),
                            Text(_days.isEmpty
                              ? t('Every day', 'Каждый день')
                              : '${_days.length} ${t('days', 'дн.')}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9, fontWeight: FontWeight.w600,
                                color: _kCocoa.withAlpha(150))),
                          ]),
                          const SizedBox(height: 6),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [for (final d in [1,2,3,4,5,6,7]) ...[
                              GestureDetector(
                                onTap: () => setState(() {
                                  if (_days.contains(d)) {
                                    _days.remove(d);
                                  } else {
                                    _days.add(d);
                                  }
                                }),
                                child: Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _days.contains(d)
                                      ? habitCatColor(_cat).withAlpha(40)
                                      : _kRowBg,
                                    border: Border.all(
                                      color: _days.contains(d)
                                        ? habitCatColor(_cat)
                                        : _kDivider,
                                      width: _days.contains(d) ? 1.4 : 1)),
                                  child: Center(
                                    child: Text(
                                      [t('M','П'),t('T','В'),t('W','С'),t('T','Ч'),t('F','П'),t('S','С'),t('S','В')][d-1],
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10, fontWeight: FontWeight.w700,
                                        color: _days.contains(d)
                                          ? habitCatColor(_cat)
                                          : _kCocoa.withAlpha(160))),
                                  ),
                                ),
                              ),
                            ]],
                          ),
                        ],
                      ),
                    ),

                    // Routine slot
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                      child: Row(children: [
                        for (final entry in [
                          (slot: '', label: t('ANYTIME', 'В ЛЮБОЕ'), icon: Icons.all_inclusive_rounded),
                          (slot: 'morning', label: t('MORNING', 'УТРО'), icon: Icons.wb_sunny_rounded),
                          (slot: 'evening', label: t('EVENING', 'ВЕЧЕР'), icon: Icons.nights_stay_rounded),
                        ]) Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: GestureDetector(
                              onTap: () => setState(() => _routine = entry.slot),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _routine == entry.slot
                                    ? AppColors.habits.withAlpha(30)
                                    : _kRowBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _routine == entry.slot
                                      ? AppColors.habits
                                      : _kDivider,
                                    width: _routine == entry.slot ? 1.4 : 1)),
                                child: Column(children: [
                                  Icon(entry.icon, size: 13,
                                    color: _routine == entry.slot
                                      ? AppColors.habits
                                      : _kCocoa.withAlpha(140)),
                                  const SizedBox(height: 3),
                                  Text(entry.label,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 7.5, fontWeight: FontWeight.w700,
                                      color: _routine == entry.slot
                                        ? AppColors.habits
                                        : _kCocoa.withAlpha(140))),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),

                    // Timer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.timer_outlined,
                              size: 12, color: _kCocoa.withAlpha(130)),
                            const SizedBox(width: 6),
                            Text(_timer == 0
                              ? t('No timer', 'Без таймера')
                              : '$_timer ${t('min', 'мин')}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9, fontWeight: FontWeight.w600,
                                color: _kCocoa.withAlpha(150))),
                          ]),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, runSpacing: 6,
                            children: [0, 5, 10, 15, 20, 30, 45, 60].map((m) {
                              final active = _timer == m;
                              return GestureDetector(
                                onTap: () => setState(() => _timer = m),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: active
                                      ? AppColors.habits.withAlpha(35)
                                      : _kRowBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: active
                                        ? AppColors.habits
                                        : _kDivider,
                                      width: active ? 1.4 : 1)),
                                  child: Text(m == 0 ? t('off', 'выкл') : '${m}m',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      color: active
                                        ? AppColors.habits
                                        : _kCocoa.withAlpha(140))),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, thickness: 1, color: _kDivider),

                    // Action row: delete + save
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: Row(children: [
                        GestureDetector(
                          onTap: _confirmDelete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withAlpha(25),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFDC2626).withAlpha(80))),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: Color(0xFFDC2626)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _save,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.habits,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(
                                  color: AppColors.habits.withAlpha(90),
                                  blurRadius: 12, offset: const Offset(0, 4))]),
                              child: Center(
                                child: Text(t('SAVE', 'СОХРАНИТЬ'),
                                  style: GoogleFonts.inter(
                                    fontSize: 12, fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ]),
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

// ── Habit detail view (calendar + stats) ─────────────────────────────────────

class _HabitDetailView extends StatefulWidget {
  final Habit habit;
  final VoidCallback onToggle;
  const _HabitDetailView({required this.habit, required this.onToggle});
  @override
  State<_HabitDetailView> createState() => _HabitDetailViewState();
}

class _HabitDetailViewState extends State<_HabitDetailView> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  static String _dk(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final color = habitCatColor(h.category);
    final now = DateTime.now();
    const cardBg = Color(0xFFF5F2EB);
    const textCol = Color(0xFF2A2318);
    const subCol = Color(0xFF8A8070);

    // Calendar grid
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final startWeekday = firstDay.weekday; // 1=Mon
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final months = [t('JANUARY','ЯНВАРЬ'),t('FEBRUARY','ФЕВРАЛЬ'),t('MARCH','МАРТ'),t('APRIL','АПРЕЛЬ'),t('MAY','МАЙ'),t('JUNE','ИЮНЬ'),
      t('JULY','ИЮЛЬ'),t('AUGUST','АВГУСТ'),t('SEPTEMBER','СЕНТЯБРЬ'),t('OCTOBER','ОКТЯБРЬ'),t('NOVEMBER','НОЯБРЬ'),t('DECEMBER','ДЕКАБРЬ')];

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(180),
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(30))),
                  child: Icon(Icons.close_rounded, size: 20,
                      color: Colors.white.withAlpha(200)))),
              const SizedBox(width: 14),
              Expanded(child: Text(h.title, style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic, color: Colors.white),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final changed = await showDialog<bool>(
                    context: context, barrierColor: Colors.black.withAlpha(180),
                    builder: (_) => _EditHabitSheet(habit: h));
                  if (changed == true && mounted) setState(() {});
                },
                child: Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withAlpha(80))),
                  child: Icon(Icons.edit_rounded, size: 18, color: color))),
            ]),
          ),

          const SizedBox(height: 20),

          // Main card
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              // ── Stats row ──────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(25),
                    blurRadius: 12, offset: const Offset(0, 5))]),
                child: Row(children: [
                  _DetailStat(value: '${h.streak}', label: t('STREAK', 'СЕРИЯ'),
                    icon: Icons.local_fire_department_rounded,
                    color: h.streak >= 7 ? AppColors.action : const Color(0xFFF59E0B)),
                  _DetailStat(value: '${h.weeklyCount}/7', label: t('THIS WEEK', 'ЭТА НЕДЕЛЯ'),
                    icon: Icons.insights_rounded, color: color),
                  _DetailStat(value: '${h.completedDates.length}', label: t('TOTAL', 'ВСЕГО'),
                    icon: Icons.check_circle_rounded, color: AppColors.success),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Calendar ───────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(25),
                    blurRadius: 12, offset: const Offset(0, 5))]),
                child: Column(children: [
                  // Month nav
                  Row(children: [
                    GestureDetector(
                      onTap: () => setState(() => _viewMonth = DateTime(
                          _viewMonth.year, _viewMonth.month - 1)),
                      child: Icon(Icons.chevron_left_rounded, size: 22, color: textCol)),
                    const Spacer(),
                    Text('${months[_viewMonth.month - 1]}  ${_viewMonth.year}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        letterSpacing: 2, color: textCol)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _viewMonth = DateTime(
                          _viewMonth.year, _viewMonth.month + 1)),
                      child: Icon(Icons.chevron_right_rounded, size: 22, color: textCol)),
                  ]),
                  const SizedBox(height: 14),

                  // Day headers
                  Row(children: [t('Mon','Пн'),t('Tue','Вт'),t('Wed','Ср'),t('Thu','Чт'),t('Fri','Пт'),t('Sat','Сб'),t('Sun','Вс')].map((d) =>
                    Expanded(child: Center(child: Text(d,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8, fontWeight: FontWeight.w600,
                        color: subCol.withAlpha(140)))))).toList()),
                  const SizedBox(height: 8),

                  // Calendar grid
                  ...List.generate(6, (week) {
                    return Row(
                      children: List.generate(7, (dayOfWeek) {
                        final dayIndex = week * 7 + dayOfWeek - (startWeekday - 1);
                        if (dayIndex < 0 || dayIndex >= daysInMonth) {
                          return const Expanded(child: SizedBox(height: 36));
                        }
                        final day = dayIndex + 1;
                        final date = DateTime(_viewMonth.year, _viewMonth.month, day);
                        final key = _dk(date);
                        final done = h.completedDates.contains(key);
                        final isToday = date.day == now.day &&
                            date.month == now.month && date.year == now.year;
                        final isFuture = date.isAfter(now);

                        return Expanded(child: GestureDetector(
                          onTap: isFuture ? null : () {
                            setState(() {
                              if (done) { h.completedDates.remove(key); }
                              else { h.completedDates.add(key); }
                            });
                          },
                          child: Container(
                            height: 36,
                            margin: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              color: done
                                  ? color
                                  : isToday
                                      ? color.withAlpha(15)
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isToday && !done
                                  ? Border.all(color: color.withAlpha(120), width: 1.5)
                                  : null,
                            ),
                            child: Center(child: Text('$day',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: done || isToday ? FontWeight.w700 : FontWeight.w500,
                                color: done
                                    ? Colors.white
                                    : isFuture
                                        ? subCol.withAlpha(60)
                                        : textCol))),
                          ),
                        ));
                      }),
                    );
                  }),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Info card ──────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(25),
                    blurRadius: 12, offset: const Offset(0, 5))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(habitCatIcon(h.category), size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(habitCatLabel(h.category), style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      letterSpacing: 1, color: color)),
                    const Spacer(),
                    Text(h.scheduleLabel, style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, fontWeight: FontWeight.w600, color: subCol)),
                  ]),
                  if (h.routineSlot.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(h.routineSlot == 'morning'
                          ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        size: 12, color: subCol),
                      const SizedBox(width: 4),
                      Text('${h.routineSlot == 'morning' ? t('MORNING', 'УТРО') : t('EVENING', 'ВЕЧЕР')} ${t('ROUTINE', 'РАСПОРЯДОК')}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8, fontWeight: FontWeight.w600, color: subCol)),
                    ]),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withAlpha(15),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text('+${h.xpPerCheck} ${t('XP per check-in', 'XP за отметку')}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gold)),
                  ),
                ]),
              ),
            ],
          )),
        ]),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _DetailStat({required this.value, required this.label,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.jetBrainsMono(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: const Color(0xFF2A2318))),
      Text(label, style: GoogleFonts.jetBrainsMono(
        fontSize: 7, fontWeight: FontWeight.w600,
        letterSpacing: 1.5, color: const Color(0xFF8A8070))),
    ]));
  }
}

// ── Routine chip ─────────────────────────────────────────────────────────────

class _RoutineChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _RoutineChip({required this.label, required this.icon,
    required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const cocoa = Color(0xFF594536);
    const divider = Color(0xFFDDD8CB);
    const rowBg = Color(0xFFEFEBE0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.habits.withAlpha(20) : rowBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.habits.withAlpha(120) : divider),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: active ? AppColors.habits : cocoa.withAlpha(100)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.jetBrainsMono(
            fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            color: active ? AppColors.habits : cocoa.withAlpha(130))),
        ]),
      ),
    );
  }
}

// ── Check-in celebration overlay ─────────────────────────────────────────────

class _CheckCelebration extends StatefulWidget {
  final Color color;
  final VoidCallback onDone;
  const _CheckCelebration({required this.color, required this.onDone});
  @override
  State<_CheckCelebration> createState() => _CheckCelebrationState();
}

class _CheckCelebrationState extends State<_CheckCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))
      ..forward().then((_) => widget.onDone());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final v = _ctrl.value;
        final sz = MediaQuery.of(context).size;
        return Positioned.fill(child: IgnorePointer(child: Stack(
          children: [
            // Scale bounce checkmark
            Center(child: Opacity(
              opacity: (1 - v * 1.5).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.5 + Curves.elasticOut.transform((v * 2).clamp(0.0, 1.0)) * 1.5,
                child: Icon(Icons.check_circle_rounded,
                    size: 60, color: widget.color.withAlpha(180))),
            )),
            // Mini confetti
            ...List.generate(12, (i) {
              final seed = i * 73.7;
              final angle = (i / 12) * 2 * pi;
              final dist = v * 80 + sin(seed) * 20;
              final x = sz.width / 2 + cos(angle) * dist;
              final y = sz.height / 2 + sin(angle) * dist - v * 40;
              return Positioned(
                left: x - 3, top: y - 3,
                child: Opacity(
                  opacity: (1 - v * 1.3).clamp(0.0, 1.0),
                  child: Container(width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: i % 2 == 0 ? widget.color : AppColors.gold,
                      borderRadius: BorderRadius.circular(i % 3 == 0 ? 1 : 3)))),
              );
            }),
          ],
        )));
      },
    );
  }
}

// ── Streak milestone overlay ─────────────────────────────────────────────────

class _StreakMilestone extends StatefulWidget {
  final int streak;
  final VoidCallback onDone;
  const _StreakMilestone({required this.streak, required this.onDone});
  @override
  State<_StreakMilestone> createState() => _StreakMilestoneState();
}

class _StreakMilestoneState extends State<_StreakMilestone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2500))
      ..forward().then((_) => widget.onDone());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final v = _ctrl.value;
        final bgOp = v < 0.1 ? v / 0.1 : v > 0.8 ? 1 - (v - 0.8) / 0.2 : 1.0;
        final scale = Curves.elasticOut.transform(
            ((v - 0.05) / 0.3).clamp(0.0, 1.0));
        final textOp = v < 0.1 ? 0.0 : v > 0.8 ? 1 - (v - 0.8) / 0.2 : 1.0;

        return Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: bgOp.clamp(0.0, 1.0),
              child: Container(
                color: Colors.black.withAlpha(160),
                child: Center(
                  child: Opacity(
                    opacity: textOp.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale.clamp(0.0, 1.5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 56, color: AppColors.action),
                          const SizedBox(height: 12),
                          Text('${widget.streak} ${t('DAY', 'ДЕНЬ')}',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 42, fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: AppColors.gold, height: 1)),
                          Text(t('STREAK', 'СЕРИЯ'),
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 42, fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.white, height: 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Habit Timer Screen ───────────────────────────────────────────────────────

class _HabitTimerScreen extends StatefulWidget {
  final Habit habit;
  final VoidCallback onComplete;
  const _HabitTimerScreen({required this.habit, required this.onComplete});

  @override
  State<_HabitTimerScreen> createState() => _HabitTimerScreenState();
}

class _HabitTimerScreenState extends State<_HabitTimerScreen>
    with TickerProviderStateMixin {
  late int _secondsLeft;
  late final int _totalSeconds;
  bool _running = false;
  bool _finished = false;
  late final AnimationController _tick;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.habit.timerMinutes * 60;
    _secondsLeft = _totalSeconds;
    _tick = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && _running) {
          setState(() {
            _secondsLeft--;
            if (_secondsLeft <= 0) {
              _running = false;
              _finished = true;
              HapticFeedback.heavyImpact();
            } else {
              _tick.forward(from: 0);
            }
          });
        }
      });
  }

  @override
  void dispose() { _tick.dispose(); super.dispose(); }

  void _start() {
    setState(() => _running = true);
    _tick.forward(from: 0);
  }

  void _pause() {
    setState(() => _running = false);
    _tick.stop();
  }

  String get _timeDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => _totalSeconds == 0 ? 0.0
      : 1.0 - (_secondsLeft / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    final color = habitCatColor(widget.habit.category);

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(200),
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withAlpha(30))),
                    child: Icon(Icons.close_rounded, size: 20,
                        color: Colors.white.withAlpha(200))),
                ),
              ),
            ),

            const Spacer(),

            // Habit title
            Text(widget.habit.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: Colors.white)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(60))),
              child: Text(habitCatLabel(widget.habit.category),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8, fontWeight: FontWeight.w700,
                  letterSpacing: 1, color: color)),
            ),

            const SizedBox(height: 40),

            // Timer ring
            SizedBox(
              width: 200, height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200, height: 200,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withAlpha(15),
                      valueColor: AlwaysStoppedAnimation(
                          _finished ? AppColors.success : color),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_finished ? '✓' : _timeDisplay,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: _finished ? 48 : 40,
                          fontWeight: FontWeight.w700,
                          color: _finished ? AppColors.success : Colors.white)),
                      if (!_finished)
                        Text(t('REMAINING', 'ОСТАЛОСЬ'),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: Colors.white.withAlpha(80))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Controls
            if (_finished)
              GestureDetector(
                onTap: widget.onComplete,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: AppColors.success.withAlpha(80),
                      blurRadius: 20, offset: const Offset(0, 6))]),
                  child: Center(child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(t('COMPLETE', 'ЗАВЕРШИТЬ'),
                        style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          letterSpacing: 1, color: Colors.white)),
                      const SizedBox(width: 10),
                      Text('+${widget.habit.xpPerCheck} XP',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: Colors.white.withAlpha(200))),
                    ],
                  )),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Start/Pause
                  GestureDetector(
                    onTap: _running ? _pause : _start,
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: color.withAlpha(80),
                          blurRadius: 16, spreadRadius: 2)]),
                      child: Icon(
                        _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Reset
                  GestureDetector(
                    onTap: () => setState(() {
                      _running = false;
                      _tick.stop();
                      _secondsLeft = _totalSeconds;
                    }),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(30))),
                      child: Icon(Icons.refresh_rounded, size: 22,
                          color: Colors.white.withAlpha(180)),
                    ),
                  ),
                ],
              ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

