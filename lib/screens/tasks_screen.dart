import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/task.dart';
import '../models/game_state.dart';
import '../models/collection_state.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';
import '../widgets/jelly_button.dart';
import '../widgets/animated_empty.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../l10n/app_locale.dart';

// ── In-memory store ───────────────────────────────────────────────────────────

// ignore: library_private_types_in_public_api
class TaskStore {
  static final List<Task> tasks = [];
  static int nextId = 1;

  /// Count of tasks completed on a given local day.
  static int completedOn(DateTime day) {
    return tasks.where((t) =>
      t.completedAt != null &&
      t.completedAt!.year == day.year &&
      t.completedAt!.month == day.month &&
      t.completedAt!.day == day.day
    ).length;
  }

  /// Last N days of completion counts, oldest first.
  static List<(DateTime, int)> last(int n) {
    final today = DateTime.now();
    return List.generate(n, (i) {
      final d = DateTime(today.year, today.month, today.day - (n - 1 - i));
      return (d, completedOn(d));
    });
  }
}

/// Streak-freeze state: allows one "skip" per week without breaking combo.
class TaskCombo {
  static int current = 0;
  static DateTime? lastCompletedDay;
  static DateTime? freezeUsedWeek;

  static double get multiplier {
    if (current >= 10) return 2.0;
    if (current >= 5) return 1.5;
    if (current >= 3) return 1.2;
    return 1.0;
  }

  static DateTime _weekStart(DateTime d) {
    final start = DateTime(d.year, d.month, d.day);
    return start.subtract(Duration(days: start.weekday - 1));
  }

  static bool get canFreeze {
    final w = _weekStart(DateTime.now());
    return freezeUsedWeek == null || freezeUsedWeek != w;
  }

  static void onComplete() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    if (lastCompletedDay == null) {
      current = 1;
    } else {
      final diff = todayKey.difference(lastCompletedDay!).inDays;
      if (diff == 0) {
        current++;
      } else if (diff == 1) {
        current++;
      } else if (diff == 2 && canFreeze) {
        // auto-freeze the one missed day
        freezeUsedWeek = _weekStart(today);
        current++;
      } else {
        current = 1;
      }
    }
    lastCompletedDay = todayKey;
  }
}

// ── Priority helpers ──────────────────────────────────────────────────────────

Color _pColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return const Color(0xFFDC2626); // red-600
    case TaskPriority.medium:
      return const Color(0xFFF59E0B); // amber-500
    case TaskPriority.low:
      return const Color(0xFF22C55E); // green-500
  }
}

// Earthy card palette matching _AddSheet priority buttons
Color _pCardBg(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return const Color(0xFF4E0000); // Red Inferno
    case TaskPriority.medium:
      return const Color(0xFFF2E6B1); // Pastel Yellow
    case TaskPriority.low:
      return const Color(0xFF4E5226); // Chive
  }
}

Color _pCardText(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return const Color(0xFFF0EDE5); // cream on dark
    case TaskPriority.medium:
      return const Color(0xFF3A2E10); // dark on yellow
    case TaskPriority.low:
      return const Color(0xFFE8E4D0); // cream on olive
  }
}

Color _pCardSub(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return const Color(0xFFB07070);
    case TaskPriority.medium:
      return const Color(0xFF8A7040);
    case TaskPriority.low:
      return const Color(0xFFAAAD8C);
  }
}

String _pLabel(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return t('Critical', 'Важно');
    case TaskPriority.medium:
      return t('Normal', 'Обычно');
    case TaskPriority.low:
      return t('Light', 'Лёгко');
  }
}

int _pXp(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return 50;
    case TaskPriority.medium:
      return 25;
    case TaskPriority.low:
      return 10;
  }
}

// ── Theme helpers ─────────────────────────────────────────────────────────────

Color _bg(bool dark) =>
    dark ? const Color(0xFF0D0D16) : const Color(0xFFBEC1DC);
Color _cardBg(bool dark) => dark ? AppColors.darkCard : const Color(0xFFFFFFFF);
Color _cardBorder(bool dark) =>
    dark ? AppColors.darkBorder : const Color(0xFFB8BACD);
Color _textPrimary(bool dark) =>
    dark ? AppColors.darkText : AppColors.lightText;
Color _textSub(bool dark) =>
    dark ? AppColors.darkTextSub : AppColors.lightTextSub;
Color _divider(bool dark) =>
    dark ? AppColors.darkBorder : const Color(0xFFDDDDEE);

// ── Time / date formatters ────────────────────────────────────────────────────

