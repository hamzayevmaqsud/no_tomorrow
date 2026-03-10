import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/task.dart';
import '../models/game_state.dart';
import '../models/collection_state.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';

// ── In-memory store ───────────────────────────────────────────────────────────

// ignore: library_private_types_in_public_api
class TaskStore {
  static final List<Task> tasks = [];
  static int nextId = 1;
}

// ── Priority helpers ──────────────────────────────────────────────────────────

Color _pColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:   return const Color(0xFFFF1744);
    case TaskPriority.medium: return const Color(0xFFFFD600);
    case TaskPriority.low:    return const Color(0xFF00E676);
  }
}

String _pLabel(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:   return 'Critical';
    case TaskPriority.medium: return 'Normal';
    case TaskPriority.low:    return 'Light';
  }
}

int _pXp(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:   return 50;
    case TaskPriority.medium: return 25;
    case TaskPriority.low:    return 10;
  }
}

// ── Theme helpers ─────────────────────────────────────────────────────────────

Color _bg(bool dark)          => dark ? const Color(0xFF0D0D16) : const Color(0xFFBEC1DC);
Color _cardBg(bool dark)      => dark ? AppColors.darkCard      : const Color(0xFFFFFFFF);
Color _cardBorder(bool dark)  => dark ? AppColors.darkBorder    : const Color(0xFFB8BACD);
Color _textPrimary(bool dark) => dark ? AppColors.darkText      : AppColors.lightText;
Color _textSub(bool dark)     => dark ? AppColors.darkTextSub   : AppColors.lightTextSub;
Color _divider(bool dark)     => dark ? AppColors.darkBorder    : const Color(0xFFDDDDEE);

// ── Time / date formatters ────────────────────────────────────────────────────

String _fmt24(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _fmtDate(DateTime d) {
  const mo = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
  return '${mo[d.month - 1]} ${d.day}';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TasksScreen extends StatefulWidget {
  final TaskCategory category;
  const TasksScreen({super.key, required this.category});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  DateTime? _selectedDate;
  bool _showDashboard = false;

  List<Task> get _tasks =>
      TaskStore.tasks.where((t) => t.category == widget.category).toList();

  List<Task> get _filteredTasks {
    if (_selectedDate == null) return _tasks;
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == _selectedDate!.year &&
             t.dueDate!.month == _selectedDate!.month &&
             t.dueDate!.day == _selectedDate!.day;
    }).toList();
  }

  Future<void> _complete(Task task) async {
    if (task.isCompleted) return;
    HapticFeedback.mediumImpact();
    setState(() => task.isCompleted = true);
    final color        = _pColor(task.priority);
    final fromProgress = GameState.instance.levelProgress;
    final fromLevel    = GameState.instance.level;
    final didLevelUp   = GameState.instance.addXp(task.xp);
    final toProgress   = didLevelUp ? 1.0 : GameState.instance.levelProgress;
    _showXp(task.xp, color,
        fromProgress: fromProgress, toProgress: toProgress, level: fromLevel);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() {});
    if (didLevelUp) {
      final levelsGained = GameState.instance.level - fromLevel;
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      await _showLevelUp(GameState.instance.level);
      if (!mounted) return;
      for (int i = 0; i < levelsGained; i++) {
        final dropped = CollectionState.instance.onLevelUp();
        if (dropped != null && mounted) {
          await _showCollectibleDrop(dropped);
          if (!mounted) return;
        }
      }
      if (GameState.instance.levelProgress > 0) {
        _showXp(0, color,
            fromProgress: 0.0,
            toProgress: GameState.instance.levelProgress,
            level: GameState.instance.level);
      }
    }
  }

  void _delete(String id) {
    HapticFeedback.lightImpact();
    setState(() => TaskStore.tasks.removeWhere((t) => t.id == id));
  }

  void _showXp(int xp, Color color,
      {required double fromProgress,
      required double toProgress,
      required int level}) {
    final overlay = Overlay.of(context);
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => _XpBarOverlay(
        xp: xp, color: color,
        fromProgress: fromProgress, toProgress: toProgress,
        level: level,
        onDone: () => e.remove(),
      ),
    );
    overlay.insert(e);
  }

  Future<void> _showLevelUp(int level) {
    final completer = Completer<void>();
    final overlay = Overlay.of(context);
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => _LevelUpOverlay(level: level, onDone: () {
        e.remove();
        if (!completer.isCompleted) completer.complete();
      }),
    );
    overlay.insert(e);
    return completer.future;
  }

  Future<void> _showCollectibleDrop(CollectionItem item) {
    final completer = Completer<void>();
    final overlay = Overlay.of(context);
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => _CollectibleDropOverlay(item: item, onDone: () {
        e.remove();
        if (!completer.isCompleted) completer.complete();
      }),
    );
    overlay.insert(e);
    return completer.future;
  }

  void _showDetail(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskDetailSheet(
        task: task,
        onComplete: () {
          Navigator.pop(context);
          _complete(task);
        },
        onDelete: () {
          Navigator.pop(context);
          _delete(task.id);
        },
      ),
    );
  }

  void _showAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSheet(
        onAdd: (task) {
          task.category = widget.category;
          setState(() => TaskStore.tasks.insert(0, task));
          Navigator.pop(context);
        },
        nextId: '${TaskStore.nextId++}',
        preselectedDate: _selectedDate,
      ),
    );
  }

  Widget _dismissible(Task task, bool isDark) => Dismissible(
    key: ValueKey('${task.id}_${task.isCompleted}'),
    direction: DismissDirection.endToStart,
    onDismissed: (_) => _delete(task.id),
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 18),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(isDark ? 15 : 25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
    ),
    child: _TaskCard(
      key: ValueKey('k_${task.id}'),
      task: task,
      onComplete: () => _complete(task),
      onTap: () => _showDetail(task),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total  = _tasks.length;
    final done   = _tasks.where((t) => t.isCompleted).length;
    final filtered = _filteredTasks;
    final pending   = filtered.where((t) => !t.isCompleted).toList();
    final completed = filtered.where((t) => t.isCompleted).toList();

    final isWork = widget.category == TaskCategory.work;
    final bgImage = isWork
        ? 'assets/collection/Tasks menu/Work.jpg'
        : 'assets/collection/Tasks menu/Live.jpg';
    final categoryBg   = isWork ? const Color(0xFF24201D) : const Color(0xFF080F0C);
    final bgImgOpacity = isWork ? 0.15 : 0.26;

    return SwipeToPop(child: Scaffold(
      backgroundColor: isDark ? categoryBg : _bg(isDark),
      body: Stack(
        children: [
          // ── Blurred bg ──────────────────────────────────────────────────
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Opacity(
                opacity: bgImgOpacity,
                child: Image.asset(bgImage, fit: BoxFit.cover),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            border: Border.all(color: _cardBorder(isDark)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 15, color: _textPrimary(isDark)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MISSIONS',
                              style: GoogleFonts.inter(
                                fontSize: 20, fontWeight: FontWeight.w700,
                                letterSpacing: 1.5, color: AppColors.tasks,
                              )),
                            if (total > 0)
                              Text('$done of $total done',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9, color: _textSub(isDark),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Progress bar ─────────────────────────────────────────
                const SizedBox(height: 14),
                Stack(children: [
                  Container(height: 1, color: _divider(isDark)),
                  if (total > 0)
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      widthFactor: done / total,
                      child: Container(height: 1, color: AppColors.tasks),
                    ),
                ]),

                const SizedBox(height: 16),

                // ── Calendar strip ───────────────────────────────────────
                _CalendarStrip(
                  selectedDate: _selectedDate,
                  onDateSelected: (d) => setState(() {
                    _selectedDate = (_selectedDate != null &&
                        _selectedDate!.day == d.day &&
                        _selectedDate!.month == d.month &&
                        _selectedDate!.year == d.year)
                        ? null
                        : d;
                  }),
                  accentColor: AppColors.tasks,
                  isDark: isDark,
                ),

                const SizedBox(height: 12),

                // ── Dashboard panel ───────────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: _showDashboard
                      ? _DashboardPanel(
                          tasks: _tasks,
                          isDark: isDark,
                          accentColor: AppColors.tasks,
                        )
                      : const SizedBox.shrink(),
                ),

                // ── Task list ─────────────────────────────────────────────
                Expanded(
                  child: pending.isEmpty && completed.isEmpty
                      ? _Empty(isDark: isDark, hasDateFilter: _selectedDate != null)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          children: [
                            ...pending.map((t) => _dismissible(t, isDark)),
                            if (completed.isNotEmpty) ...[
                              _DoneDivider(count: completed.length),
                              ...completed.map((t) => _dismissible(t, isDark)),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),

          // ── Bottom bar ───────────────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _BottomBar(
              onAdd: _showAdd,
              isDark: isDark,
              dashboardActive: _showDashboard,
              onDashboard: () => setState(() => _showDashboard = !_showDashboard),
            ),
          ),
        ],
      ),
    ));
  }
}

