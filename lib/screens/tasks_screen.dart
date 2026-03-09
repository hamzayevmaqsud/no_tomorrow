import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/task.dart';
import '../models/game_state.dart';
import '../models/collection_state.dart';
import '../theme/app_colors.dart';

// ── In-memory store ───────────────────────────────────────────────────────────

// ignore: library_private_types_in_public_api
class TaskStore {
  static final List<Task> tasks = [];
  static int nextId = 1;
}

// ── Priority helpers ──────────────────────────────────────────────────────────

Color _pColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:   return const Color(0xFFFF1744);  // vivid red
    case TaskPriority.medium: return const Color(0xFFFFD600);  // vivid yellow
    case TaskPriority.low:    return const Color(0xFF00E676);  // vivid green
  }
}

String _pBadge(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:   return 'P1';
    case TaskPriority.medium: return 'P2';
    case TaskPriority.low:    return 'P3';
  }
}

String _pLabel(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:   return 'CRITICAL';
    case TaskPriority.medium: return 'NORMAL';
    case TaskPriority.low:    return 'LIGHT';
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

Color _bg(bool dark)         => dark ? const Color(0xFF0D0D16) : const Color(0xFFBEC1DC);
Color _cardBg(bool dark)     => dark ? AppColors.darkCard      : const Color(0xFFFFFFFF);
Color _cardBorder(bool dark) => dark ? AppColors.darkBorder    : const Color(0xFFB8BACD);
Color _textPrimary(bool dark)=> dark ? AppColors.darkText      : AppColors.lightText;
Color _textSub(bool dark)    => dark ? AppColors.darkTextSub   : AppColors.lightTextSub;
Color _divider(bool dark)    => dark ? AppColors.darkBorder    : const Color(0xFFDDDDEE);

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
  TaskPriority? _filter;

  List<Task> get _tasks =>
      TaskStore.tasks.where((t) => t.category == widget.category).toList();

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
      // show carry-over XP for new level
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
      ),
    );
  }

  Widget _dismissible(Task task, bool isDark) => Dismissible(
    key: ValueKey(task.id),
    direction: DismissDirection.endToStart,
    onDismissed: (_) => _delete(task.id),
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 18),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(isDark ? 15 : 25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.delete_outline_rounded,
          color: Colors.red, size: 16),
    ),
    child: _TaskCard(
      key: ValueKey('k_${task.id}'),
      task: task,
      onComplete: () => _complete(task),
    ),
  );

  List<Widget> _buildGroups(bool isDark) {
    final all = _tasks;
    final widgets = <Widget>[];
    final priorities = _filter != null ? [_filter!] : TaskPriority.values;

    for (final p in priorities) {
      final group = all.where((t) => !t.isCompleted && t.priority == p).toList();
      if (group.isEmpty) continue;
      widgets.add(_SectionBand(priority: p));
      widgets.addAll(group.map((t) => _dismissible(t, isDark)));
    }

    final done = _filter != null
        ? all.where((t) => t.isCompleted && t.priority == _filter).toList()
        : all.where((t) => t.isCompleted).toList();

    if (done.isNotEmpty) {
      widgets.add(_DoneDivider(count: done.length));
      widgets.addAll(done.map((t) => _dismissible(t, isDark)));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _tasks.length;
    final done = _tasks.where((t) => t.isCompleted).length;
    final groups = _buildGroups(isDark);

    final bgImage = widget.category == TaskCategory.work
        ? 'assets/collection/Tasks menu/Work.jpg'
        : 'assets/collection/Tasks menu/Live.jpg';

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: Stack(
        children: [
          // ── Blurred category background ──────────────────────────────────
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Opacity(
                opacity: 0.13,
                child: Image.asset(bgImage, fit: BoxFit.cover),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────────────────
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
                            borderRadius: BorderRadius.circular(8),
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
                                  fontSize: 9,
                                  color: _textSub(isDark),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Progress bar ─────────────────────────────────────────────
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

                // ── Filters ───────────────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'ALL',
                        count: _tasks.length,
                        active: _filter == null,
                        color: AppColors.tasks,
                        onTap: () => setState(() => _filter = null),
                      ),
                      const SizedBox(width: 6),
                      for (final p in TaskPriority.values) ...[
                        _FilterChip(
                          label: _pBadge(p),
                          count: _tasks.where((t) => t.priority == p).length,
                          active: _filter == p,
                          color: _pColor(p),
                          onTap: () => setState(() => _filter = p),
                        ),
                        if (p != TaskPriority.low) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── List ─────────────────────────────────────────────────────
                Expanded(
                  child: groups.isEmpty
                      ? _Empty(isDark: isDark)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: groups,
                        ),
                ),
              ],
            ),
          ),

          // ── FAB ─────────────────────────────────────────────────────────
          Positioned(
            right: 24,
            bottom: 32,
            child: _AddFab(onTap: _showAdd),
          ),

          // ── TEMP: +500 XP test button ────────────────────────────────────
          Positioned(
            left: 24,
            bottom: 32,
            child: GestureDetector(
              onTap: () async {
                final fromProgress = GameState.instance.levelProgress;
                final fromLevel = GameState.instance.level;
                final didLevelUp = GameState.instance.addXp(500);
                final toProgress = didLevelUp ? 1.0 : GameState.instance.levelProgress;
                _showXp(500, Colors.orange,
                    fromProgress: fromProgress,
                    toProgress: toProgress,
                    level: fromLevel);
                await Future.delayed(const Duration(milliseconds: 800));
                if (!mounted) return;
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
                    _showXp(0, Colors.orange,
                        fromProgress: 0.0,
                        toProgress: GameState.instance.levelProgress,
                        level: GameState.instance.level);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(30),
                  border: Border.all(color: Colors.orange.withAlpha(180), width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('DEBUG +500 XP',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: Colors.orange, letterSpacing: 1,
                  )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section band ─────────────────────────────────────────────────────────────

class _SectionBand extends StatelessWidget {
  final TaskPriority priority;
  const _SectionBand({required this.priority});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _pColor(priority);
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 35 : 55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(isDark ? 120 : 160), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(isDark ? 50 : 40),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withAlpha(180), blurRadius: 6)],
            ),
          ),
          Text(_pLabel(priority),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12, fontWeight: FontWeight.w700,
              letterSpacing: 2, color: color,
            )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 45 : 65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(isDark ? 130 : 170), width: 1),
            ),
            child: Text('+${_pXp(priority)} XP each',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: color,
              )),
          ),
        ],
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
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Container(height: 0.5, color: _divider(isDark))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('DONE  $count',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: _textSub(isDark).withAlpha(140),
                letterSpacing: 1,
              )),
          ),
          Expanded(child: Container(height: 0.5, color: _divider(isDark))),
        ],
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _AddFab extends StatefulWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  State<_AddFab> createState() => _AddFabState();
}