String _fmt24(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _fmtDate(DateTime d) {
  final mo = [
    t('JAN', 'ЯНВ'),
    t('FEB', 'ФЕВ'),
    t('MAR', 'МАР'),
    t('APR', 'АПР'),
    t('MAY', 'МАЙ'),
    t('JUN', 'ИЮН'),
    t('JUL', 'ИЮЛ'),
    t('AUG', 'АВГ'),
    t('SEP', 'СЕН'),
    t('OCT', 'ОКТ'),
    t('NOV', 'НОЯ'),
    t('DEC', 'ДЕК'),
  ];
  return '${mo[d.month - 1]} ${d.day}';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TasksScreen extends StatefulWidget {
  final TaskCategory category;
  const TasksScreen({super.key, required this.category});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

enum _TaskFilter { all, today, priority }
enum _SortMode { none, manual, dateAsc, dateDesc, priorityHigh, priorityLow, nameAz }
enum _ViewMode { list, timeline }

class _TasksScreenState extends State<TasksScreen> {
  DateTime? _selectedDate;
  bool _showDashboard = false;
  _TaskFilter _filter = _TaskFilter.all;
  String _searchQuery = '';
  _SortMode _sort = _SortMode.none;
  bool _showSearch = false;
  _ViewMode _viewMode = _ViewMode.list;

  final TextEditingController _quickCtrl = TextEditingController();
  final FocusNode _quickFocus = FocusNode();

  @override
  void dispose() {
    _quickCtrl.dispose();
    _quickFocus.dispose();
    super.dispose();
  }

  void _quickAdd() {
    final title = _quickCtrl.text.trim();
    if (title.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      TaskStore.tasks.add(Task(
        id: 't${TaskStore.nextId++}',
        title: title,
        createdAt: DateTime.now(),
        category: widget.category,
        priority: TaskPriority.medium,
        sortOrder: TaskStore.tasks.length,
      ));
      _quickCtrl.clear();
    });
    _quickFocus.requestFocus();
  }

  Widget _buildReorderable(List<Task> pending, List<Task> completed, Color vivid, bool isDark) {
    // Normalize sortOrder on first render so drag works predictably.
    for (var i = 0; i < pending.length; i++) {
      pending[i].sortOrder = i;
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      buildDefaultDragHandles: false,
      itemCount: pending.length,
      onReorder: (oldIdx, newIdx) {
        HapticFeedback.mediumImpact();
        setState(() {
          if (newIdx > oldIdx) newIdx--;
          final moved = pending.removeAt(oldIdx);
          pending.insert(newIdx, moved);
          for (var i = 0; i < pending.length; i++) {
            pending[i].sortOrder = i;
          }
        });
      },
      itemBuilder: (ctx, i) {
        final tk = pending[i];
        return ReorderableDragStartListener(
          key: ValueKey('reorder_${tk.id}'),
          index: i,
          child: _dismissible(tk, isDark),
        );
      },
    );
  }

  List<Task> get _tasks =>
      TaskStore.tasks.where((t) => t.category == widget.category).toList();

  List<Task> get _filteredTasks {
    var list = _tasks;

    // Date filter from calendar strip
    if (_selectedDate != null) {
      list = list.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.year == _selectedDate!.year &&
            t.dueDate!.month == _selectedDate!.month &&
            t.dueDate!.day == _selectedDate!.day;
      }).toList();
    }

    // Tab filter
    final now = DateTime.now();
    switch (_filter) {
      case _TaskFilter.today:
        list = list.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.year == now.year &&
              t.dueDate!.month == now.month &&
              t.dueDate!.day == now.day;
        }).toList();
        break;
      case _TaskFilter.priority:
        list = List.of(list)
          ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
        break;
      case _TaskFilter.all:
        break;
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.description.toLowerCase().contains(q) ||
        t.tags.any((tag) => tag.toLowerCase().contains(q))
      ).toList();
    }

    // Sort
    switch (_sort) {
      case _SortMode.dateAsc:
        list = List.of(list)..sort((a, b) => (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999)));
        break;
      case _SortMode.dateDesc:
        list = List.of(list)..sort((a, b) => (b.dueDate ?? DateTime(0)).compareTo(a.dueDate ?? DateTime(0)));
        break;
      case _SortMode.priorityHigh:
        list = List.of(list)..sort((a, b) => a.priority.index.compareTo(b.priority.index));
        break;
      case _SortMode.priorityLow:
        list = List.of(list)..sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case _SortMode.nameAz:
        list = List.of(list)..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case _SortMode.manual:
        list = List.of(list)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
      case _SortMode.none:
        break;
    }

    return list;
  }

  Future<void> _complete(Task task) async {
    if (task.isCompleted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      task.isCompleted = true;
      task.completedAt = DateTime.now();
      TaskCombo.onComplete();
    });
    final color = _pColor(task.priority);
    final fromProgress = GameState.instance.levelProgress;
    final fromLevel = GameState.instance.level;
    GameState.instance.recordCompletion();
    final xpGain = (task.xp * TaskCombo.multiplier).round();
    final didLevelUp = GameState.instance.addXp(xpGain);
    final toProgress = didLevelUp ? 1.0 : GameState.instance.levelProgress;
    _showXp(
      xpGain,
      color,
      fromProgress: fromProgress,
      toProgress: toProgress,
      level: fromLevel,
    );
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
        _showXp(
          0,
          color,
          fromProgress: 0.0,
          toProgress: GameState.instance.levelProgress,
          level: GameState.instance.level,
        );
      }
    }

    // Check if all tasks are done
    final allDone = _tasks.isNotEmpty && _tasks.every((t) => t.isCompleted);
    if (allDone && mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _showAllDone();
    }
  }

  void _showAllDone() {
    final overlay = Overlay.of(context);
    late OverlayEntry e;
    e = OverlayEntry(builder: (_) => _AllDoneOverlay(onDone: () => e.remove()));
    overlay.insert(e);
  }

  void _delete(String id) {
    HapticFeedback.lightImpact();
    final idx = TaskStore.tasks.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final removed = TaskStore.tasks.removeAt(idx);
    setState(() {});
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${t('Deleted', 'Удалено')} "${removed.title}"'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: t('UNDO', 'ОТМЕНИТЬ'),
          onPressed: () {
            setState(
              () => TaskStore.tasks.insert(
                idx.clamp(0, TaskStore.tasks.length),
                removed,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showXp(
    int xp,
    Color color, {
    required double fromProgress,
    required double toProgress,
    required int level,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => _XpBarOverlay(
        xp: xp,
        color: color,
        fromProgress: fromProgress,
        toProgress: toProgress,
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
      builder: (_) => _LevelUpOverlay(
        level: level,
        onDone: () {
          e.remove();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    overlay.insert(e);
    return completer.future;
  }

  Future<void> _showCollectibleDrop(CollectionItem item) {
    final completer = Completer<void>();
    final overlay = Overlay.of(context);
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => _CollectibleDropOverlay(
        item: item,
        onDone: () {
          e.remove();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    overlay.insert(e);
    return completer.future;
  }

  void _showDetail(Task task) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (ctx, _, _) => _TaskDetailOverlay(
          task: task,
          onComplete: () {
            Navigator.pop(ctx);
            _complete(task);
          },
          onDelete: () {
            Navigator.pop(ctx);
            _delete(task.id);
          },
          onEdit: () => setState(() {}),
        ),
        transitionsBuilder: (ctx, anim, _, child) {
          return FadeTransition(
            opacity: Tween(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }

  void _showAdd() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withAlpha(140),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (ctx, _, _) => _AddSheet(
        onAdd: (task) {
          task.category = widget.category;
          setState(() => TaskStore.tasks.insert(0, task));
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(t('Mission created!', 'Миссия создана!')),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        nextId: '${TaskStore.nextId++}',
        preselectedDate: _selectedDate,
        isWork: widget.category == TaskCategory.work,
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

  Widget _staggered(int index, Widget child) {
    final delay = (index * 50).clamp(0, 400);
    return TweenAnimationBuilder<double>(
      key: ValueKey('stagger_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  PopupMenuEntry<_SortMode> _sortItem(_SortMode mode, String label, IconData icon) {
    final active = _sort == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(children: [
        Icon(icon, size: 14, color: active ? AppColors.action : const Color(0xFF594536)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? AppColors.action : const Color(0xFF594536))),
      ]),
    );
  }

  Widget _dismissible(Task task, bool isDark) => Dismissible(
    key: ValueKey('${task.id}_${task.isCompleted}'),
    direction: task.isCompleted
        ? DismissDirection.endToStart
        : DismissDirection.horizontal,
    confirmDismiss: (direction) async {
      if (direction == DismissDirection.startToEnd && !task.isCompleted) {
        _complete(task);
        return false; // don't remove, just complete
      }
      return true; // endToStart = delete
    },
    onDismissed: (_) => _delete(task.id),
    // Swipe right → green complete (iOS-style vivid)
    background: Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 22),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft, end: Alignment.centerRight,
          colors: [const Color(0xFF22C55E), const Color(0xFF22C55E).withAlpha(0)],
          stops: const [0.0, 0.85],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_rounded, color: Colors.white, size: 26),
        const SizedBox(width: 10),
        Text(t('DONE', 'ГОТОВО'), style: GoogleFonts.jetBrainsMono(
          fontSize: 12, fontWeight: FontWeight.w800,
          letterSpacing: 1.5, color: Colors.white)),
      ]),
    ),
    // Swipe left → red delete (iOS-style vivid)
    secondaryBackground: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft, end: Alignment.centerRight,
          colors: [const Color(0xFFDC2626).withAlpha(0), const Color(0xFFDC2626)],
          stops: const [0.15, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(t('DELETE', 'УДАЛИТЬ'), style: GoogleFonts.jetBrainsMono(
          fontSize: 12, fontWeight: FontWeight.w800,
          letterSpacing: 1.5, color: Colors.white)),
        const SizedBox(width: 10),
        const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ]),
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
    final total = _tasks.length;
    final done = _tasks.where((t) => t.isCompleted).length;
    final filtered = _filteredTasks;
    final pending = filtered.where((t) => !t.isCompleted).toList();
    final completed = filtered.where((t) => t.isCompleted).toList();

    final isWork = widget.category == TaskCategory.work;
    final bgImage = isWork
        ? 'assets/collection/Tasks menu/Work.jpg'
        : 'assets/collection/Tasks menu/Live.jpg';
    final categoryBg = isWork
        ? const Color(0xFF12100E)
        : const Color(0xFF060C09);
    final bgImgOpacity = isWork ? 0.28 : 0.34;

    // Category-specific accent
    final vivid = isWork
        ? AppColors
              .action // warm orange for WORK
        : const Color(0xFF10B981); // emerald green for LIVE

    return SwipeToPop(
      child: Scaffold(
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

            // ── Living gradient mesh ───────────────────────────────────────
            Positioned.fill(child: IgnorePointer(child: _LivingGradient())),

            // ── Grain texture ──────────────────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _GrainPainter()),
              ),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
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
                              border: Border.all(color: Colors.white.withAlpha(40))),
                            child: Icon(Icons.chevron_left_rounded,
                                size: 22, color: Colors.white.withAlpha(200)),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isWork ? t('WORK', 'РАБОТА') : t('LIVE', 'ЖИЗНЬ'),
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 2,
                            color: isWork
                                ? const Color(0xFFF0E6D3)
                                : const Color(0xFFD0ECDF),
                          ),
                        ),
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
                            done == total
                                ? Icons.check_circle_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 12,
                            color: done == total
                                ? AppColors.success
                                : Colors.white.withAlpha(140),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$done / $total ${t('completed', 'выполнено')}',
                            style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: done == total
                                  ? AppColors.success
                                  : Colors.white.withAlpha(160),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: GameState.instance.streak >= 7
                                  ? AppColors.action.withAlpha(40)
                                  : GameState.instance.streak >= 3
                                  ? const Color(0xFFF59E0B).withAlpha(35)
                                  : Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: GameState.instance.streak >= 7
                                    ? AppColors.action.withAlpha(120)
                                    : GameState.instance.streak >= 3
                                    ? const Color(0xFFF59E0B).withAlpha(100)
                                    : Colors.white.withAlpha(40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 12,
                                  color: GameState.instance.streak >= 7
                                      ? AppColors.action
                                      : GameState.instance.streak >= 3
                                      ? const Color(0xFFF59E0B)
                                      : Colors.white.withAlpha(120),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${GameState.instance.streak}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: GameState.instance.streak >= 7
                                        ? AppColors.action
                                        : GameState.instance.streak >= 3
                                        ? const Color(0xFFF59E0B)
                                        : Colors.white.withAlpha(140),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (TaskCombo.current >= 3) ...[
                            const SizedBox(width: 6),
                            _ComboBadge(accentColor: vivid, compact: true),
                          ],
                        ],
                      ),
                    ),

                  // ── Progress bar ─────────────────────────────────────────
                  const SizedBox(height: 14),
                  Stack(
                    children: [
                      Container(height: 1, color: _divider(isDark)),
                      if (total > 0)
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          widthFactor: done / total,
                          child: Container(height: 1, color: vivid),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Search + Sort ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      // Search toggle
                      GestureDetector(
                        onTap: () => setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) _searchQuery = '';
                        }),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _showSearch
                                ? vivid.withAlpha(30)
                                : Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _showSearch
                                ? vivid.withAlpha(100)
                                : Colors.white.withAlpha(25)),
                          ),
                          child: Icon(Icons.search_rounded, size: 16,
                            color: _showSearch ? vivid : Colors.white.withAlpha(140)),
                        ),
                      ),
                      // Search field
                      if (_showSearch) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(25)),
                            ),
                            child: TextField(
                              autofocus: true,
                              style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: t('Search tasks...', 'Поиск задач...'),
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.white.withAlpha(80)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v),
                            ),
                          ),
                        ),
                      ],
                      if (!_showSearch) ...[
                        const SizedBox(width: 8),
                        // Inline filter tabs (ALL / TODAY / PRIORITY)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _TaskFilter.values.map((f) {
                                final active = _filter == f;
                                final label = switch (f) {
                                  _TaskFilter.all => t('ALL', 'ВСЕ'),
                                  _TaskFilter.today => t('TODAY', 'СЕГОДНЯ'),
                                  _TaskFilter.priority => t('PRIORITY', 'ПРИОРИТЕТ'),
                                };
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: JellyButton(
                                    onTap: () => setState(() => _filter = f),
                                    pressScale: 0.92,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: active
                                          ? vivid.withAlpha(40)
                                          : Colors.white.withAlpha(14),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: active
                                            ? vivid.withAlpha(180)
                                            : Colors.white.withAlpha(40),
                                          width: 1)),
                                      child: Text(label,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9, fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                          color: active
                                            ? vivid : Colors.white.withAlpha(180))),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Sort button
                      PopupMenuButton<_SortMode>(
                        onSelected: (v) => setState(() => _sort = v),
                        color: const Color(0xFFF5F2EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                        itemBuilder: (_) => [
                          _sortItem(_SortMode.none, t('Default', 'По умолч.'), Icons.remove_rounded),
                          _sortItem(_SortMode.manual, t('Manual (drag)', 'Вручную'), Icons.drag_handle_rounded),
                          _sortItem(_SortMode.dateAsc, t('Date ↑', 'Дата ↑'), Icons.arrow_upward_rounded),
                          _sortItem(_SortMode.dateDesc, t('Date ↓', 'Дата ↓'), Icons.arrow_downward_rounded),
                          _sortItem(_SortMode.priorityHigh, t('Priority ↑', 'Приоритет ↑'), Icons.flag_rounded),
                          _sortItem(_SortMode.nameAz, t('Name A-Z', 'Имя А-Я'), Icons.sort_by_alpha_rounded),
                        ],
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _sort != _SortMode.none
                                ? vivid.withAlpha(30)
                                : Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _sort != _SortMode.none
                                ? vivid.withAlpha(100)
                                : Colors.white.withAlpha(25)),
                          ),
                          child: Icon(Icons.sort_rounded, size: 16,
                            color: _sort != _SortMode.none ? vivid : Colors.white.withAlpha(140)),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // ── Calendar strip ───────────────────────────────────────
                  _CalendarStrip(
                    selectedDate: _selectedDate,
                    onDateSelected: (d) => setState(() {
                      _selectedDate =
                          (_selectedDate != null &&
                              _selectedDate!.day == d.day &&
                              _selectedDate!.month == d.month &&
                              _selectedDate!.year == d.year)
                          ? null
                          : d;
                    }),
                    accentColor: vivid,
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
                            accentColor: vivid,
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Task list / Timeline ──────────────────────────────────
                  Expanded(
                    child: pending.isEmpty && completed.isEmpty
                        ? _Empty(
                            isDark: isDark,
                            hasDateFilter: _selectedDate != null,
                          )
                        : _viewMode == _ViewMode.timeline
                            ? _TimelineView(
                                tasks: filtered,
                                onTap: _showDetail,
                                onComplete: _complete,
                                accentColor: vivid,
                              )
                            : RefreshIndicator(
                            color: vivid,
                            backgroundColor: const Color(0xFFF5F2EB),
                            onRefresh: () async {
                              HapticFeedback.lightImpact();
                              setState(() {});
                              await Future.delayed(
                                const Duration(milliseconds: 400),
                              );
                            },
                            child: _sort == _SortMode.manual
                              ? _buildReorderable(pending, completed, vivid, isDark)
                              : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                120,
                              ),
                              children: [
                                _QuickAddRow(
                                  controller: _quickCtrl,
                                  focusNode: _quickFocus,
                                  accentColor: vivid,
                                  onSubmit: _quickAdd,
                                ),
                                _TemplateChips(
                                  category: widget.category,
                                  accentColor: vivid,
                                  onPick: (title, priority) {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      TaskStore.tasks.add(Task(
                                        id: 't${TaskStore.nextId++}',
                                        title: title,
                                        createdAt: DateTime.now(),
                                        category: widget.category,
                                        priority: priority,
                                        sortOrder: TaskStore.tasks.length,
                                      ));
                                    });
                                  },
                                ),
                                ...pending.asMap().entries.map(
                                  (e) => _staggered(
                                    e.key,
                                    _dismissible(e.value, isDark),
                                  ),
                                ),
                                if (completed.isNotEmpty) ...[
                                  _DoneDivider(count: completed.length),
                                  ...completed.asMap().entries.map(
                                    (e) => _staggered(
                                      pending.length + e.key,
                                      _dismissible(e.value, isDark),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // ── Bottom bar ───────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomBar(
                onAdd: _showAdd,
                isDark: isDark,
                accentColor: vivid,
                dashboardActive: _showDashboard,
                isTimeline: _viewMode == _ViewMode.timeline,
                onDashboard: () =>
                    setState(() => _showDashboard = !_showDashboard),
                onToggleView: () => setState(() =>
                    _viewMode = _viewMode == _ViewMode.list
                        ? _ViewMode.timeline : _ViewMode.list),
              ),
            ),
          ],
        ),
      ),
    );
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
    // Always Mon–Sun of the current week
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dayNames = [t('MON', 'ПН'), t('TUE', 'ВТ'), t('WED', 'СР'), t('THU', 'ЧТ'), t('FRI', 'ПТ'), t('SAT', 'СБ'), t('SUN', 'ВС')];
    final months = [
      t('JANUARY', 'ЯНВАРЬ'),
      t('FEBRUARY', 'ФЕВРАЛЬ'),
      t('MARCH', 'МАРТ'),
      t('APRIL', 'АПРЕЛЬ'),
      t('MAY', 'МАЙ'),
      t('JUNE', 'ИЮНЬ'),
      t('JULY', 'ИЮЛЬ'),
      t('AUGUST', 'АВГУСТ'),
      t('SEPTEMBER', 'СЕНТЯБРЬ'),
      t('OCTOBER', 'ОКТЯБРЬ'),
      t('NOVEMBER', 'НОЯБРЬ'),
      t('DECEMBER', 'ДЕКАБРЬ'),
    ];

    const kRed = Color(0xFF4E0000); // Pantone Red Inferno
    const kBeige = Color(0xFFE8E0D0); // soft beige cell bg
    const kBeigeS = Color(0xFFD4C9B4); // beige selected/today border

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month label — centered, beige, Outfit
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Center(
            child: Text(
              months[today.month - 1],
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 5,
                color: Color(0xFFE8E0D0),
              ),
            ),
          ),
        ),
        // 7-day row — circular cells
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(7, (i) {
              final day = days[i];
              final isToday = day.day == today.day && day.month == today.month;
              final isSelected =
                  selectedDate != null &&
                  selectedDate!.day == day.day &&
                  selectedDate!.month == day.month;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onDateSelected(day);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected || isToday
                              ? kBeige
                              : kBeige.withAlpha(45),
                          border: Border.all(
                            color: isSelected
                                ? kRed
                                : isToday
                                ? kBeigeS
                                : kBeige.withAlpha(65),
                            width: isSelected ? 1.8 : 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNames[i],
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isSelected || isToday
                                ? kRed
                                : kBeige.withAlpha(180),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            color: isSelected
                                ? kRed
                                : isToday
                                ? kRed.withAlpha(200)
                                : kBeige.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatefulWidget {
  final VoidCallback onAdd;
  final VoidCallback onDashboard;
  final VoidCallback onToggleView;
  final bool isDark;
  final Color accentColor;
  final bool dashboardActive;
  final bool isTimeline;

  const _BottomBar({
    required this.onAdd,
    required this.onDashboard,
    required this.onToggleView,
    required this.isDark,
    required this.accentColor,
    required this.dashboardActive,
    this.isTimeline = false,
  });

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> with TickerProviderStateMixin {
  Color get _addBtnColor => widget.accentColor;
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotCtrl;
  late final AnimationController _tapCtrl;
  late final AnimationController _burstCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.82,
    ).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
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
                  ? Colors.white.withAlpha(25)
                  : Colors.black.withAlpha(195),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withAlpha(widget.isDark ? 45 : 18),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                JellyButton(
                  onTap: widget.onDashboard,
                  pressScale: 0.88,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.dashboardActive
                          ? widget.accentColor.withAlpha(50)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: widget.dashboardActive
                          ? widget.accentColor
                          : Colors.white.withAlpha(160),
                      size: 22,
                    ),
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
                    animation: Listenable.merge([
                      _pulseCtrl,
                      _rotCtrl,
                      _tapCtrl,
                      _burstCtrl,
                    ]),
                    builder: (context, _) {
                      final p = _pulseCtrl.value;
                      final burst = _burstCtrl.value;
                      return SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Burst particles
                            for (int i = 0; i < 8; i++)
                              if (burst > 0 && burst < 1.0)
                                Positioned(
                                  left:
                                      40 + cos(i / 8 * 2 * pi) * burst * 30 - 3,
                                  top:
                                      40 + sin(i / 8 * 2 * pi) * burst * 30 - 3,
                                  child: Opacity(
                                    opacity: (1 - burst * 1.4).clamp(0.0, 1.0),
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _addBtnColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _addBtnColor.withAlpha(200),
                                            blurRadius: 5,
                                          ),
                                        ],
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
                                  color: _addBtnColor.withAlpha(
                                    35 + (50 * p).round(),
                                  ),
                                  width: 1.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _addBtnColor.withAlpha(
                                      22 + (55 * p).round(),
                                    ),
                                    blurRadius: 14 + p * 14,
                                    spreadRadius: p * 2,
                                  ),
                                ],
                              ),
                            ),
                            // Rotating arc
                            Transform.rotate(
                              angle: _rotCtrl.value * 2 * pi,
                              child: CustomPaint(
                                size: const Size(64, 64),
                                painter: _ArcPainter(color: _addBtnColor),
                              ),
                            ),
                            // Main circle button
                            ScaleTransition(
                              scale: _scale,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _addBtnColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _addBtnColor.withAlpha(
                                        110 + (65 * p).round(),
                                      ),
                                      blurRadius: 16 + p * 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                JellyButton(
                  onTap: widget.onToggleView,
                  pressScale: 0.85,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      widget.isTimeline
                          ? Icons.view_list_rounded
                          : Icons.schedule_rounded,
                      color: Colors.white.withAlpha(160),
                      size: 22,
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

class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(
      r,
      -pi / 2,
      pi * 1.15,
      false,
      Paint()
        ..color = color.withAlpha(190)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      r,
      pi * 0.73,
      pi * 0.52,
      false,
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
    final total = tasks.length;
    final done = tasks.where((t) => t.isCompleted).length;
    final pending = total - done;
    final xpEarned = tasks
        .where((t) => t.isCompleted)
        .fold(0, (s, t) => s + _pXp(t.priority));
    final critical = tasks
        .where((t) => !t.isCompleted && t.priority == TaskPriority.high)
        .length;
    final progress = total == 0 ? 0.0 : done / total;

    const cardBg = Color(0xFFFAF5FF);
    const textCol = Color(0xFF4C1D95);
    const subCol = Color(0xFF6B5A7A);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(
                t('OVERVIEW', 'ОБЗОР'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: textCol,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withAlpha(60)),
                ),
                child: Text(
                  '${t('LVL', 'УР')} ${GameState.instance.level}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              _StatBox(
                label: t('TOTAL', 'ВСЕГО'),
                value: '$total',
                color: const Color(0xFF2A2318),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatBox(
                label: t('DONE', 'ГОТОВО'),
                value: '$done',
                color: const Color(0xFF2E7D32),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatBox(
                label: t('PENDING', 'В ОЖИДАНИИ'),
                value: '$pending',
                color: const Color(0xFFE65100),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatBox(
                label: 'XP',
                value: '+$xpEarned',
                color: const Color(0xFFC62828),
                isDark: isDark,
              ),
            ],
          ),

          if (critical > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB85C38),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB85C38).withAlpha(120),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$critical ${t('critical mission${critical > 1 ? 's' : ''} remaining', 'важн${critical > 1 ? 'ых' : 'ая'} мисси${critical > 1 ? 'й' : 'я'} осталось')}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB85C38),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Progress bar — warm style
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: textCol.withAlpha(18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withAlpha(100),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).round()}% ${t('complete', 'выполнено')}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: subCol,
            ),
          ),

          const SizedBox(height: 14),

          // 30-day heatmap (GitHub-style)
          Row(children: [
            Text(t('LAST 30 DAYS', 'ПОСЛЕДНИЕ 30 ДНЕЙ'),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8, fontWeight: FontWeight.w700,
                letterSpacing: 1.5, color: subCol)),
            const Spacer(),
            JellyButton(
              onTap: () => _openWeeklyReview(context, tasks, accentColor),
              pressScale: 0.9,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withAlpha(60))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.analytics_rounded, size: 11, color: accentColor),
                  const SizedBox(width: 5),
                  Text(t('REVIEW', 'ОБЗОР'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      letterSpacing: 1, color: accentColor)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          _Heatmap30(
            tasks: tasks,
            accentColor: accentColor,
            mutedColor: textCol.withAlpha(14),
          ),
        ],
      ),
    );
  }

  void _openWeeklyReview(BuildContext ctx, List<Task> tasks, Color accent) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WeeklyReviewSheet(tasks: tasks, accentColor: accent),
    );
  }
}