// ── Calendar strip ────────────────────────────────────────────────────────────

class _CalendarStrip extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Color accentColor;
  final bool isDark;

  const _CalendarStrip({
    required this.selectedDate,
    required this.onDateSelected,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days  = List.generate(21, (i) => today.add(Duration(days: i - 3)));
    const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return SizedBox(
      height: 74,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: days.length,
        itemBuilder: (_, i) {
          final day = days[i];
          final isToday = day.day == today.day &&
              day.month == today.month &&
              day.year == today.year;
          final isSelected = selectedDate != null &&
              selectedDate!.day == day.day &&
              selectedDate!.month == day.month &&
              selectedDate!.year == day.year;
          final dayName = dayNames[(day.weekday - 1) % 7];

          return GestureDetector(
            onTap: () => onDateSelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : isToday
                        ? accentColor.withAlpha(isDark ? 38 : 30)
                        : _cardBg(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : isToday
                          ? accentColor.withAlpha(130)
                          : _cardBorder(isDark),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName,
                    style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isSelected
                          ? Colors.white.withAlpha(180)
                          : isToday
                              ? accentColor
                              : _textSub(isDark),
                    )),
                  const SizedBox(height: 4),
                  Text('${day.day}',
                    style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      height: 1,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? accentColor
                              : _textPrimary(isDark),
                    )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatefulWidget {
  final VoidCallback onAdd;
  final VoidCallback onDashboard;
  final bool isDark;
  final bool dashboardActive;

  const _BottomBar({
    required this.onAdd,
    required this.onDashboard,
    required this.isDark,
    required this.dashboardActive,
  });

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotCtrl;
  late final AnimationController _tapCtrl;
  late final AnimationController _burstCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _rotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat();
    _tapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 140));
    _scale = Tween(begin: 1.0, end: 0.82)
        .animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 460));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotCtrl.dispose();
    _tapCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(52, 0, 52, 36),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withAlpha(18)
                  : Colors.black.withAlpha(195),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withAlpha(widget.isDark ? 28 : 18),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: widget.onDashboard,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.dashboardActive
                          ? AppColors.tasks.withAlpha(50)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bar_chart_rounded,
                        color: widget.dashboardActive
                            ? AppColors.tasks
                            : Colors.white.withAlpha(140),
                        size: 22),
                  ),
                ),

                // ── Animated add button ──────────────────────────────────
                GestureDetector(
                  onTapDown: (_) => _tapCtrl.forward(),
                  onTapUp: (_) {
                    _tapCtrl.reverse();
                    _burstCtrl.forward(from: 0);
                    widget.onAdd();
                  },
                  onTapCancel: () => _tapCtrl.reverse(),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulseCtrl, _rotCtrl, _tapCtrl, _burstCtrl]),
                    builder: (context, _) {
                      final p     = _pulseCtrl.value;
                      final burst = _burstCtrl.value;
                      return SizedBox(
                        width: 80, height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Burst particles
                            for (int i = 0; i < 8; i++)
                              if (burst > 0 && burst < 1.0)
                                Positioned(
                                  left: 40 + cos(i / 8 * 2 * pi) * burst * 30 - 3,
                                  top:  40 + sin(i / 8 * 2 * pi) * burst * 30 - 3,
                                  child: Opacity(
                                    opacity: (1 - burst * 1.4).clamp(0.0, 1.0),
                                    child: Container(
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(
                                        color: AppColors.tasks,
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(
                                          color: AppColors.tasks.withAlpha(200),
                                          blurRadius: 5,
                                        )],
                                      ),
                                    ),
                                  ),
                                ),
                            // Pulsing glow ring
                            Container(
                              width: 58 + p * 8,
                              height: 58 + p * 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.tasks.withAlpha(35 + (50 * p).round()),
                                  width: 1.1,
                                ),
                                boxShadow: [BoxShadow(
                                  color: AppColors.tasks.withAlpha(22 + (55 * p).round()),
                                  blurRadius: 14 + p * 14,
                                  spreadRadius: p * 2,
                                )],
                              ),
                            ),
                            // Rotating arc
                            Transform.rotate(
                              angle: _rotCtrl.value * 2 * pi,
                              child: CustomPaint(
                                size: const Size(64, 64),
                                painter: _ArcPainter(color: AppColors.tasks),
                              ),
                            ),
                            // Main circle button
                            ScaleTransition(
                              scale: _scale,
                              child: Container(
                                width: 46, height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.tasks,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.tasks.withAlpha(110 + (65 * p).round()),
                                      blurRadius: 16 + p * 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 26),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Icon(Icons.checklist_rounded,
                    color: Colors.white.withAlpha(140), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(r, -pi / 2, pi * 1.15, false,
      Paint()
        ..color = color.withAlpha(190)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(r, pi * 0.73, pi * 0.52, false,
      Paint()
        ..color = color.withAlpha(60)
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}

// ── Dashboard panel ───────────────────────────────────────────────────────────

class _DashboardPanel extends StatelessWidget {
  final List<Task> tasks;
  final bool isDark;
  final Color accentColor;

  const _DashboardPanel({
    required this.tasks,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final total     = tasks.length;
    final done      = tasks.where((t) => t.isCompleted).length;
    final pending   = total - done;
    final xpEarned  = tasks.where((t) => t.isCompleted).fold(0, (s, t) => s + _pXp(t.priority));
    final critical  = tasks.where((t) => !t.isCompleted && t.priority == TaskPriority.high).length;
    final progress  = total == 0 ? 0.0 : done / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withAlpha(60), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('OVERVIEW',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 2, color: accentColor,
                )),
              const Spacer(),
              Text('LVL ${GameState.instance.level}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1, color: _textSub(isDark),
                )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatBox(label: 'TOTAL',   value: '$total',   color: accentColor,              isDark: isDark),
              const SizedBox(width: 8),
              _StatBox(label: 'DONE',    value: '$done',    color: AppColors.success,        isDark: isDark),
              const SizedBox(width: 8),
              _StatBox(label: 'PENDING', value: '$pending', color: const Color(0xFFFFD600),  isDark: isDark),
              const SizedBox(width: 8),
              _StatBox(label: 'XP',      value: '+$xpEarned', color: const Color(0xFFFF1744), isDark: isDark),
            ],
          ),
          if (critical > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF1744), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('$critical critical mission${critical > 1 ? 's' : ''} remaining',
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF1744),
                  )),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Stack(children: [
            Container(height: 4, decoration: BoxDecoration(
              color: _divider(isDark), borderRadius: BorderRadius.circular(2))),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              widthFactor: progress,
              child: Container(height: 4, decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: accentColor.withAlpha(120), blurRadius: 6)],
              )),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${(progress * 100).round()}% complete',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9, color: _textSub(isDark).withAlpha(140))),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatBox({
    required this.label, required this.value,
    required this.color, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 20 : 15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(isDark ? 60 : 50), width: 1),
        ),
        child: Column(
          children: [
            Text(value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 8, fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: color.withAlpha(isDark ? 160 : 180))),
          ],
        ),
      ),
    );
  }
}