class _AddFabState extends State<_AddFab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween(begin: 1.0, end: 0.87)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            color: AppColors.tasks,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.tasks.withAlpha(110),
                  blurRadius: 22, offset: const Offset(0, 4)),
              BoxShadow(color: AppColors.tasks.withAlpha(45),
                  blurRadius: 44, spreadRadius: 6),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label, required this.count, required this.active,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? color : color.withAlpha(isDark ? 28 : 38),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? color : color.withAlpha(isDark ? 90 : 130),
            width: 1.5,
          ),
          boxShadow: active ? [
            BoxShadow(
              color: color.withAlpha(100),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: active ? Colors.white : color,
              )),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withAlpha(55)
                      : color.withAlpha(isDark ? 55 : 70),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$count',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: active ? Colors.white : color,
                    )),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Task card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;

  const _TaskCard({super.key, required this.task, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _pColor(task.priority);
    final done = task.isCompleted;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: done ? 0.38 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _cardBg(isDark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: done
                ? _cardBorder(isDark).withAlpha(100)
                : _cardBorder(isDark),
            width: isDark ? 0.8 : 1,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Priority bar
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: done ? _cardBorder(isDark) : color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (!done) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(isDark ? 20 : 30),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: color.withAlpha(isDark ? 60 : 90),
                                          width: 0.8),
                                    ),
                                    child: Text(_pBadge(task.priority),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      )),
                                  ),
                                  const SizedBox(width: 7),
                                ],
                                Expanded(
                                  child: Text(task.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                      color: done
                                          ? _textSub(isDark)
                                          : _textPrimary(isDark),
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      decorationColor:
                                          _textSub(isDark).withAlpha(150),
                                    )),
                                ),
                              ],
                            ),

                            if (task.description.isNotEmpty && !done) ...[
                              const SizedBox(height: 5),
                              Text(task.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13, height: 1.4,
                                  color: _textSub(isDark),
                                )),
                            ],

                            if (!done) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (task.dueDate != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.tasks.withAlpha(
                                            isDark ? 30 : 25),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.tasks.withAlpha(
                                              isDark ? 80 : 70),
                                          width: 0.8),
                                      ),
                                      child: Row(children: [
                                        Icon(Icons.calendar_today_rounded,
                                            size: 10,
                                            color: AppColors.tasks),
                                        const SizedBox(width: 4),
                                        Text(_fmtDate(task.dueDate!),
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.tasks,
                                          )),
                                      ]),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (task.dueTime != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.tasks.withAlpha(
                                            isDark ? 30 : 25),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.tasks.withAlpha(
                                              isDark ? 80 : 70),
                                          width: 0.8),
                                      ),
                                      child: Row(children: [
                                        Icon(Icons.access_time_rounded,
                                            size: 11,
                                            color: AppColors.tasks),
                                        const SizedBox(width: 4),
                                        Text(_fmt24(task.dueTime!),
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.tasks,
                                          )),
                                      ]),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(isDark ? 28 : 35),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: color.withAlpha(isDark ? 70 : 100),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text('+${_pXp(task.priority)} XP',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      )),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      GestureDetector(
                        onTap: done ? null : onComplete,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: done ? AppColors.success : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: done
                                  ? AppColors.success
                                  : color.withAlpha(isDark ? 120 : 180),
                              width: 1.5,
                            ),
                          ),
                          child: done
                              ? const Icon(Icons.check_rounded,
                                  size: 12, color: Colors.white)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  final bool isDark;
  const _Empty({required this.isDark});

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
          Text('no tasks yet',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: _textSub(isDark),
            )),
          const SizedBox(height: 4),
          Text('tap the circle below to add one',
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
  const _AddSheet({required this.onAdd, required this.nextId});

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  TimeOfDay? _time;
  DateTime? _date;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _pColor(_priority);
    final sheetBg = isDark ? AppColors.darkCard : const Color(0xFFFFFFFF);
    final fieldBg = isDark ? AppColors.darkBg : const Color(0xFFE8E8F8);
    final fieldBorder = isDark ? AppColors.darkBorder : const Color(0xFFDDDDEE);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    padding: EdgeInsets.only(right: p != TaskPriority.low ? 6 : 0),
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
                        child: Text(_pBadge(p),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: isActive ? c : _textSub(isDark),
                          )),
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
                            style: GoogleFonts.jetBrainsMono(
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
                            style: GoogleFonts.jetBrainsMono(
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
                  borderRadius: BorderRadius.circular(10),
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
                    Text('ADD TASK',
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

// ── XP bar overlay (Hearthstone style) ───────────────────────────────────────

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
  late final Animation<double> _slideY;   // panel slides in from bottom
  late final Animation<double> _fill;     // bar fills up
  late final Animation<double> _labelY;  // "+XP" text bounces up
  late final Animation<double> _labelOp;
  late final Animation<double> _panelOp;

  @override
  void initState() {
    super.initState();
    // total: 2000 ms
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));

    // 0–10%: slide panel in
    _slideY = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.0, 0.12, curve: Curves.easeOutCubic)));

    // 12–75%: fill bar from real fromProgress to real toProgress with slight overshoot
    final from = widget.fromProgress;
    final to   = widget.toProgress;
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

    // 15–45%: label bounces up from bar
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

    // 82–100%: panel fades + slides out
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
                    // Floating "+XP" label above bar
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

                    // XP row
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

                    // The bar
                    Stack(
                      children: [
                        // Track
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withAlpha(12), width: 1),
                          ),
                        ),
                        // Fill
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
                        // Shine at fill edge
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
                  color: sel ? AppColors.tasks : _textSub(isDark).withAlpha(100),
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
        border: Border(
          top: BorderSide(color: border, width: 1),
        ),
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
                    border: Border.all(color: AppColors.tasks.withAlpha(80), width: 1.2),
                  ),
                ),
                Row(
                  children: [
                    _drum(count: 24, selected: _hour, ctrl: _hourCtrl,
                        onChanged: (i) => setState(() => _hour = i), isDark: isDark),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(':',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 36, fontWeight: FontWeight.w700,
                          color: AppColors.tasks.withAlpha(200))),
                    ),
                    _drum(count: 60, selected: _minute, ctrl: _minCtrl,
                        onChanged: (i) => setState(() => _minute = i), isDark: isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context, TimeOfDay(hour: _hour, minute: _minute)),
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