// ── 30-day heatmap (GitHub-style) ─────────────────────────────────────────────

class _Heatmap30 extends StatelessWidget {
  final List<Task> tasks;
  final Color accentColor;
  final Color mutedColor;
  const _Heatmap30({
    required this.tasks, required this.accentColor, required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final days = List.generate(30, (i) {
      final d = todayKey.subtract(Duration(days: 29 - i));
      final count = tasks.where((t) =>
        t.completedAt != null &&
        t.completedAt!.year == d.year &&
        t.completedAt!.month == d.month &&
        t.completedAt!.day == d.day
      ).length;
      return (d, count);
    });
    final maxCount = days.fold<int>(0, (m, e) => e.$2 > m ? e.$2 : m);

    return LayoutBuilder(builder: (ctx, box) {
      const cols = 10;
      const rows = 3;
      final gap = 4.0;
      final cellW = (box.maxWidth - gap * (cols - 1)) / cols;
      final cellH = cellW * 0.85;
      return SizedBox(
        height: rows * cellH + (rows - 1) * gap,
        child: Wrap(
          spacing: gap, runSpacing: gap,
          children: days.map((entry) {
            final (d, count) = entry;
            final isToday = d.day == today.day && d.month == today.month;
            final intensity = maxCount == 0 ? 0.0 : count / maxCount;
            return Container(
              width: cellW, height: cellH,
              decoration: BoxDecoration(
                color: intensity == 0
                  ? mutedColor
                  : Color.lerp(accentColor.withAlpha(60), accentColor, intensity),
                borderRadius: BorderRadius.circular(4),
                border: isToday
                  ? Border.all(color: accentColor, width: 1.5) : null,
                boxShadow: intensity > 0.5 ? [
                  BoxShadow(color: accentColor.withAlpha(80), blurRadius: 4),
                ] : null,
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

// ── Weekly review sheet ───────────────────────────────────────────────────────

class _WeeklyReviewSheet extends StatelessWidget {
  final List<Task> tasks;
  final Color accentColor;
  const _WeeklyReviewSheet({required this.tasks, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final weekStart = todayKey.subtract(Duration(days: today.weekday - 1));

    // Per-day completion counts for this week
    final weekDays = List.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      final count = tasks.where((t) =>
        t.completedAt != null &&
        t.completedAt!.year == d.year &&
        t.completedAt!.month == d.month &&
        t.completedAt!.day == d.day
      ).length;
      return (d, count);
    });
    final weekDone = weekDays.fold<int>(0, (s, e) => s + e.$2);
    final weekCreated = tasks.where((t) =>
      t.createdAt.isAfter(weekStart) && t.createdAt.isBefore(todayKey.add(const Duration(days: 1)))
    ).length;
    final completionRate = weekCreated == 0 ? 0.0 : (weekDone / weekCreated).clamp(0.0, 1.0);

    // Best day
    final bestDay = weekDays.reduce((a, b) => a.$2 >= b.$2 ? a : b);
    final dayNames = [t('Monday', 'Понедельник'), t('Tuesday', 'Вторник'), t('Wednesday', 'Среда'), t('Thursday', 'Четверг'), t('Friday', 'Пятница'), t('Saturday', 'Суббота'), t('Sunday', 'Воскресенье')];
    final bestDayName = bestDay.$2 == 0 ? t('nobody yet', 'пока нет') : dayNames[bestDay.$1.weekday - 1];

    // Priority breakdown of completed this week
    int hi = 0, md = 0, lo = 0;
    for (final t in tasks) {
      if (t.completedAt == null || t.completedAt!.isBefore(weekStart)) continue;
      switch (t.priority) {
        case TaskPriority.high: hi++; break;
        case TaskPriority.medium: md++; break;
        case TaskPriority.low: lo++; break;
      }
    }
    final xp = hi * 50 + md * 25 + lo * 10;

    // Focus time
    final focusMins = tasks.fold<int>(0, (s, t) => s + t.focusMinutes);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F2EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2318).withAlpha(40),
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 18),
        Row(children: [
          Icon(Icons.analytics_rounded, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Text(t('WEEKLY REVIEW', 'НЕДЕЛЬНЫЙ ОБЗОР'),
            style: GoogleFonts.playfairDisplay(
              fontSize: 18, fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF2A2318))),
        ]),
        const SizedBox(height: 18),

        // Hero stat
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              accentColor.withAlpha(220), accentColor]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(
              color: accentColor.withAlpha(120),
              blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            Text('$weekDone',
              style: GoogleFonts.playfairDisplay(
                fontSize: 56, fontWeight: FontWeight.w800,
                color: Colors.white, height: 1)),
            const SizedBox(height: 4),
            Text(t('COMPLETED THIS WEEK', 'ВЫПОЛНЕНО ЗА НЕДЕЛЮ'),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10, fontWeight: FontWeight.w800,
                letterSpacing: 2, color: Colors.white.withAlpha(220))),
          ]),
        ),
        const SizedBox(height: 14),

        // Stats grid
        Row(children: [
          Expanded(child: _ReviewStat(label: t('BEST DAY', 'ЛУЧШИЙ ДЕНЬ'), value: bestDayName, accent: accentColor)),
          const SizedBox(width: 10),
          Expanded(child: _ReviewStat(label: t('RATE', 'ТЕМП'), value: '${(completionRate * 100).round()}%', accent: accentColor)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ReviewStat(label: t('XP EARNED', 'XP ЗАРАБОТАНО'), value: '+$xp', accent: accentColor)),
          const SizedBox(width: 10),
          Expanded(child: _ReviewStat(label: t('FOCUS', 'ФОКУС'), value: '${focusMins}${t('m', 'м')}', accent: accentColor)),
        ]),
        const SizedBox(height: 14),

        // Priority breakdown (donut + legend)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(180),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2A2318).withAlpha(20))),
          child: Column(children: [
            Row(children: [
              Text(t('BREAKDOWN', 'РАЗБИВКА'),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: const Color(0xFF2A2318).withAlpha(140))),
            ]),
            const SizedBox(height: 14),
            _PrioDonut(hi: hi, md: md, lo: lo),
          ]),
        ),
        const SizedBox(height: 14),

        // Days strip
        Row(children: List.generate(7, (i) {
          final (d, c) = weekDays[i];
          final isToday = d.day == today.day && d.month == today.month;
          final labels = [t('M', 'П'), t('T', 'В'), t('W', 'С'), t('T', 'Ч'), t('F', 'П'), t('S', 'С'), t('S', 'В')];
          final maxC = weekDays.fold<int>(0, (m, e) => e.$2 > m ? e.$2 : m);
          final h = maxC == 0 ? 6.0 : 6.0 + (c / maxC) * 40;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: i < 6 ? 2 : 0),
              child: Column(children: [
                Text(c == 0 ? '·' : '$c',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: c == 0
                      ? const Color(0xFF2A2318).withAlpha(80)
                      : const Color(0xFF2A2318))),
                const SizedBox(height: 4),
                Container(
                  height: h,
                  decoration: BoxDecoration(
                    color: c == 0
                      ? const Color(0xFF2A2318).withAlpha(14)
                      : accentColor,
                    borderRadius: BorderRadius.circular(4),
                    border: isToday
                      ? Border.all(color: accentColor.withAlpha(220), width: 1.5)
                      : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i],
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8, fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A2318).withAlpha(130))),
              ]),
            ),
          );
        })),
      ]),
    );
  }
}