// ── Done divider ──────────────────────────────────────────────────────────────

class _DoneDivider extends StatelessWidget {
  final int count;
  const _DoneDivider({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: AppColors.success.withAlpha(40))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(isDark ? 22 : 18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withAlpha(80), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 11, color: AppColors.success),
                const SizedBox(width: 5),
                Text('COMPLETED  $count',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    letterSpacing: 1, color: AppColors.success,
                  )),
              ],
            ),
          ),
          Expanded(child: Container(height: 1, color: AppColors.success.withAlpha(40))),
        ],
      ),
    );
  }
}

// ── Task card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onTap;

  const _TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = _pColor(task.priority);
    final done   = task.isCompleted;
    final catLabel = task.category == TaskCategory.work ? 'WORK' : 'LIVE';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: done ? 0.45 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _cardBg(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done
                  ? _cardBorder(isDark).withAlpha(60)
                  : color.withAlpha(isDark ? 55 : 70),
              width: done ? 0.8 : 1.2,
            ),
            boxShadow: done
                ? null
                : [
                    BoxShadow(
                      color: color.withAlpha(isDark ? 30 : 20),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Colored left accent bar ──────────────────────────
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: done ? _cardBorder(isDark).withAlpha(80) : color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    boxShadow: done ? null : [
                      BoxShadow(
                        color: color.withAlpha(isDark ? 160 : 120),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),

                // ── Content ──────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Top row: category + priority pill + complete btn
                        Row(
                          children: [
                            // Category tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.tasks.withAlpha(isDark ? 28 : 22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(catLabel,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9, fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: AppColors.tasks.withAlpha(isDark ? 200 : 180),
                                )),
                            ),
                            const SizedBox(width: 6),
                            // Priority pill
                            if (!done)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(isDark ? 30 : 22),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: color.withAlpha(isDark ? 100 : 80),
                                      width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5, height: 5,
                                      decoration: BoxDecoration(
                                          color: color, shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(
                                              color: color.withAlpha(200),
                                              blurRadius: 4)]),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(_pLabel(task.priority),
                                      style: GoogleFonts.inter(
                                        fontSize: 9, fontWeight: FontWeight.w700,
                                        color: color,
                                      )),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            // Complete button
                            GestureDetector(
                              onTap: done ? null : onComplete,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: 26, height: 26,
                                decoration: BoxDecoration(
                                  color: done ? AppColors.success : color.withAlpha(isDark ? 30 : 22),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: done ? AppColors.success : color.withAlpha(isDark ? 120 : 100),
                                    width: 1.5,
                                  ),
                                  boxShadow: done ? [BoxShadow(
                                      color: AppColors.success.withAlpha(120),
                                      blurRadius: 8)] : null,
                                ),
                                child: done
                                    ? const Icon(Icons.check_rounded,
                                        size: 13, color: Colors.white)
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 9),

                        // Title
                        Text(task.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: done ? _textSub(isDark) : _textPrimary(isDark),
                            decoration: done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: _textSub(isDark).withAlpha(150),
                          )),

                        // Description
                        if (task.description.isNotEmpty && !done) ...[
                          const SizedBox(height: 5),
                          Text(task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12, height: 1.4,
                              color: _textSub(isDark),
                            )),
                        ],

                        const SizedBox(height: 10),

                        // Bottom row: date/time + XP
                        Row(
                          children: [
                            if (task.dueDate != null) ...[
                              Icon(Icons.calendar_today_rounded,
                                  size: 10,
                                  color: _textSub(isDark).withAlpha(180)),
                              const SizedBox(width: 3),
                              Text(_fmtDate(task.dueDate!),
                                style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w500,
                                  color: _textSub(isDark),
                                )),
                              const SizedBox(width: 8),
                            ],
                            if (task.dueTime != null) ...[
                              Icon(Icons.access_time_rounded,
                                  size: 10,
                                  color: _textSub(isDark).withAlpha(180)),
                              const SizedBox(width: 3),
                              Text(_fmt24(task.dueTime!),
                                style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w500,
                                  color: _textSub(isDark),
                                )),
                            ],
                            const Spacer(),
                            // XP badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: done
                                    ? _cardBorder(isDark).withAlpha(50)
                                    : color.withAlpha(isDark ? 28 : 22),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                done ? '✓ ${_pXp(task.priority)} XP' : '+${_pXp(task.priority)} XP',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: done
                                      ? _textSub(isDark).withAlpha(120)
                                      : color,
                                )),
                            ),
                          ],
                        ),
                      ],
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