// ── Level-up overlay (neon arcade style) ────────────────────────────────────

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

  static const _cyan   = Color(0xFF00EEFF);
  static const _pink   = Color(0xFFFF2D9B);

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3800));
    // play intro then wait — do NOT use addStatusListener (fires on animateTo too)
    _ctrl
        .animateTo(0.74,
            duration: const Duration(milliseconds: 2600),
            curve: Curves.linear)
        .then((_) { if (mounted) setState(() => _waitingForTap = true); });
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

        // bg fade (0-8%)
        final bgOp = (t < 0.08 ? t / 0.08 : t > 0.80 ? 1-(t-0.80)/0.20 : 1.0).clamp(0.0, 1.0);

        // white flash (0-6%)
        final flashOp = (t < 0.06 ? 1 - t / 0.06 : 0.0).clamp(0.0, 1.0);

        // avatar drops in from top (8-22%)
        final avT  = Curves.easeOutBack.transform(((t-0.08)/0.14).clamp(0.0,1.0));
        final avY  = (1 - avT) * -180.0;
        final avOp = (t < 0.08 ? 0.0 : t > 0.80 ? 1-(t-0.80)/0.20 : 1.0).clamp(0.0, 1.0);

        // ring pulse (0.22+)
        final ring = t > 0.22 ? (0.55 + 0.45*sin(t * 2 * pi * 3.5)).clamp(0.0,1.0) : 0.0;

        // "LEVEL" neon on (22-38%) with flicker
        final lvlT   = ((t-0.22)/0.16).clamp(0.0,1.0);
        final lvlFlk = lvlT < 1 ? (lvlT + 0.25*sin(lvlT*pi*10)*(1-lvlT)).clamp(0.0,1.2) : 1.0;
        final lvlOp  = (t < 0.22 ? 0.0 : t > 0.80 ? 1-(t-0.80)/0.20 : lvlFlk).clamp(0.0,1.0);

        // "UP" neon on (34-52%)
        final upT    = ((t-0.34)/0.18).clamp(0.0,1.0);
        final upFlk  = upT < 1 ? (upT + 0.25*sin(upT*pi*10)*(1-upT)).clamp(0.0,1.2) : 1.0;
        final upOp   = (t < 0.34 ? 0.0 : t > 0.80 ? 1-(t-0.80)/0.20 : upFlk).clamp(0.0,1.0);

        // level badge bounces in (55-70%)
        final bdT    = Curves.elasticOut.transform(((t-0.55)/0.15).clamp(0.0,1.0));
        final bdSc   = (t < 0.55 ? 0.0 : bdT).clamp(0.0, 2.5);
        final bdOp   = (t < 0.55 ? 0.0 : t > 0.80 ? 1-(t-0.80)/0.20 : 1.0).clamp(0.0,1.0);

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

                    // white flash
                    if (flashOp > 0) Positioned.fill(
                      child: IgnorePointer(child: Opacity(
                        opacity: flashOp,
                        child: Container(color: Colors.white),
                      )),
                    ),

                    // ── center content ────────────────────────────────────
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          // avatar with pulsing neon ring
                          Transform.translate(
                            offset: Offset(0, avY),
                            child: Opacity(
                              opacity: avOp,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // outer glow ring
                                  Container(
                                    width: 152 + ring * 10,
                                    height: 152 + ring * 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _cyan.withAlpha((80 + ring * 175).round()),
                                        width: 2.5 + ring * 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _cyan.withAlpha((ring * 160).round()),
                                          blurRadius: 20 + ring * 28,
                                          spreadRadius: ring * 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // avatar circle
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

                          // "LEVEL" neon
                          Opacity(opacity: lvlOp, child: _neon('LEVEL', _cyan, 56)),

                          // "UP" neon (bigger, pink)
                          Opacity(opacity: upOp, child: _neon('UP', _pink, 82)),

                          const SizedBox(height: 22),

                          // level number badge
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
  State<_CollectibleDropOverlay> createState() => _CollectibleDropOverlayState();
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
        vsync: this, duration: const Duration(milliseconds: 2400));
    _ctrl
        .animateTo(0.80,
            duration: const Duration(milliseconds: 1800),
            curve: Curves.easeOut)
        .then((_) { if (mounted) setState(() => _waitingForTap = true); });
    if (widget.item.isVideo) {
      _initVideo();
    } else {
      _mediaReady = true; // images don't need async init
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
        final t = _ctrl.value;
        final bgOp = (t / 0.12).clamp(0.0, 1.0);
        final cardT = Curves.easeOutBack.transform(((t - 0.20) / 0.35).clamp(0.0, 1.0));
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

                      // "NEW COLLECTIBLE" label
                      Opacity(
                        opacity: Curves.easeOut.transform(labelT),
                        child: Text('NEW  COLLECTIBLE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: rc.withAlpha(200),
                            shadows: [Shadow(color: rc.withAlpha(160), blurRadius: 12)],
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

                      // Card
                      Transform.scale(
                        scale: cardT,
                        child: Container(
                          width: 200, height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: rc.withAlpha(200), width: 2),
                            boxShadow: [
                              BoxShadow(color: rc.withAlpha(100), blurRadius: 30, spreadRadius: 2),
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
                                          child: Center(child: Text(
                                            e.toString(),
                                            style: const TextStyle(color: Color(0xFFFF5252), fontSize: 9),
                                            textAlign: TextAlign.center,
                                          )),
                                        ),
                                      ))
                                : Container(
                                    color: const Color(0xFF0A0A14),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          color: rc.withAlpha(180), strokeWidth: 1.5),
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Card name + rarity
                      Opacity(
                        opacity: Curves.easeOut.transform(((t - 0.65) / 0.20).clamp(0.0, 1.0)),
                        child: Column(children: [
                          Text(widget.item.name,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              letterSpacing: 3, color: rc,
                              shadows: [Shadow(color: rc.withAlpha(180), blurRadius: 8)],
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

                      // Hint
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