class _ReviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _ReviewStat({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2318).withAlpha(20))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8, fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: const Color(0xFF2A2318).withAlpha(140))),
        const SizedBox(height: 4),
        Text(value,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18, fontWeight: FontWeight.w800,
            color: const Color(0xFF2A2318))),
      ]),
    );
  }
}

/// Donut of priority distribution for the Weekly Review sheet.
class _PrioDonut extends StatefulWidget {
  final int hi;
  final int md;
  final int lo;
  const _PrioDonut({required this.hi, required this.md, required this.lo});

  @override
  State<_PrioDonut> createState() => _PrioDonutState();
}

class _PrioDonutState extends State<_PrioDonut> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    const hiColor = Color(0xFFDC2626);
    const mdColor = Color(0xFFF59E0B);
    const loColor = Color(0xFF10B981);
    final total = widget.hi + widget.md + widget.lo;

    List<PieChartSectionData> sections() {
      final data = [
        (t('HIGH', 'ВЫСОК'), widget.hi, hiColor),
        (t('MED',  'СРЕД'),  widget.md, mdColor),
        (t('LOW',  'НИЗК'),  widget.lo, loColor),
      ];
      return List.generate(data.length, (i) {
        final (_, count, color) = data[i];
        final isTouched = i == _touchedIndex;
        return PieChartSectionData(
          color: color,
          value: count == 0 ? 0.0001 : count.toDouble(),
          showTitle: isTouched && count > 0,
          title: '$count',
          titleStyle: GoogleFonts.jetBrainsMono(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: Colors.white),
          radius: isTouched ? 30 : 24,
        );
      });
    }

    return Column(children: [
      SizedBox(
        height: 150,
        child: Stack(alignment: Alignment.center, children: [
          PieChart(
            PieChartData(
              sections: sections(),
              centerSpaceRadius: 42,
              sectionsSpace: 3,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (ev, resp) {
                  setState(() {
                    if (!ev.isInterestedForInteractions ||
                        resp == null || resp.touchedSection == null) {
                      _touchedIndex = null;
                      return;
                    }
                    _touchedIndex =
                        resp.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$total',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24, fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF2A2318))),
            Text(t('TASKS', 'ЗАДАЧ'),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8, fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: const Color(0xFF2A2318).withAlpha(130))),
          ]),
        ]),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _DonutLegend(label: t('HIGH', 'ВЫСОК'), count: widget.hi, color: hiColor),
        const SizedBox(width: 14),
        _DonutLegend(label: t('MED', 'СРЕД'), count: widget.md, color: mdColor),
        const SizedBox(width: 14),
        _DonutLegend(label: t('LOW', 'НИЗК'), count: widget.lo, color: loColor),
      ]),
    ]);
  }
}

class _DonutLegend extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _DonutLegend({
    required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 5),
      Text('$label',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9, fontWeight: FontWeight.w700,
          letterSpacing: 0.8, color: color)),
      const SizedBox(width: 4),
      Text('$count',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10, fontWeight: FontWeight.w800,
          color: const Color(0xFF2A2318))),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0ECF6),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(6),
              blurRadius: 3, offset: const Offset(0, 2)),
            BoxShadow(color: Colors.white.withAlpha(220),
              blurRadius: 1, offset: const Offset(0, -1)),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: color.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick add row ─────────────────────────────────────────────────────────────

class _QuickAddRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accentColor;
  final VoidCallback onSubmit;
  const _QuickAddRow({
    required this.controller,
    required this.focusNode,
    required this.accentColor,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(40), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(children: [
          Icon(Icons.add_rounded, size: 20, color: accentColor.withAlpha(220)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
              cursorColor: accentColor,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: t('quick add — press Enter', 'быстрое добавление — Enter'),
                hintStyle: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white.withAlpha(120)),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, v, __) {
              if (v.text.trim().isEmpty) return const SizedBox.shrink();
              return JellyButton(
                onTap: onSubmit,
                pressScale: 0.9,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.arrow_upward_rounded,
                    size: 18, color: accentColor),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

// ── Task templates ────────────────────────────────────────────────────────────

class _TemplateChips extends StatelessWidget {
  final TaskCategory category;
  final Color accentColor;
  final void Function(String title, TaskPriority priority) onPick;
  const _TemplateChips({
    required this.category, required this.accentColor, required this.onPick,
  });

  static final List<(String, String, TaskPriority)> workTemplates = [
    ('📧', t('Reply to emails', 'Ответить на письма'), TaskPriority.medium),
    ('👀', t('Review PR', 'Проверить PR'), TaskPriority.high),
    ('📞', t('Call meeting', 'Созвон'), TaskPriority.medium),
    ('📝', t('Write report', 'Написать отчёт'), TaskPriority.high),
    ('📅', t('Plan week', 'Спланировать неделю'), TaskPriority.low),
    ('🧹', t('Clean inbox', 'Разобрать почту'), TaskPriority.low),
  ];
  static final List<(String, String, TaskPriority)> liveTemplates = [
    ('🛒', t('Groceries', 'Продукты'), TaskPriority.medium),
    ('💪', t('Workout', 'Тренировка'), TaskPriority.high),
    ('📚', t('Read 30m', 'Чтение 30м'), TaskPriority.medium),
    ('🚿', t('Shower', 'Душ'), TaskPriority.low),
    ('💊', t('Meds', 'Лекарства'), TaskPriority.high),
    ('🧘', t('Meditate', 'Медитация'), TaskPriority.low),
  ];

  @override
  Widget build(BuildContext context) {
    final list = category == TaskCategory.work ? workTemplates : liveTemplates;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (emoji, title, prio) = list[i];
            return JellyButton(
              onTap: () => onPick(title, prio),
              pressScale: 0.92,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(35))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(title,
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(210))),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Combo badge ───────────────────────────────────────────────────────────────

class _ComboBadge extends StatelessWidget {
  final Color accentColor;
  final bool compact;
  const _ComboBadge({required this.accentColor, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final n = TaskCombo.current;
    final mult = TaskCombo.multiplier;
    final hot = n >= 5;

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 14,
        vertical: compact ? 2 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: hot
          ? [const Color(0xFFFF6B35), const Color(0xFFDC2626)]
          : [accentColor.withAlpha(200), accentColor.withAlpha(120)]),
        borderRadius: BorderRadius.circular(compact ? 10 : 18),
        boxShadow: [BoxShadow(
          color: (hot ? const Color(0xFFFF6B35) : accentColor).withAlpha(compact ? 80 : 120),
          blurRadius: compact ? 6 : 14,
          offset: Offset(0, compact ? 2 : 4))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(hot ? Icons.local_fire_department_rounded : Icons.bolt_rounded,
          size: compact ? 11 : 16, color: Colors.white),
        SizedBox(width: compact ? 4 : 8),
        Text('x$n', style: GoogleFonts.jetBrainsMono(
          fontSize: compact ? 9 : 11, fontWeight: FontWeight.w800,
          letterSpacing: compact ? 0.5 : 1.5, color: Colors.white)),
        if (!compact) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(60),
              borderRadius: BorderRadius.circular(10)),
            child: Text(
              '${mult.toStringAsFixed(mult == mult.roundToDouble() ? 0 : 1)}×XP',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9, fontWeight: FontWeight.w800,
                letterSpacing: 1, color: Colors.white)),
          ),
        ],
      ]),
    );

    return compact
      ? badge
      : badge.animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.03, duration: 900.ms, curve: Curves.easeInOut);
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
          Expanded(
            child: Container(height: 1, color: AppColors.success.withAlpha(40)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(isDark ? 22 : 18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withAlpha(80),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 11,
                  color: AppColors.success,
                ),
                const SizedBox(width: 5),
                Text(
                  '${t('COMPLETED', 'ВЫПОЛНЕНО')}  $count',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(height: 1, color: AppColors.success.withAlpha(40)),
          ),
        ],
      ),
    );
  }
}

