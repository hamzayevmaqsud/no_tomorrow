import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class Workout {
  final String id;
  String name;
  final DateTime date;
  final List<ExerciseSet> sets;
  bool get isCompleted => sets.isNotEmpty && sets.every((s) => s.done);

  Workout({
    required this.id,
    required this.name,
    required this.date,
    List<ExerciseSet>? sets,
  }) : sets = sets ?? [];

  int get totalVolume =>
      sets.where((s) => s.done).fold(0, (sum, s) => sum + s.reps * s.weight);
  int get doneSets => sets.where((s) => s.done).length;
  int get xp => doneSets * 10;
}

class ExerciseSet {
  int reps;
  int weight;
  bool done;
  ExerciseSet({this.reps = 10, this.weight = 0, this.done = false});
}

class WorkoutStore {
  static final List<Workout> workouts = [];
  static int nextId = 1;
}

// ── Screen ───────────────────────────────────────────────────────────────────

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});
  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  void _completeSet(Workout w, int setIndex) {
    if (w.sets[setIndex].done) return;
    HapticFeedback.mediumImpact();
    setState(() => w.sets[setIndex].done = true);
    GameState.instance.recordCompletion();
    GameState.instance.addXp(10);
  }

  void _delete(String id) {
    HapticFeedback.lightImpact();
    setState(() => WorkoutStore.workouts.removeWhere((w) => w.id == id));
  }

  void _showAdd() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withAlpha(140),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (ctx, _, _) => _AddWorkoutSheet(
        onAdd: (w) {
          setState(() => WorkoutStore.workouts.insert(0, w));
          Navigator.of(ctx).pop();
        },
        nextId: '${WorkoutStore.nextId++}',
      ),
      transitionBuilder: (_, anim, _, child) => SlideTransition(
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
    final workouts = WorkoutStore.workouts;
    final todayW = workouts.where((w) {
      final n = DateTime.now();
      return w.date.day == n.day && w.date.month == n.month;
    }).toList();
    final totalSets = todayW.fold(0, (s, w) => s + w.sets.length);
    final doneSets = todayW.fold(0, (s, w) => s + w.doneSets);
    final totalVol = todayW.fold(0, (s, w) => s + w.totalVolume);

    return SwipeToPop(
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0808),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 1.2,
                    colors: [Color(0xFF1A1210), Color(0xFF0E0808)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _Header(
                    totalSets: totalSets,
                    doneSets: doneSets,
                    totalVol: totalVol,
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: Colors.white.withAlpha(12)),
                  // Dashboard
                  if (workouts.isNotEmpty)
                    _Dashboard(
                      totalSets: totalSets,
                      doneSets: doneSets,
                      totalVol: totalVol,
                    ),
                  Expanded(
                    child: workouts.isEmpty
                        ? _Empty()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            itemCount: workouts.length,
                            itemBuilder: (ctx, i) => _WorkoutCard(
                              workout: workouts[i],
                              onCompleteSet: (si) =>
                                  _completeSet(workouts[i], si),
                              onDelete: () => _delete(workouts[i].id),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 36,
              left: 52,
              right: 52,
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
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.workouts,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.workouts.withAlpha(100),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'NEW  WORKOUT',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int totalSets, doneSets, totalVol;
  const _Header({
    required this.totalSets,
    required this.doneSets,
    required this.totalVol,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Text(
                'WORKOUT',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: const Color(0xFFF0D4C0),
                ),
              ),
              const SizedBox(height: 3),
              if (totalSets > 0)
                Text(
                  '$doneSets / $totalSets sets',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withAlpha(160),
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 22,
                  color: Colors.white.withAlpha(200),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final int totalSets, doneSets, totalVol;
  const _Dashboard({
    required this.totalSets,
    required this.doneSets,
    required this.totalVol,
  });
  @override
  Widget build(BuildContext context) {
    final p = totalSets == 0 ? 0.0 : doneSets / totalSets;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F2EB),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: p,
                      strokeWidth: 4,
                      backgroundColor: const Color(0xFF2A2318).withAlpha(15),
                      valueColor: AlwaysStoppedAnimation(
                        p >= 1.0 ? AppColors.success : AppColors.workouts,
                      ),
                    ),
                  ),
                  Text(
                    '${(p * 100).round()}%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A2318),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center_rounded,
                        size: 12,
                        color: AppColors.workouts,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$doneSets SETS DONE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.workouts,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.scale_rounded,
                        size: 12,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${totalVol}kg VOLUME',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.workouts.withAlpha(12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p >= 1.0 ? 'WORKOUT COMPLETE' : 'KEEP PUSHING',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: p >= 1.0
                            ? AppColors.success
                            : const Color(0xFF594536),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final void Function(int) onCompleteSet;
  final VoidCallback onDelete;
  const _WorkoutCard({
    required this.workout,
    required this.onCompleteSet,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFFF5F2EB);
    const textCol = Color(0xFF2A2318);
    const subCol = Color(0xFF8A8070);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  size: 14,
                  color: AppColors.workouts,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    workout.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: textCol,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${workout.xp} XP',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: subCol.withAlpha(120),
                  ),
                ),
              ],
            ),
            if (workout.sets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: workout.sets.asMap().entries.map((e) {
                  final s = e.value;
                  return GestureDetector(
                    onTap: () => onCompleteSet(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: s.done
                            ? AppColors.workouts.withAlpha(20)
                            : textCol.withAlpha(8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: s.done
                              ? AppColors.workouts.withAlpha(80)
                              : textCol.withAlpha(20),
                        ),
                      ),
                      child: Text(
                        s.done
                            ? '✓ ${s.reps}×${s.weight}kg'
                            : '${s.reps}×${s.weight}kg',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: s.done ? AppColors.workouts : subCol,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.fitness_center_rounded,
          size: 40,
          color: Colors.white.withAlpha(60),
        ),
        const SizedBox(height: 16),
        Text(
          'no workouts yet',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white.withAlpha(180),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'start your training',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withAlpha(120),
          ),
        ),
      ],
    ),
  );
}

class _AddWorkoutSheet extends StatefulWidget {
  final void Function(Workout) onAdd;
  final String nextId;
  const _AddWorkoutSheet({required this.onAdd, required this.nextId});
  @override
  State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  final _ctrl = TextEditingController();
  int _setCount = 3;
  int _reps = 10;
  int _weight = 20;

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    widget.onAdd(
      Workout(
        id: widget.nextId,
        name: name,
        date: DateTime.now(),
        sets: List.generate(
          _setCount,
          (_) => ExerciseSet(reps: _reps, weight: _weight),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    const bg = Color(0xFFF5F1E8);
    const cocoa = Color(0xFF594536);
    const divider = Color(0xFFDDD8CB);

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
                color: bg,
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
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.workouts.withAlpha(25),
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
                              color: AppColors.workouts,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'NEW WORKOUT',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: cocoa,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: divider,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: cocoa.withAlpha(150),
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cocoa,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Bench Press',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: cocoa.withAlpha(100),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: divider),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          _Counter(
                            label: 'SETS',
                            value: _setCount,
                            onChanged: (v) => setState(() => _setCount = v),
                            min: 1,
                            max: 10,
                          ),
                          const SizedBox(width: 12),
                          _Counter(
                            label: 'REPS',
                            value: _reps,
                            onChanged: (v) => setState(() => _reps = v),
                            min: 1,
                            max: 50,
                          ),
                          const SizedBox(width: 12),
                          _Counter(
                            label: 'KG',
                            value: _weight,
                            onChanged: (v) => setState(() => _weight = v),
                            min: 0,
                            max: 300,
                            step: 5,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: divider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                      child: GestureDetector(
                        onTap: _submit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.workouts,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.workouts.withAlpha(70),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'START WORKOUT',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: Colors.white,
                              ),
                            ),
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

class _Counter extends StatefulWidget {
  final String label;
  final int value, min, max, step;
  final ValueChanged<int> onChanged;
  const _Counter({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
  });
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(_Counter old) {
    super.didUpdateWidget(old);
    if (!_editing) _ctrl.text = '${widget.value}';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _finishEdit() {
    final v = (int.tryParse(_ctrl.text) ?? widget.value).clamp(
      widget.min,
      widget.max,
    );
    widget.onChanged(v);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    const cocoa = Color(0xFF594536);
    return Expanded(
      child: Column(
        children: [
          Text(
            widget.label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: cocoa.withAlpha(140),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: widget.value > widget.min
                    ? () => widget.onChanged(widget.value - widget.step)
                    : null,
                child: Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 20,
                  color: widget.value > widget.min
                      ? cocoa
                      : cocoa.withAlpha(50),
                ),
              ),
              const SizedBox(width: 8),
              _editing
                  ? SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        autofocus: true,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cocoa,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _finishEdit(),
                        onTapOutside: (_) => _finishEdit(),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _editing = true),
                      child: Text(
                        '${widget.value}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cocoa,
                        ),
                      ),
                    ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.value < widget.max
                    ? () => widget.onChanged(widget.value + widget.step)
                    : null,
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: 20,
                  color: widget.value < widget.max
                      ? cocoa
                      : cocoa.withAlpha(50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