// ── Task detail sheet ─────────────────────────────────────────────────────────

class _TaskDetailSheet extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _TaskDetailSheet({
    required this.task,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final color    = _pColor(task.priority);
    final sheetBg  = isDark ? AppColors.darkCard : const Color(0xFFFFFFFF);
    final done     = task.isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _cardBorder(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Top row: priority tag + delete
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 28 : 35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: color.withAlpha(isDark ? 90 : 120), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded, size: 12, color: color),
                    const SizedBox(width: 5),
                    Text('${_pLabel(task.priority)} priority',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: color,
                      )),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(isDark ? 20 : 15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.red.withAlpha(isDark ? 60 : 50)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 15, color: Colors.red),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // XP label
          Text('+${_pXp(task.priority)} XP',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: color.withAlpha(180),
            )),

          const SizedBox(height: 6),

          // Title
          Text(task.title,
            style: GoogleFonts.inter(
              fontSize: 26, fontWeight: FontWeight.w800,
              height: 1.2,
              color: done ? _textSub(isDark) : _textPrimary(isDark),
              decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: _textSub(isDark).withAlpha(150),
            )),

          // Date / time
          if (task.dueDate != null || task.dueTime != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (task.dueTime != null)
                  Text(_fmt24(task.dueTime!),
                    style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: _textSub(isDark),
                    )),
                if (task.dueDate != null) ...[
                  if (task.dueTime != null)
                    Text(' • ',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: _textSub(isDark))),
                  Text('due ${_fmtDate(task.dueDate!)}',
                    style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: _textSub(isDark),
                    )),
                ],
              ],
            ),
          ],

          // Description
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Description',
              style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: _textSub(isDark).withAlpha(150),
              )),
            const SizedBox(height: 6),
            Text(task.description,
              style: GoogleFonts.inter(
                fontSize: 15, height: 1.55,
                color: _textSub(isDark),
              )),
          ],

          const SizedBox(height: 28),

          // Complete button
          if (!done)
            GestureDetector(
              onTap: onComplete,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.white : Colors.black)
                          .withAlpha(30),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Complete mission',
                      style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.black : Colors.white,
                      )),
                    const SizedBox(width: 10),
                    Text('+${_pXp(task.priority)} XP',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: color,
                      )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  final bool isDark;
  final bool hasDateFilter;
  const _Empty({required this.isDark, this.hasDateFilter = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _cardBorder(isDark), width: 1.5),
            ),
            child: Icon(Icons.checklist_rounded,
                size: 22, color: _cardBorder(isDark)),
          ),
          const SizedBox(height: 16),
          Text(hasDateFilter ? 'no tasks this day' : 'no tasks yet',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: _textSub(isDark),
            )),
          const SizedBox(height: 4),
          Text(hasDateFilter
              ? 'tap another day or add a task'
              : 'tap + below to add one',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: _textSub(isDark).withAlpha(120),
            )),
        ],
      ),
    );
  }
}