// ── Task card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatefulWidget {
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
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final onTap = widget.onTap;
    final onComplete = widget.onComplete;
    final done = task.isCompleted;
    final accentBg = done ? const Color(0xFFCCCAC4) : _pCardBg(task.priority);
    final accentTxt = done
        ? const Color(0xFF8A8880)
        : _pCardText(task.priority);
    final isWork = task.category == TaskCategory.work;
    final cardBg = isWork
        ? const Color(0xFFF5F0E8) // warm parchment for WORK
        : const Color(0xFFEEF5F0); // cool mint for LIVE
    final textCol = isWork
        ? const Color(0xFF2A2318) // warm brown
        : const Color(0xFF1A2A20); // cool dark green
    const subCol = Color(0xFF8A8070);
    final catLabel = isWork ? t('WORK', 'РАБОТА') : t('LIVE', 'ЖИЗНЬ');

    return JellyButton(
      onTap: onTap,
      pressScale: 0.97,
      child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: done ? 0.55 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                // Outer shadow — depth
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
                // Inner highlight — top edge light
                BoxShadow(
                  color: Colors.white.withAlpha(180),
                  blurRadius: 1,
                  offset: const Offset(0, -0.5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left: main content ──────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: textCol.withAlpha(10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: textCol.withAlpha(25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                catLabel,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: textCol.withAlpha(130),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Title
                            Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                height: 1.2,
                                color: textCol,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: textCol.withAlpha(100),
                              ),
                            ),

                            // Description
                            if (task.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                task.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  height: 1.3,
                                  color: subCol,
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),

                            // Bottom: date/time + XP
                            Row(
                              children: [
                                if (task.dueDate != null) ...[
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 10,
                                    color: subCol,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _fmtDate(task.dueDate!),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: subCol,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (task.dueTime != null) ...[
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 10,
                                    color: subCol,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _fmt24(task.dueTime!),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: subCol,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: done
                                        ? subCol.withAlpha(20)
                                        : AppColors.gold.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    done
                                        ? '✓ ${_pXp(task.priority)} XP'
                                        : '+${_pXp(task.priority)} XP',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: done ? subCol : AppColors.gold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          // Subtask progress
                          if (task.subtasks.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: Stack(children: [
                                Container(height: 3, decoration: BoxDecoration(
                                  color: textCol.withAlpha(15),
                                  borderRadius: BorderRadius.circular(2))),
                                FractionallySizedBox(
                                  widthFactor: task.subtaskProgress,
                                  child: Container(height: 3, decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(2)))),
                              ])),
                              const SizedBox(width: 6),
                              Text('${task.subtasksDone}/${task.subtasks.length}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8, fontWeight: FontWeight.w600,
                                  color: subCol)),
                            ]),
                          ],

                          // Tags
                          if (task.tags.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(spacing: 4, runSpacing: 4,
                              children: task.tags.map((t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: textCol.withAlpha(10),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: textCol.withAlpha(20))),
                                child: Text('#$t', style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8, fontWeight: FontWeight.w600,
                                  color: subCol)),
                              )).toList()),
                          ],

                          // Recurring indicator
                          if (task.recurType != RecurType.none) ...[
                            const SizedBox(height: 6),
                            Row(children: [
                              Icon(Icons.repeat_rounded, size: 10, color: subCol),
                              const SizedBox(width: 4),
                              Text(task.recurLabel, style: GoogleFonts.jetBrainsMono(
                                fontSize: 8, fontWeight: FontWeight.w600, color: subCol)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),

                    // ── Right: priority accent block (~1/4 width) ───────
                    Container(
                      width: 68,
                      color: accentBg,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Complete button
                          GestureDetector(
                            onTap: done ? null : onComplete,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: accentTxt.withAlpha(done ? 50 : 25),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentTxt.withAlpha(done ? 110 : 70),
                                  width: 1.5,
                                ),
                              ),
                              child: done
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: accentTxt.withAlpha(210),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Priority label rotated
                          RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              _pLabel(task.priority).toUpperCase(),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: accentTxt.withAlpha(150),
                              ),
                            ),
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

// ── Task detail sheet ─────────────────────────────────────────────────────────

class _TaskDetailOverlay extends StatefulWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskDetailOverlay({
    required this.task, required this.onComplete,
    required this.onDelete, required this.onEdit,
  });

  @override
  State<_TaskDetailOverlay> createState() => _TaskDetailOverlayState();
}

class _TaskDetailOverlayState extends State<_TaskDetailOverlay> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
  }

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  void _save() {
    widget.task.title = _titleCtrl.text.trim();
    widget.task.description = _descCtrl.text.trim();
    widget.onEdit();
    setState(() => _editing = false);
  }

  Widget _themedPicker(BuildContext ctx, Widget? child) => Theme(
    data: ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.action,
        surface: Color(0xFF1C1C27),
        onSurface: Colors.white,
      ),
    ),
    child: child!,
  );

  void _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context, initialDate: widget.task.dueDate ?? now,
      firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 2),
      builder: _themedPicker);
    if (d != null) { setState(() => widget.task.dueDate = d); widget.onEdit(); }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: widget.task.dueTime ?? TimeOfDay.now(),
      builder: _themedPicker);
    if (picked != null) { setState(() => widget.task.dueTime = picked); widget.onEdit(); }
  }

  void _toggleSubtask(int i) {
    setState(() => widget.task.subtasks[i].done = !widget.task.subtasks[i].done);
    widget.onEdit();
  }

  void _addSubtask() {
    setState(() => widget.task.subtasks.add(SubTask(title: t('New step', 'Новый шаг'))));
    widget.onEdit();
  }

  void _openFocus(BuildContext ctx) {
    HapticFeedback.mediumImpact();
    Navigator.push(ctx, PageRouteBuilder(
      opaque: false, barrierColor: Colors.black.withAlpha(200),
      pageBuilder: (_, __, ___) => _TaskFocusScreen(
        task: widget.task,
        accentColor: _pColor(widget.task.priority),
        onComplete: () {
          Navigator.pop(ctx);
          widget.onComplete();
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tk = widget.task;
    final color = _pColor(tk.priority);
    final done = tk.isCompleted;
    const cardBg = Color(0xFFF5F2EB);
    const textCol = Color(0xFF2A2318);
    const subCol = Color(0xFF8A8070);

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(180),
      body: SafeArea(child: Column(children: [
        // ── Top bar ──────────────────────────────
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            GestureDetector(onTap: () { if (_editing) _save(); Navigator.pop(context); },
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(30))),
                child: Icon(Icons.close_rounded, size: 20, color: Colors.white.withAlpha(200)))),
            const Spacer(),
            // Edit toggle
            GestureDetector(
              onTap: () { if (_editing) _save(); else setState(() => _editing = true); },
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _editing ? AppColors.action.withAlpha(25) : Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _editing ? AppColors.action.withAlpha(80) : Colors.white.withAlpha(30))),
                child: Icon(_editing ? Icons.check_rounded : Icons.edit_rounded,
                    size: 18, color: _editing ? AppColors.action : Colors.white.withAlpha(200)))),
            const SizedBox(width: 8),
            JellyButton(onTap: () => _openFocus(context), pressScale: 0.9,
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(25), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withAlpha(80))),
                child: Icon(Icons.timer_outlined, size: 18, color: color))),
            const SizedBox(width: 8),
            JellyButton(onTap: widget.onDelete, pressScale: 0.9,
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withAlpha(50))),
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red))),
          ])),

        const SizedBox(height: 20),

        // ── Scrollable card ──────────────────────
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg, borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 30, offset: const Offset(0, 10))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Priority + XP + Category (tap to change)
                Row(children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final values = TaskPriority.values;
                      final next = values[(tk.priority.index + 1) % values.length];
                      setState(() => widget.task.priority = next);
                      widget.onEdit();
                    },
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withAlpha(80))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.flag_rounded, size: 11, color: color),
                        const SizedBox(width: 4),
                        Text(_pLabel(tk.priority), style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: color)),
                      ])),
                  ),
                  const SizedBox(width: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.gold.withAlpha(20),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text('+${_pXp(tk.priority)} XP', style: GoogleFonts.jetBrainsMono(
                      fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.gold))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => widget.task.category =
                        tk.category == TaskCategory.work
                          ? TaskCategory.live : TaskCategory.work);
                      widget.onEdit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: textCol.withAlpha(10),
                        borderRadius: BorderRadius.circular(10)),
                      child: Text(tk.category == TaskCategory.work ? t('WORK', 'РАБОТА') : t('LIVE', 'ЖИЗНЬ'),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: subCol)),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                // Title (editable)
                _editing
                    ? TextField(controller: _titleCtrl,
                        style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic, color: textCol),
                        decoration: InputDecoration(
                          hintText: t('Task title', 'Название задачи'), border: InputBorder.none,
                          hintStyle: GoogleFonts.playfairDisplay(fontSize: 24, color: subCol.withAlpha(100)),
                          isDense: true, contentPadding: EdgeInsets.zero))
                    : Text(tk.title, style: GoogleFonts.playfairDisplay(
                        fontSize: 24, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic,
                        height: 1.15, color: textCol,
                        decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationColor: textCol.withAlpha(100))),

                const SizedBox(height: 12),

                // Description (editable)
                _editing
                    ? TextField(controller: _descCtrl, maxLines: 4,
                        style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: subCol),
                        decoration: InputDecoration(
                          hintText: t('Add description...', 'Добавить описание...'), border: InputBorder.none,
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: subCol.withAlpha(80)),
                          isDense: true, contentPadding: EdgeInsets.zero))
                    : tk.description.isNotEmpty
                        ? Text(tk.description, style: GoogleFonts.inter(
                            fontSize: 13, height: 1.5, color: subCol))
                        : Text(t('No description', 'Нет описания'), style: GoogleFonts.inter(
                            fontSize: 13, fontStyle: FontStyle.italic,
                            color: subCol.withAlpha(80))),

                const SizedBox(height: 16),

                // Date + Time (tappable)
                Row(children: [
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: textCol.withAlpha(8), borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.calendar_today_rounded, size: 13, color: subCol),
                        const SizedBox(width: 6),
                        Text(tk.dueDate != null ? _fmtDate(tk.dueDate!) : t('Add date', 'Выбрать дату'),
                          style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600,
                            color: tk.dueDate != null ? textCol : subCol.withAlpha(100))),
                      ]))),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: textCol.withAlpha(8), borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.access_time_rounded, size: 13, color: subCol),
                        const SizedBox(width: 6),
                        Text(tk.dueTime != null ? _fmt24(tk.dueTime!) : t('Add time', 'Выбрать время'),
                          style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600,
                            color: tk.dueTime != null ? textCol : subCol.withAlpha(100))),
                      ]))),
                ]),

                // Subtasks
                if (tk.subtasks.isNotEmpty || _editing) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    Text(t('SUBTASKS', 'ПОДЗАДАЧИ'), style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: subCol)),
                    const Spacer(),
                    if (_editing) GestureDetector(onTap: _addSubtask,
                      child: Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.action)),
                  ]),
                  const SizedBox(height: 8),
                  ...tk.subtasks.asMap().entries.map((e) {
                    final s = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: GestureDetector(
                        onTap: () => _toggleSubtask(e.key),
                        child: Row(children: [
                          Container(width: 20, height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s.done ? AppColors.success.withAlpha(25) : textCol.withAlpha(8),
                              border: Border.all(
                                color: s.done ? AppColors.success : textCol.withAlpha(25), width: 1.2)),
                            child: s.done ? Icon(Icons.check_rounded, size: 12, color: AppColors.success) : null),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.title, style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: s.done ? subCol : textCol,
                            decoration: s.done ? TextDecoration.lineThrough : TextDecoration.none))),
                        ]),
                      ),
                    );
                  }),
                ],

                // Tags
                if (tk.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 6, runSpacing: 4,
                    children: tk.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: textCol.withAlpha(8), borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: textCol.withAlpha(15))),
                      child: Text('#$tag', style: GoogleFonts.jetBrainsMono(
                        fontSize: 9, fontWeight: FontWeight.w600, color: subCol)),
                    )).toList()),
                ],

                // Recurring
                if (tk.recurType != RecurType.none) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.repeat_rounded, size: 12, color: subCol),
                    const SizedBox(width: 6),
                    Text(tk.recurLabel, style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, fontWeight: FontWeight.w600, color: subCol)),
                  ]),
                ],
              ])),

            const SizedBox(height: 16),

            // ── Complete button ───────────────────
            if (!done)
              JellyButton(onTap: widget.onComplete, pressScale: 0.95,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 20, offset: const Offset(0, 6))]),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(t('COMPLETE MISSION', 'ЗАВЕРШИТЬ МИССИЮ'), style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white)),
                    const SizedBox(width: 10),
                    Text('+${_pXp(tk.priority)} XP', style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(200))),
                  ]))),
          ],
        )),
      ])),
    );
  }
}

// ── Focus mode (Pomodoro per task) ───────────────────────────────────────────

class _TaskFocusScreen extends StatefulWidget {
  final Task task;
  final Color accentColor;
  final VoidCallback onComplete;
  const _TaskFocusScreen({
    required this.task,
    required this.accentColor,
    required this.onComplete,
  });

  @override
  State<_TaskFocusScreen> createState() => _TaskFocusScreenState();
}

class _TaskFocusScreenState extends State<_TaskFocusScreen>
    with TickerProviderStateMixin {
  static const List<int> _presets = [15, 25, 45, 60];
  int _minutes = 25;
  late int _secondsLeft = _minutes * 60;
  int get _totalSeconds => _minutes * 60;
  bool _running = false;
  bool _finished = false;
  late final AnimationController _tick;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && _running) {
          setState(() {
            _secondsLeft--;
            widget.task.focusMinutes = ((_totalSeconds - _secondsLeft) / 60).floor();
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

  void _start() { setState(() => _running = true); _tick.forward(from: 0); }
  void _pause() { setState(() => _running = false); _tick.stop(); }
  void _reset() => setState(() {
    _running = false; _tick.stop(); _secondsLeft = _totalSeconds;
  });
  void _setPreset(int m) => setState(() {
    _running = false; _tick.stop();
    _minutes = m; _secondsLeft = m * 60; _finished = false;
  });

  String get _timeDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => _totalSeconds == 0
      ? 0.0 : 1.0 - (_secondsLeft / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F).withAlpha(240),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: JellyButton(
                onTap: () => Navigator.pop(context),
                pressScale: 0.9,
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(widget.task.title, textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text(t('FOCUS MODE', 'РЕЖИМ ФОКУСА'),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10, fontWeight: FontWeight.w800,
              letterSpacing: 2, color: color)),

          const SizedBox(height: 40),

          // Ring
          SizedBox(
            width: 220, height: 220,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 220, height: 220,
                child: CircularProgressIndicator(
                  value: _progress, strokeWidth: 8,
                  backgroundColor: Colors.white.withAlpha(15),
                  valueColor: AlwaysStoppedAnimation(
                    _finished ? AppColors.success : color)),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_finished ? '✓' : _timeDisplay,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: _finished ? 48 : 42,
                    fontWeight: FontWeight.w700,
                    color: _finished ? AppColors.success : Colors.white)),
                if (!_finished)
                  Text(t('REMAINING', 'ОСТАЛОСЬ'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      letterSpacing: 2, color: Colors.white.withAlpha(80))),
              ]),
            ]),
          ),

          const SizedBox(height: 28),

          // Presets
          if (!_running && !_finished)
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: _presets.map((m) {
                final active = m == _minutes;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: JellyButton(
                    onTap: () => _setPreset(m),
                    pressScale: 0.9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? color.withAlpha(50) : Colors.white.withAlpha(12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active ? color.withAlpha(180) : Colors.white.withAlpha(30))),
                      child: Text('${m}${t('m', 'м')}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: active ? color : Colors.white.withAlpha(160))),
                    ),
                  ),
                );
              }).toList()),

          const SizedBox(height: 28),

          // Controls
          if (_finished)
            JellyButton(
              onTap: widget.onComplete, pressScale: 0.95,
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
                  mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(t('COMPLETE MISSION', 'ЗАВЕРШИТЬ МИССИЮ'),
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        letterSpacing: 1, color: Colors.white)),
                  ])),
              ),
            )
          else
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              JellyButton(
                onTap: _running ? _pause : _start, pressScale: 0.9,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: color.withAlpha(100),
                      blurRadius: 16, spreadRadius: 2)]),
                  child: Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 32, color: Colors.white),
                ),
              ),
              const SizedBox(width: 20),
              JellyButton(
                onTap: _reset, pressScale: 0.9,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(30))),
                  child: Icon(Icons.refresh_rounded, size: 22,
                    color: Colors.white.withAlpha(180))),
              ),
            ]),

          const Spacer(),
        ]),
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
    return AnimatedEmpty(
      icon: Icons.checklist_rounded,
      title: hasDateFilter ? t('no tasks this day', 'нет задач на этот день') : t('no tasks yet', 'пока нет задач'),
      subtitle: hasDateFilter
          ? t('tap another day or add a task', 'выберите другой день или добавьте задачу')
          : t('tap + below to add one', 'нажмите + чтобы добавить'),
    ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOut);
  }
}

// ── Timeline view (Outlook-style hourly slots) ───────────────────────────────

class _TimelineView extends StatelessWidget {
  final List<Task> tasks;
  final void Function(Task) onTap;
  final void Function(Task) onComplete;
  final Color accentColor;