// ── Add sheet ─────────────────────────────────────────────────────────────────

class _AddSheet extends StatefulWidget {
  final void Function(Task) onAdd;
  final String nextId;
  final DateTime? preselectedDate;
  const _AddSheet({
    required this.onAdd,
    required this.nextId,
    this.preselectedDate,
  });

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  TimeOfDay? _time;
  late DateTime? _date;

  @override
  void initState() {
    super.initState();
    _date = widget.preselectedDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _pickTime() async {
    final t = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TimeDrumPicker(initial: _time ?? TimeOfDay.now()),
    );
    if (t != null) setState(() => _time = t);
  }

  void _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.tasks,
            surface: AppColors.darkCard,
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.darkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onAdd(Task(
      id: widget.nextId,
      title: title,
      description: _descCtrl.text.trim(),
      priority: _priority,
      createdAt: DateTime.now(),
      dueTime: _time,
      dueDate: _date,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = _pColor(_priority);
    final sheetBg     = isDark ? AppColors.darkCard : const Color(0xFFFFFFFF);
    final fieldBg     = isDark ? AppColors.darkBg   : const Color(0xFFE8E8F8);
    final fieldBorder = isDark ? AppColors.darkBorder : const Color(0xFFDDDDEE);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: Container(
                width: 36, height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: fieldBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            _Field(
              controller: _titleCtrl,
              hint: 'What needs to be done?',
              autofocus: true,
              fontSize: 16,
              bold: true,
              isDark: isDark,
              fieldBg: fieldBg,
              fieldBorder: fieldBorder,
              onSubmit: (_) => _submit(),
            ),
            const SizedBox(height: 10),
            _Field(
              controller: _descCtrl,
              hint: 'Notes (optional)',
              fontSize: 13,
              isDark: isDark,
              fieldBg: fieldBg,
              fieldBorder: fieldBorder,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                ...TaskPriority.values.map((p) {
                  final isActive = _priority == p;
                  final c = _pColor(p);
                  return Padding(
                    padding: EdgeInsets.only(
                        right: p != TaskPriority.low ? 6 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? c.withAlpha(isDark ? 22 : 35)
                              : fieldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? c : fieldBorder,
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: isActive ? c : _textSub(isDark),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(_pLabel(p),
                              style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: isActive ? c : _textSub(isDark),
                              )),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Date button
                GestureDetector(
                  onTap: _pickDate,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _date != null
                          ? AppColors.tasks.withAlpha(isDark ? 22 : 30)
                          : fieldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _date != null ? AppColors.tasks : fieldBorder,
                        width: _date != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 13,
                            color: _date != null
                                ? AppColors.tasks
                                : _textSub(isDark)),
                        if (_date != null) ...[
                          const SizedBox(width: 5),
                          Text(_fmtDate(_date!),
                            style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.tasks,
                            )),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _date = null),
                            child: Icon(Icons.close_rounded,
                                size: 11,
                                color: AppColors.tasks.withAlpha(160)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Time button
                GestureDetector(
                  onTap: _pickTime,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _time != null
                          ? AppColors.tasks.withAlpha(isDark ? 22 : 30)
                          : fieldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _time != null ? AppColors.tasks : fieldBorder,
                        width: _time != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13,
                            color: _time != null
                                ? AppColors.tasks
                                : _textSub(isDark)),
                        if (_time != null) ...[
                          const SizedBox(width: 5),
                          Text(_fmt24(_time!),
                            style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.tasks,
                            )),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _time = null),
                            child: Icon(Icons.close_rounded,
                                size: 11,
                                color: AppColors.tasks.withAlpha(160)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withAlpha(70),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ADD MISSION',
                      style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: _priority == TaskPriority.medium
                            ? Colors.black
                            : Colors.white,
                      )),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('+${_pXp(_priority)} XP',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: _priority == TaskPriority.medium
                              ? Colors.black.withAlpha(160)
                              : Colors.white.withAlpha(200),
                        )),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Field ─────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final double fontSize;
  final bool bold;
  final bool isDark;
  final Color fieldBg;
  final Color fieldBorder;
  final ValueChanged<String>? onSubmit;

  const _Field({
    required this.controller,
    required this.hint,
    required this.isDark,
    required this.fieldBg,
    required this.fieldBorder,
    this.autofocus = false,
    required this.fontSize,
    this.bold = false,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = _textPrimary(isDark);
    final hintColor = _textSub(isDark).withAlpha(100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fieldBorder),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onSubmitted: onSubmit,
        style: bold
            ? GoogleFonts.inter(
                fontSize: fontSize, fontWeight: FontWeight.w600,
                color: textColor)
            : GoogleFonts.inter(fontSize: fontSize, color: textColor),
        cursorColor: AppColors.tasks,
        cursorWidth: 1.5,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: fontSize, color: hintColor),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ── XP bar overlay ────────────────────────────────────────────────────────────

class _XpBarOverlay extends StatefulWidget {
  final int xp;
  final Color color;
  final double fromProgress;
  final double toProgress;
  final int level;
  final VoidCallback onDone;
  const _XpBarOverlay({
    required this.xp,
    required this.color,
    required this.fromProgress,
    required this.toProgress,
    required this.level,
    required this.onDone,
  });

  @override
  State<_XpBarOverlay> createState() => _XpBarOverlayState();
}

class _XpBarOverlayState extends State<_XpBarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slideY;
  late final Animation<double> _fill;
  late final Animation<double> _labelY;
  late final Animation<double> _labelOp;
  late final Animation<double> _panelOp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));

    _slideY = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.0, 0.12, curve: Curves.easeOutCubic)));