  const _TimelineView({
    required this.tasks,
    required this.onTap,
    required this.onComplete,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const textCol = Color(0xFF2A2318);
    const subCol = Color(0xFF8A8070);
    const cardBg = Color(0xFFF5F2EB);

    // Group tasks by hour (0-23), unscheduled go to -1
    final Map<int, List<Task>> byHour = {};
    for (final t in tasks) {
      final h = t.dueTime?.hour ?? -1;
      byHour.putIfAbsent(h, () => []).add(t);
    }

    // Build hour slots from 6:00 to 23:00 + unscheduled
    final hours = <int>[];
    if (byHour.containsKey(-1)) hours.add(-1);
    for (int h = 6; h < 24; h++) hours.add(h);
    for (int h = 0; h < 6; h++) if (byHour.containsKey(h)) hours.add(h);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 20, 120),
      itemCount: hours.length,
      itemBuilder: (ctx, i) {
        final hour = hours[i];
        final slotTasks = byHour[hour] ?? [];
        final label = hour < 0
            ? t('ANYTIME', 'КОГДА-НИБУДЬ')
            : '${hour.toString().padLeft(2, '0')}:00';
        final now = TimeOfDay.now();
        final isCurrent = hour == now.hour;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left time label
              SizedBox(
                width: 56,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent ? accentColor : subCol,
                    ),
                  ),
                ),
              ),

              // Timeline line + dot
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: isCurrent ? 10 : 6,
                      height: isCurrent ? 10 : 6,
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slotTasks.isNotEmpty
                            ? accentColor
                            : isCurrent
                                ? accentColor.withAlpha(80)
                                : subCol.withAlpha(30),
                        boxShadow: isCurrent
                            ? [BoxShadow(
                                color: accentColor.withAlpha(80),
                                blurRadius: 8)]
                            : [],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 1.5,
                        color: isCurrent
                            ? accentColor.withAlpha(40)
                            : subCol.withAlpha(15),
                      ),
                    ),
                  ],
                ),
              ),

              // Task cards for this slot
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: slotTasks.isEmpty
                      ? SizedBox(
                          height: 32,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 1,
                              margin: const EdgeInsets.only(top: 12),
                              color: subCol.withAlpha(10),
                            ),
                          ),
                        )
                      : Column(
                          children: slotTasks.map((tk) {
                            final done = tk.isCompleted;
                            final pColor = _pColor(tk.priority);
                            final accentBg = done ? const Color(0xFFCCCAC4) : _pCardBg(tk.priority);
                            final accentTxt = done ? const Color(0xFF8A8880) : _pCardText(tk.priority);
                            return GestureDetector(
                              onTap: () => onTap(tk),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: done ? 0.55 : 1.0,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8, top: 4),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withAlpha(20),
                                        blurRadius: 10, offset: const Offset(0, 4)),
                                      BoxShadow(color: Colors.white.withAlpha(180),
                                        blurRadius: 1, offset: const Offset(0, -0.5)),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Left content
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Category tag
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: textCol.withAlpha(10),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: textCol.withAlpha(20))),
                                                    child: Text(
                                                      tk.category == TaskCategory.work ? t('WORK', 'РАБОТА') : t('LIVE', 'ЖИЗНЬ'),
                                                      style: GoogleFonts.jetBrainsMono(
                                                        fontSize: 8, fontWeight: FontWeight.w700,
                                                        letterSpacing: 1, color: textCol.withAlpha(130))),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Title
                                                  Text(tk.title,
                                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.playfairDisplay(
                                                      fontSize: 16, fontWeight: FontWeight.w700,
                                                      fontStyle: FontStyle.italic, height: 1.2,
                                                      color: textCol,
                                                      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                                                      decorationColor: textCol.withAlpha(100))),
                                                  // Description
                                                  if (tk.description.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(tk.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(fontSize: 11, height: 1.3, color: subCol)),
                                                  ],
                                                  const SizedBox(height: 8),
                                                  // Bottom row
                                                  Row(children: [
                                                    if (tk.dueTime != null) ...[
                                                      Icon(Icons.access_time_rounded, size: 10, color: subCol),
                                                      const SizedBox(width: 3),
                                                      Text(_fmt24(tk.dueTime!), style: GoogleFonts.inter(
                                                        fontSize: 10, fontWeight: FontWeight.w500, color: subCol)),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    if (tk.dueDate != null) ...[
                                                      Icon(Icons.calendar_today_rounded, size: 10, color: subCol),
                                                      const SizedBox(width: 3),
                                                      Text(_fmtDate(tk.dueDate!), style: GoogleFonts.inter(
                                                        fontSize: 10, fontWeight: FontWeight.w500, color: subCol)),
                                                    ],
                                                    const Spacer(),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: done ? subCol.withAlpha(20) : AppColors.gold.withAlpha(20),
                                                        borderRadius: BorderRadius.circular(8)),
                                                      child: Text(
                                                        done ? '✓ ${_pXp(tk.priority)} XP' : '+${_pXp(tk.priority)} XP',
                                                        style: GoogleFonts.jetBrainsMono(
                                                          fontSize: 8, fontWeight: FontWeight.w700,
                                                          color: done ? subCol : AppColors.gold)),
                                                    ),
                                                  ]),
                                                  // Subtasks progress
                                                  if (tk.subtasks.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Row(children: [
                                                      Expanded(child: Stack(children: [
                                                        Container(height: 3, decoration: BoxDecoration(
                                                          color: textCol.withAlpha(15), borderRadius: BorderRadius.circular(2))),
                                                        FractionallySizedBox(widthFactor: tk.subtaskProgress,
                                                          child: Container(height: 3, decoration: BoxDecoration(
                                                            color: AppColors.success, borderRadius: BorderRadius.circular(2)))),
                                                      ])),
                                                      const SizedBox(width: 6),
                                                      Text('${tk.subtasksDone}/${tk.subtasks.length}',
                                                        style: GoogleFonts.jetBrainsMono(
                                                          fontSize: 8, fontWeight: FontWeight.w600, color: subCol)),
                                                    ]),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Right accent block
                                          Container(
                                            width: 52,
                                            color: accentBg,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                GestureDetector(
                                                  onTap: done ? null : () => onComplete(tk),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 220),
                                                    width: 26, height: 26,
                                                    decoration: BoxDecoration(
                                                      color: accentTxt.withAlpha(done ? 50 : 25),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: accentTxt.withAlpha(done ? 110 : 70), width: 1.5)),
                                                    child: done
                                                        ? Icon(Icons.check_rounded, size: 14, color: accentTxt.withAlpha(210))
                                                        : null,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                RotatedBox(quarterTurns: 1,
                                                  child: Text(_pLabel(tk.priority).toUpperCase(),
                                                    style: GoogleFonts.jetBrainsMono(
                                                      fontSize: 7, fontWeight: FontWeight.w700,
                                                      letterSpacing: 1.5, color: accentTxt.withAlpha(150)))),
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
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Add sheet ─────────────────────────────────────────────────────────────────

class _AddSheet extends StatefulWidget {
  final void Function(Task) onAdd;
  final String nextId;
  final DateTime? preselectedDate;
  final bool isWork;
  const _AddSheet({
    required this.onAdd,
    required this.nextId,
    this.preselectedDate,
    this.isWork = true,
  });

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _titleFocus = FocusNode();
  TaskPriority _priority = TaskPriority.medium;
  TimeOfDay? _time;
  late DateTime? _date;
  bool _titleError = false;

  @override
  void initState() {
    super.initState();
    _date = widget.preselectedDate;
    // Delay focus so slide animation finishes first
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _titleFocus.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: widget.isWork ? AppColors.action : const Color(0xFF10B981),
            surface: const Color(0xFF1C1C27),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
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
          colorScheme: ColorScheme.dark(
            primary: widget.isWork ? AppColors.action : const Color(0xFF10B981),
            surface: const Color(0xFF1C1C27),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() => _titleError = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _titleError = false);
      });
      return;
    }
    HapticFeedback.lightImpact();
    // Smart default: before 17:00 → today, after 17:00 → tomorrow.
    final now = DateTime.now();
    final smartDate = _date ??
        (now.hour < 17
            ? DateTime(now.year, now.month, now.day)
            : DateTime(now.year, now.month, now.day).add(const Duration(days: 1)));
    widget.onAdd(
      Task(
        id: widget.nextId,
        title: title,
        description: _descCtrl.text.trim(),
        priority: _priority,
        createdAt: DateTime.now(),
        dueTime: _time,
        dueDate: smartDate,
      ),
    );
  }

  // Pantone palette (light version)
  static const _kNavy = Color(0xFF002D4E); // 2965 C
  static const _kDarkNavy = Color(0xFF001828); // darker bg (unused in light)
  static const _kRedInferno = Color(0xFF4E0000); // 4975 C
  static const _kPastelYellow = Color(0xFFF2E6B1); // 11-0616 TCX
  static const _kReseda = Color(0xFFA1AD8C); // 15-6414 TCX
  static const _kChive = Color(0xFF4E5226); // 19-0323 TCX
  static const _kCocoa = Color(0xFF594536); // 19-1119 TCX
  static const _kCoconutMilk = Color(0xFFF0EDE5); // 11-0608 TPG
  // derived light tones
  static const _kSheetBg = Color(0xFFF5F1E8); // warm off-white
  static const _kRowBg = Color(0xFFEFEBE0); // slightly darker row
  static const _kDivider = Color(0xFFDDD8CB); // soft divider

  Widget _tableRow({
    required String label,
    required Widget content,
    bool topBorder = true,
    IconData? icon,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (topBorder) Divider(height: 1, thickness: 1, color: _kDivider),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 12, color: _kCocoa.withAlpha(130)),
                    const SizedBox(width: 5),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _kCocoa.withAlpha(150),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: content),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final kb = MediaQuery.of(context).viewInsets.bottom;

    // Priority: Critical=Red Inferno, Normal=Pastel Yellow, Light=Chive
    const pBg = {
      TaskPriority.high: Color(0xFF4E0000), // Red Inferno
      TaskPriority.medium: Color(0xFFF2E6B1), // Pastel Yellow
      TaskPriority.low: Color(0xFF4E5226), // Chive
    };
    const pText = {
      TaskPriority.high: Color(0xFFF0EDE5), // light on dark red
      TaskPriority.medium: Color(0xFF3A2E10), // dark on yellow
      TaskPriority.low: Color(0xFFE8E4D0), // light on olive
    };

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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 40,
                    offset: const Offset(6, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ─────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: _kReseda.withAlpha(60),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(36),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: widget.isWork
                                  ? _kCocoa
                                  : const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: widget.isWork
                                  ? _kCoconutMilk
                                  : Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('NEW MISSION', 'НОВАЯ МИССИЯ'),
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: _kCocoa,
                                ),
                              ),
                              Text(
                                '+${_pXp(_priority)} XP',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: _kCocoa.withAlpha(140),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _kDivider,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: _kCocoa.withAlpha(150),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Form fields ────────────────────────────────────
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _titleError ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (ctx, shake, child) => Transform.translate(
                        offset: Offset(sin(shake * pi * 4) * 8, 0),
                        child: child,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _titleError
                              ? const Color(0xFFDC2626).withAlpha(8)
                              : Colors.transparent,
                          border: _titleError
                              ? Border(
                                  bottom: BorderSide(
                                    color: const Color(
                                      0xFFDC2626,
                                    ).withAlpha(120),
                                    width: 1.5,
                                  ),
                                )
                              : const Border(),
                        ),
                        child: _tableRow(
                          label: t('TITLE', 'НАЗВАНИЕ'),
                          icon: Icons.edit_rounded,
                          topBorder: false,
                          content: TextField(
                            controller: _titleCtrl,
                            focusNode: _titleFocus,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _titleError
                                  ? const Color(0xFFDC2626)
                                  : _kCocoa,
                            ),
                            decoration: InputDecoration(
                              hintText: _titleError
                                  ? t('Title is required!', 'Название обязательно!')
                                  : t('What needs to be done?', 'Что нужно сделать?'),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: _titleError
                                    ? const Color(0xFFDC2626).withAlpha(160)
                                    : _kCocoa.withAlpha(120),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _submit(),
                            onChanged: (_) {
                              if (_titleError)
                                setState(() => _titleError = false);
                            },
                          ),
                        ),
                      ),
                    ),

                    _tableRow(
                      label: t('NOTES', 'ЗАМЕТКИ'),
                      icon: Icons.sticky_note_2_outlined,
                      content: TextField(
                        controller: _descCtrl,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _kCocoa.withAlpha(190),
                        ),
                        decoration: InputDecoration(
                          hintText: t('Optional notes…', 'Заметки (необязательно)…'),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: _kCocoa.withAlpha(120),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),

                    _tableRow(
                      label: t('PRIORITY', 'ПРИОРИТЕТ'),
                      icon: Icons.flag_rounded,
                      content: Wrap(
                        spacing: 7,
                        runSpacing: 6,
                        children: TaskPriority.values.map((p) {
                          final isActive = _priority == p;
                          return GestureDetector(
                            onTap: () => setState(() => _priority = p),
                            child: AnimatedScale(
                              scale: isActive ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive ? pBg[p]! : _kRowBg,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isActive ? pBg[p]! : _kDivider,
                                    width: isActive ? 1.8 : 1.0,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: pBg[p]!.withAlpha(80),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  _pLabel(p),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? pText[p]!
                                        : _kCocoa.withAlpha(130),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    _tableRow(
                      label: t('DATE', 'ДАТА'),
                      icon: Icons.calendar_today_rounded,
                      content: GestureDetector(
                        onTap: _pickDate,
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: _kCocoa.withAlpha(150),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _date != null ? _fmtDate(_date!) : t('Pick a date', 'Выбрать дату'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _date != null
                                    ? _kCocoa
                                    : _kCocoa.withAlpha(90),
                              ),
                            ),
                            if (_date != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _date = null),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: _kCocoa.withAlpha(110),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    _tableRow(
                      label: t('TIME', 'ВРЕМЯ'),
                      icon: Icons.access_time_rounded,
                      content: GestureDetector(
                        onTap: _pickTime,
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: _kCocoa.withAlpha(150),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _time != null ? _fmt24(_time!) : t('Pick a time', 'Выбрать время'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _time != null
                                    ? _kCocoa
                                    : _kCocoa.withAlpha(90),
                              ),
                            ),
                            if (_time != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _time = null),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: _kCocoa.withAlpha(110),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // ── Submit ────────────────────────────────────────
                    Divider(height: 1, thickness: 1, color: _kDivider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                      child: JellyButton(
                        onTap: _submit,
                        pressScale: 0.95,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: widget.isWork
                                ? _kCocoa
                                : const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (widget.isWork
                                            ? _kCocoa
                                            : const Color(0xFF10B981))
                                        .withAlpha(70),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t('ADD MISSION', 'ДОБАВИТЬ МИССИЮ'),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+${_pXp(_priority)} XP',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: _kPastelYellow.withAlpha(210),
                                ),
                              ),
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

// ── Living gradient mesh ──────────────────────────────────────────────────────

class _LivingGradient extends StatefulWidget {
  const _LivingGradient();

  @override
  State<_LivingGradient> createState() => _LivingGradientState();
}

class _LivingGradientState extends State<_LivingGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final v = _ctrl.value;
        return Opacity(
          opacity: 0.18,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(
                  -0.5 + sin(v * pi) * 0.8,
                  -0.3 + cos(v * pi * 0.7) * 0.6,
                ),
                radius: 1.2 + sin(v * pi * 1.3) * 0.3,
                colors: [
                  Color.lerp(
                    const Color(0xFFFF6B35),
                    const Color(0xFFCA8A04),
                    v,
                  )!,
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Grain texture painter ─────────────────────────────────────────────────────

class _GrainPainter extends CustomPainter {
  _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rng = Random(42); // fixed seed for stable grain
    final count = (size.width * size.height * 0.003).toInt().clamp(0, 4000);
    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final bright = rng.nextBool();
      paint.color = bright
          ? Colors.white.withAlpha(8 + rng.nextInt(10))
          : Colors.black.withAlpha(12 + rng.nextInt(14));
      canvas.drawCircle(Offset(x, y), 0.5 + rng.nextDouble() * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    this.autofocus = false,
    required this.fontSize,
    this.bold = false,
    this.onSubmit,
    required this.isDark,
    required this.fieldBg,
    required this.fieldBorder,
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
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              )
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
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _shimmer;
  late final Animation<double> _slideY;
  late final Animation<double> _fill;
  late final Animation<double> _labelY;
  late final Animation<double> _labelOp;
  late final Animation<double> _panelOp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _slideY = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.12, curve: Curves.easeOutCubic),
      ),
    );

    final from = widget.fromProgress;
    final to = widget.toProgress;
    final overshoot = ((to - from) * 0.06).clamp(0.0, 0.04);
    _fill =
        TweenSequence([
          TweenSequenceItem(
            tween: Tween(
              begin: from,
              end: (to + overshoot).clamp(0.0, 1.0),
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 65,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: (to + overshoot).clamp(0.0, 1.0),
              end: to,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 15,
          ),
          TweenSequenceItem(tween: ConstantTween(to), weight: 20),
        ]).animate(
          CurvedAnimation(parent: _ctrl, curve: const Interval(0.12, 0.78)),
        );

    _labelY =
        TweenSequence([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.0,
              end: -28.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: -28.0,
              end: -22.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 40,
          ),
        ]).animate(
          CurvedAnimation(parent: _ctrl, curve: const Interval(0.15, 0.55)),
        );

    _labelOp =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
          TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
        ]).animate(
          CurvedAnimation(parent: _ctrl, curve: const Interval(0.12, 0.80)),
        );

    _panelOp = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ctrl, _shimmer]),
      builder: (context, _) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
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
                                  horizontal: 16,
                                  vertical: 6,
                                ),
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
                                child: Text(
                                  '+${widget.xp} XP',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color:
                                        widget.color == const Color(0xFFFFD600)
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t('EXPERIENCE', 'ОПЫТ'),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: Colors.white.withAlpha(120),
                          ),
                        ),
                        Text(
                          '${t('LVL', 'УР')} ${widget.level}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.white.withAlpha(120),
                          ),
                        ),
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
                              color: Colors.white.withAlpha(12),
                              width: 1,
                            ),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: _fill.value.clamp(0.0, 1.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                // Base fill
                                Container(
                                  height: 16,
                                  decoration: BoxDecoration(
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
                                // Shimmer energy sweep
                                Positioned.fill(
                                  child: Transform.translate(
                                    offset: Offset(
                                      (_shimmer.value * 2 - 0.5) *
                                          MediaQuery.of(context).size.width,
                                      0,
                                    ),
                                    child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withAlpha(0),
                                            Colors.white.withAlpha(70),
                                            Colors.white.withAlpha(0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
                                width: 5,
                                height: 16,
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
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minCtrl = FixedExtentScrollController(initialItem: _minute);
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
    final bg = isDark ? AppColors.darkCard : const Color(0xFFFFFFFF);
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
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Text(
            t('SET TIME', 'УСТАНОВИТЬ ВРЕМЯ'),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: _textSub(isDark),
            ),
          ),
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
                      color: AppColors.tasks.withAlpha(80),
                      width: 1.2,
                    ),
                  ),
                ),
                Row(
                  children: [
                    _drum(
                      count: 24,
                      selected: _hour,
                      ctrl: _hourCtrl,
                      onChanged: (i) => setState(() => _hour = i),
                      isDark: isDark,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        ':',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tasks.withAlpha(200),
                        ),
                      ),
                    ),
                    _drum(
                      count: 60,
                      selected: _minute,
                      ctrl: _minCtrl,
                      onChanged: (i) => setState(() => _minute = i),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () =>
                Navigator.pop(context, TimeOfDay(hour: _hour, minute: _minute)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.tasks,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tasks.withAlpha(120),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${t('SET', 'УСТАНОВИТЬ')}  $hh:$mm',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
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

  static const _cyan = Color(0xFFCA8A04); // warm gold
  static const _pink = Color(0xFFF97316); // warm orange

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
    _ctrl
        .animateTo(
          0.74,
          duration: const Duration(milliseconds: 2600),
          curve: Curves.linear,
        )
        .then((_) {
          if (mounted) setState(() => _waitingForTap = true);
        });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _neon(String text, Color color, double size) => Text(
    text,
    style: GoogleFonts.outfit(
      fontSize: size,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      height: 0.95,
      color: Colors.white,
      shadows: [
        Shadow(color: color, blurRadius: 0),
        Shadow(color: color.withAlpha(230), blurRadius: 10),
        Shadow(color: color.withAlpha(160), blurRadius: 24),
        Shadow(color: color.withAlpha(90), blurRadius: 50),
        Shadow(color: color.withAlpha(40), blurRadius: 90),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        final v = _ctrl.value;

        final bgOp =
            (v < 0.08
                    ? v / 0.08
                    : v > 0.80
                    ? 1 - (v - 0.80) / 0.20
                    : 1.0)
                .clamp(0.0, 1.0);
        final flashOp = (v < 0.06 ? 1 - v / 0.06 : 0.0).clamp(0.0, 1.0);
        final avT = Curves.easeOutBack.transform(
          ((v - 0.08) / 0.14).clamp(0.0, 1.0),
        );
        final avY = (1 - avT) * -180.0;
        final avOp =
            (v < 0.08
                    ? 0.0
                    : v > 0.80
                    ? 1 - (v - 0.80) / 0.20
                    : 1.0)
                .clamp(0.0, 1.0);
        final ring = v > 0.22
            ? (0.55 + 0.45 * sin(v * 2 * pi * 3.5)).clamp(0.0, 1.0)
            : 0.0;
        final lvlT = ((v - 0.22) / 0.16).clamp(0.0, 1.0);
        final lvlFlk = lvlT < 1
            ? (lvlT + 0.25 * sin(lvlT * pi * 10) * (1 - lvlT)).clamp(0.0, 1.2)
            : 1.0;
        final lvlOp =
            (v < 0.22
                    ? 0.0
                    : v > 0.80
                    ? 1 - (v - 0.80) / 0.20
                    : lvlFlk)
                .clamp(0.0, 1.0);
        final upT = ((v - 0.34) / 0.18).clamp(0.0, 1.0);
        final upFlk = upT < 1
            ? (upT + 0.25 * sin(upT * pi * 10) * (1 - upT)).clamp(0.0, 1.2)
            : 1.0;
        final upOp =
            (v < 0.34
                    ? 0.0
                    : v > 0.80
                    ? 1 - (v - 0.80) / 0.20
                    : upFlk)
                .clamp(0.0, 1.0);
        final bdT = Curves.elasticOut.transform(
          ((v - 0.55) / 0.15).clamp(0.0, 1.0),
        );
        final bdSc = (v < 0.55 ? 0.0 : bdT).clamp(0.0, 2.5);
        final bdOp =
            (v < 0.55
                    ? 0.0
                    : v > 0.80
                    ? 1 - (v - 0.80) / 0.20
                    : 1.0)
                .clamp(0.0, 1.0);

        return Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_waitingForTap) {
                _waitingForTap = false;
                _ctrl
                    .animateTo(
                      1.0,
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeIn,
                    )
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
                      Color(0xFF1A1008),
                      Color(0xFF0A0804),
                      Color(0xFF050300),
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
                                          (80 + ring * 175).round(),
                                        ),
                                        width: 2.5 + ring * 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _cyan.withAlpha(
                                            (ring * 160).round(),
                                          ),
                                          blurRadius: 20 + ring * 28,
                                          spreadRadius: ring * 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  ClipOval(
                                    child: Image.asset(
                                      'assets/images/avatar.png',
                                      width: 132,
                                      height: 132,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Opacity(
                            opacity: lvlOp,
                            child: _neon(t('LEVEL', 'УРОВЕНЬ'), _cyan, 56),
                          ),
                          Opacity(opacity: upOp, child: _neon(t('UP', 'ВВЕРХ'), _pink, 82)),
                          const SizedBox(height: 22),
                          Opacity(
                            opacity: bdOp,
                            child: Transform.scale(
                              scale: bdSc,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _cyan.withAlpha(22),
                                  border: Border.all(color: _cyan, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _cyan.withAlpha(120),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${t('LEVEL', 'УРОВЕНЬ')}  ${widget.level}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 4,
                                    color: _cyan,
                                    shadows: [
                                      Shadow(
                                        color: _cyan.withAlpha(200),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 64),
                          Opacity(
                            opacity: v > 0.65 ? bdOp : 0.0,
                            child: Text(
                              t('PRESS  ANY  KEY', 'НАЖМИТЕ  ЛЮБУЮ  КЛАВИШУ'),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                letterSpacing: 3,
                                color: Colors.white.withAlpha(80),
                              ),
                            ),
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

// ── All Done overlay ──────────────────────────────────────────────────────────

class _AllDoneOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _AllDoneOverlay({required this.onDone});

  @override
  State<_AllDoneOverlay> createState() => _AllDoneOverlayState();
}

class _AllDoneOverlayState extends State<_AllDoneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final v = _ctrl.value;
        final bgOp = v < 0.1
            ? v / 0.1
            : v > 0.75
            ? 1 - (v - 0.75) / 0.25
            : 1.0;
        final textScale = Curves.elasticOut.transform(
          ((v - 0.05) / 0.25).clamp(0.0, 1.0),
        );
        final textOp = v < 0.05
            ? 0.0
            : v > 0.75
            ? 1 - (v - 0.75) / 0.25
            : 1.0;

        return Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: bgOp.clamp(0.0, 1.0),
              child: Container(
                color: Colors.black.withAlpha(160),
                child: Stack(
                  children: [
                    // Confetti
                    if (v > 0.08)
                      ...List.generate(24, (i) {
                        final seed = i * 97.3;
                        final x = (sin(seed) * 0.5 + 0.5);
                        final speed = 0.3 + (cos(seed * 2) * 0.2 + 0.3);
                        final cT = ((v - 0.08) * speed * 1.8).clamp(0.0, 1.0);
                        final y = -0.05 + 1.1 * cT;
                        final wobble = sin(cT * pi * 5 + seed) * 16;
                        final cOp =
                            (1 - cT * 1.2).clamp(0.0, 1.0) *
                            bgOp.clamp(0.0, 1.0);
                        const colors = [
                          Color(0xFFFF6B35),
                          Color(0xFFCA8A04),
                          Color(0xFF22C55E),
                          Color(0xFFF59E0B),
                          Color(0xFFFF6B35),
                          Color(0xFFFFFFFF),
                        ];
                        final sz = MediaQuery.of(context).size;
                        return Positioned(
                          left: x * sz.width + wobble,
                          top: y * sz.height,
                          child: Opacity(
                            opacity: cOp,
                            child: Transform.rotate(
                              angle: cT * pi * 4 + seed,
                              child: Container(
                                width: 5 + (i % 3) * 2.0,
                                height: 5 + (i % 3) * 2.0,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  borderRadius: BorderRadius.circular(
                                    i % 2 == 0 ? 1 : 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    // Text
                    Center(
                      child: Opacity(
                        opacity: textOp.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: textScale.clamp(0.0, 1.5),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                size: 48,
                                color: AppColors.gold,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t('QUEST', 'КВЕСТ'),
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.gold,
                                  height: 1,
                                ),
                              ),
                              Text(
                                t('COMPLETE', 'ВЫПОЛНЕН'),
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
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
  bool _mediaReady = false;
  bool _waitingForTap = false;

  Color get _rarityColor => Color(widget.item.rarity.color);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _ctrl
        .animateTo(
          0.80,
          duration: const Duration(milliseconds: 1800),
          curve: Curves.easeOut,
        )
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
        final v = _ctrl.value;
        final bgOp = (v / 0.12).clamp(0.0, 1.0);
        final cardT = Curves.easeOutBack.transform(
          ((v - 0.20) / 0.35).clamp(0.0, 1.0),
        );
        final labelT = ((v - 0.55) / 0.20).clamp(0.0, 1.0);

        return Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_waitingForTap) {
                _waitingForTap = false;
                _ctrl
                    .animateTo(
                      1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    )
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
                        child: Text(
                          t('NEW  COLLECTIBLE', 'НОВЫЙ  ПРЕДМЕТ'),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: rc.withAlpha(200),
                            shadows: [
                              Shadow(color: rc.withAlpha(160), blurRadius: 12),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: Curves.easeOut.transform(labelT),
                        child: Text(
                          t('UNLOCKED', 'РАЗБЛОКИРОВАНО'),
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: rc, blurRadius: 0),
                              Shadow(color: rc.withAlpha(180), blurRadius: 18),
                              Shadow(color: rc.withAlpha(80), blurRadius: 40),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Transform.scale(
                        scale: cardT,
                        child: Container(
                          width: 200,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: rc.withAlpha(200),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: rc.withAlpha(100),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
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
                                              child: Text(
                                                e.toString(),
                                                style: const TextStyle(
                                                  color: Color(0xFFFF5252),
                                                  fontSize: 9,
                                                ),
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
                                        strokeWidth: 1.5,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Opacity(
                        opacity: Curves.easeOut.transform(
                          ((v - 0.65) / 0.20).clamp(0.0, 1.0),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.item.name,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                color: rc,
                                shadows: [
                                  Shadow(
                                    color: rc.withAlpha(180),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.item.rarity.label,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                letterSpacing: 3,
                                color: rc.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Opacity(
                        opacity: _waitingForTap ? 1.0 : 0.0,
                        child: Text(
                          t('PRESS  ANY  KEY', 'НАЖМИТЕ  ЛЮБУЮ  КЛАВИШУ'),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            letterSpacing: 3,
                            color: Colors.white.withAlpha(70),
                          ),
                        ),
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