    final from      = widget.fromProgress;
    final to        = widget.toProgress;
    final overshoot = ((to - from) * 0.06).clamp(0.0, 0.04);
    _fill = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: from, end: (to + overshoot).clamp(0.0, 1.0))
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65),
      TweenSequenceItem(
        tween: Tween(begin: (to + overshoot).clamp(0.0, 1.0), end: to)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15),
      TweenSequenceItem(tween: ConstantTween(to), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.12, 0.78)));

    _labelY = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -28.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: -28.0, end: -22.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40),
    ]).animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.15, 0.55)));

    _labelOp = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.12, 0.80)));

    _panelOp = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeIn)), weight: 25),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Positioned(
        bottom: 0, left: 0, right: 0,
        child: IgnorePointer(
          child: Transform.translate(
            offset: Offset(0, _slideY.value * 140),
            child: Opacity(
              opacity: _panelOp.value.clamp(0.0, 1.0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(230),
                      Colors.black.withAlpha(140),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.xp > 0)
                      Transform.translate(
                        offset: Offset(0, _labelY.value),
                        child: Opacity(
                          opacity: _labelOp.value.clamp(0.0, 1.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: widget.color,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.color.withAlpha(160),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text('+${widget.xp} XP',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 15, fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: widget.color == const Color(0xFFFFD600)
                                        ? Colors.black
                                        : Colors.white,
                                  )),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('EXPERIENCE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: Colors.white.withAlpha(120))),
                        Text('LVL ${widget.level}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.white.withAlpha(120))),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Stack(
                      children: [
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withAlpha(12), width: 1),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: _fill.value.clamp(0.0, 1.0),
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [
                                  widget.color.withAlpha(180),
                                  widget.color,
                                  widget.color.withAlpha(220),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.color.withAlpha(200),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_fill.value > 0.02)
                          FractionallySizedBox(
                            widthFactor: _fill.value.clamp(0.0, 1.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 5, height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(210),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withAlpha(160),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
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

// ── Drum-style time picker ────────────────────────────────────────────────────

class _TimeDrumPicker extends StatefulWidget {
  final TimeOfDay initial;
  const _TimeDrumPicker({required this.initial});

  @override
  State<_TimeDrumPicker> createState() => _TimeDrumPickerState();
}

class _TimeDrumPickerState extends State<_TimeDrumPicker> {
  late int _hour;
  late int _minute;
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minCtrl;

  @override
  void initState() {
    super.initState();
    _hour   = widget.initial.hour;
    _minute = widget.initial.minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minCtrl  = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  Widget _drum({
    required int count,
    required int selected,
    required FixedExtentScrollController ctrl,
    required ValueChanged<int> onChanged,
    required bool isDark,
  }) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: ctrl,
        itemExtent: 54,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 1.4,
        perspective: 0.003,
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick();
          onChanged(i);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (ctx, i) {
            final sel = i == selected;
            return Center(
              child: Text(
                i.toString().padLeft(2, '0'),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: sel ? 38 : 24,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  color: sel
                      ? AppColors.tasks
                      : _textSub(isDark).withAlpha(100),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppColors.darkCard : const Color(0xFFFFFFFF);
    final border = isDark ? AppColors.darkBorder : const Color(0xFFDDDDEE);
    final hh = _hour.toString().padLeft(2, '0');
    final mm = _minute.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44, height: 4,
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
                color: border, borderRadius: BorderRadius.circular(4)),
          ),
          Text('SET TIME',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 3, color: _textSub(isDark))),
          const SizedBox(height: 20),
          SizedBox(
            height: 54 * 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 58,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.tasks.withAlpha(isDark ? 28 : 22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppColors.tasks.withAlpha(80), width: 1.2),
                  ),
                ),
                Row(
                  children: [
                    _drum(count: 24, selected: _hour, ctrl: _hourCtrl,
                        onChanged: (i) => setState(() => _hour = i),
                        isDark: isDark),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(':',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 36, fontWeight: FontWeight.w700,
                          color: AppColors.tasks.withAlpha(200))),
                    ),
                    _drum(count: 60, selected: _minute, ctrl: _minCtrl,
                        onChanged: (i) => setState(() => _minute = i),
                        isDark: isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(
                context, TimeOfDay(hour: _hour, minute: _minute)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.tasks,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: AppColors.tasks.withAlpha(120),
                      blurRadius: 22, offset: const Offset(0, 6)),
                ],
              ),
              child: Center(
                child: Text('SET  $hh:$mm',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    letterSpacing: 2, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Level-up overlay ──────────────────────────────────────────────────────────

class _LevelUpOverlay extends StatefulWidget {
  final int level;
  final VoidCallback onDone;
  const _LevelUpOverlay({required this.level, required this.onDone});

  @override
  State<_LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<_LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _waitingForTap = false;

  static const _cyan = Color(0xFF00EEFF);
  static const _pink = Color(0xFFFF2D9B);

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3800));
    _ctrl
        .animateTo(0.74,
            duration: const Duration(milliseconds: 2600),
            curve: Curves.linear)
        .then((_) {
      if (mounted) setState(() => _waitingForTap = true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _neon(String text, Color color, double size) => Text(text,
    style: GoogleFonts.outfit(
      fontSize: size, fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic, height: 0.95,
      color: Colors.white,
      shadows: [
        Shadow(color: color, blurRadius: 0),
        Shadow(color: color.withAlpha(230), blurRadius: 10),
        Shadow(color: color.withAlpha(160), blurRadius: 24),
        Shadow(color: color.withAlpha(90),  blurRadius: 50),
        Shadow(color: color.withAlpha(40),  blurRadius: 90),
      ],
    ));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        final t = _ctrl.value;

        final bgOp    = (t < 0.08 ? t / 0.08 : t > 0.80 ? 1 - (t - 0.80) / 0.20 : 1.0).clamp(0.0, 1.0);
        final flashOp = (t < 0.06 ? 1 - t / 0.06 : 0.0).clamp(0.0, 1.0);
        final avT     = Curves.easeOutBack.transform(((t - 0.08) / 0.14).clamp(0.0, 1.0));
        final avY     = (1 - avT) * -180.0;
        final avOp    = (t < 0.08 ? 0.0 : t > 0.80 ? 1 - (t - 0.80) / 0.20 : 1.0).clamp(0.0, 1.0);
        final ring    = t > 0.22 ? (0.55 + 0.45 * sin(t * 2 * pi * 3.5)).clamp(0.0, 1.0) : 0.0;
        final lvlT    = ((t - 0.22) / 0.16).clamp(0.0, 1.0);
        final lvlFlk  = lvlT < 1 ? (lvlT + 0.25 * sin(lvlT * pi * 10) * (1 - lvlT)).clamp(0.0, 1.2) : 1.0;
        final lvlOp   = (t < 0.22 ? 0.0 : t > 0.80 ? 1 - (t - 0.80) / 0.20 : lvlFlk).clamp(0.0, 1.0);
        final upT     = ((t - 0.34) / 0.18).clamp(0.0, 1.0);
        final upFlk   = upT < 1 ? (upT + 0.25 * sin(upT * pi * 10) * (1 - upT)).clamp(0.0, 1.2) : 1.0;
        final upOp    = (t < 0.34 ? 0.0 : t > 0.80 ? 1 - (t - 0.80) / 0.20 : upFlk).clamp(0.0, 1.0);
        final bdT     = Curves.elasticOut.transform(((t - 0.55) / 0.15).clamp(0.0, 1.0));
        final bdSc    = (t < 0.55 ? 0.0 : bdT).clamp(0.0, 2.5);
        final bdOp    = (t < 0.55 ? 0.0 : t > 0.80 ? 1 - (t - 0.80) / 0.20 : 1.0).clamp(0.0, 1.0);

        return Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_waitingForTap) {
                _waitingForTap = false;
                _ctrl
                    .animateTo(1.0,
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeIn)
                    .then((_) => widget.onDone());
              }
            },
            child: Opacity(
              opacity: bgOp,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.1,
                    colors: [
                      Color(0xFF1A0040),
                      Color(0xFF0A001A),
                      Color(0xFF000008),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    if (flashOp > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: flashOp,
                            child: Container(color: Colors.white),
                          ),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(0, avY),
                            child: Opacity(
                              opacity: avOp,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 152 + ring * 10,
                                    height: 152 + ring * 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _cyan.withAlpha(
                                            (80 + ring * 175).round()),
                                        width: 2.5 + ring * 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _cyan.withAlpha(
                                              (ring * 160).round()),
                                          blurRadius: 20 + ring * 28,
                                          spreadRadius: ring * 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  ClipOval(
                                    child: Image.asset(
                                      'assets/images/avatar.png',
                                      width: 132, height: 132,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Opacity(opacity: lvlOp, child: _neon('LEVEL', _cyan, 56)),
                          Opacity(opacity: upOp,  child: _neon('UP', _pink, 82)),
                          const SizedBox(height: 22),
                          Opacity(
                            opacity: bdOp,
                            child: Transform.scale(
                              scale: bdSc,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _cyan.withAlpha(22),
                                  border: Border.all(color: _cyan, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: _cyan.withAlpha(120),
                                        blurRadius: 18, spreadRadius: 1),
                                  ],
                                ),
                                child: Text('LEVEL  ${widget.level}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    letterSpacing: 4, color: _cyan,
                                    shadows: [
                                      Shadow(color: _cyan.withAlpha(200),
                                          blurRadius: 8),
                                    ],
                                  )),
                              ),
                            ),
                          ),
                          const SizedBox(height: 64),
                          Opacity(
                            opacity: t > 0.65 ? bdOp : 0.0,
                            child: Text('PRESS  ANY  KEY',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11, letterSpacing: 3,
                                color: Colors.white.withAlpha(80))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Collectible drop overlay ───────────────────────────────────────────────────

class _CollectibleDropOverlay extends StatefulWidget {
  final CollectionItem item;
  final VoidCallback onDone;
  const _CollectibleDropOverlay({required this.item, required this.onDone});

  @override
  State<_CollectibleDropOverlay> createState() =>
      _CollectibleDropOverlayState();
}

class _CollectibleDropOverlayState extends State<_CollectibleDropOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  VideoPlayerController? _vpc;
  bool _mediaReady    = false;
  bool _waitingForTap = false;

  Color get _rarityColor => Color(widget.item.rarity.color);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));
    _ctrl
        .animateTo(0.80,
            duration: const Duration(milliseconds: 1800),
            curve: Curves.easeOut)
        .then((_) {
      if (mounted) setState(() => _waitingForTap = true);
    });
    if (widget.item.isVideo) {
      _initVideo();
    } else {
      _mediaReady = true;
    }
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.asset(widget.item.assetPath);
    _vpc = c;
    await c.initialize();
    if (!mounted) return;
    await c.setLooping(true);
    await c.setVolume(0);
    await c.play();
    setState(() => _mediaReady = true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc = _rarityColor;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        final t      = _ctrl.value;
        final bgOp   = (t / 0.12).clamp(0.0, 1.0);
        final cardT  = Curves.easeOutBack
            .transform(((t - 0.20) / 0.35).clamp(0.0, 1.0));
        final labelT = ((t - 0.55) / 0.20).clamp(0.0, 1.0);

        return Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_waitingForTap) {
                _waitingForTap = false;
                _ctrl
                    .animateTo(1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn)
                    .then((_) => widget.onDone());
              }
            },
            child: Opacity(
              opacity: bgOp,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.1),
                    radius: 1.0,
                    colors: [Color(0xFF001A22), Color(0xFF000810)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: Curves.easeOut.transform(labelT),
                        child: Text('NEW  COLLECTIBLE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: rc.withAlpha(200),
                            shadows: [
                              Shadow(color: rc.withAlpha(160), blurRadius: 12)
                            ],
                          )),
                      ),
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: Curves.easeOut.transform(labelT),
                        child: Text('UNLOCKED',
                          style: GoogleFonts.outfit(
                            fontSize: 36, fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: rc, blurRadius: 0),
                              Shadow(color: rc.withAlpha(180), blurRadius: 18),
                              Shadow(color: rc.withAlpha(80), blurRadius: 40),
                            ],
                          )),
                      ),
                      const SizedBox(height: 32),
                      Transform.scale(
                        scale: cardT,
                        child: Container(
                          width: 200, height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: rc.withAlpha(200), width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: rc.withAlpha(100),
                                  blurRadius: 30,
                                  spreadRadius: 2),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _mediaReady
                                ? (widget.item.isVideo && _vpc != null
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _vpc!.value.size.width,
                                          height: _vpc!.value.size.height,
                                          child: VideoPlayer(_vpc!),
                                        ),
                                      )
                                    : Image.asset(
                                        widget.item.assetPath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, e, s) => Container(
                                          color: const Color(0xFF0A0A14),
                                          child: Center(
                                            child: Text(e.toString(),
                                              style: const TextStyle(
                                                  color: Color(0xFFFF5252),
                                                  fontSize: 9),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ))
                                : Container(
                                    color: const Color(0xFF0A0A14),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          color: rc.withAlpha(180),
                                          strokeWidth: 1.5),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Opacity(
                        opacity: Curves.easeOut.transform(
                            ((t - 0.65) / 0.20).clamp(0.0, 1.0)),
                        child: Column(children: [
                          Text(widget.item.name,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              letterSpacing: 3, color: rc,
                              shadows: [
                                Shadow(color: rc.withAlpha(180), blurRadius: 8)
                              ],
                            )),
                          const SizedBox(height: 4),
                          Text(widget.item.rarity.label,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9, letterSpacing: 3,
                              color: rc.withAlpha(160),
                            )),
                        ]),
                      ),
                      const SizedBox(height: 48),
                      Opacity(
                        opacity: _waitingForTap ? 1.0 : 0.0,
                        child: Text('PRESS  ANY  KEY',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10, letterSpacing: 3,
                            color: Colors.white.withAlpha(70))),
                      ),
                    ],
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
