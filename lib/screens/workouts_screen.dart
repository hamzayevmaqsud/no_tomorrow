import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';
import '../widgets/jelly_button.dart';
import '../widgets/animated_empty.dart';
import '../l10n/app_locale.dart';

const _kBordo = Color(0xFF8B1A2B); // burgundy/bordeaux accent

// ── Models ──────────────────────────────────────────────────────────────────

class SetEntry {
  int weight;
  int reps;
  bool done;
  SetEntry({this.weight = 20, this.reps = 10, this.done = false});
}

class MuscleGroup {
  final String id, emoji;
  final String Function() name;
  final List<String Function()> exercises;
  const MuscleGroup({required this.id, required this.emoji, required this.name, required this.exercises});
}

final kMuscleGroups = [
  MuscleGroup(id: 'chest', emoji: '🫁', name: () => t('Chest', 'Грудь'), exercises: [
    () => t('Bench Press', 'Жим лёжа'),
    () => t('Incline Bench Press', 'Жим на наклонной'),
    () => t('Dumbbell Flyes', 'Разведение гантелей'),
    () => t('Cable Crossover', 'Кроссовер'),
    () => t('Push-Ups', 'Отжимания'),
    () => t('Dips (Chest)', 'Брусья (грудь)'),
  ]),
  MuscleGroup(id: 'back', emoji: '🔙', name: () => t('Back', 'Спина'), exercises: [
    () => t('Pull-Ups', 'Подтягивания'),
    () => t('Lat Pulldown', 'Тяга верхнего блока'),
    () => t('Barbell Row', 'Тяга штанги в наклоне'),
    () => t('Dumbbell Row', 'Тяга гантели в наклоне'),
    () => t('Seated Cable Row', 'Тяга нижнего блока'),
    () => t('Deadlift', 'Становая тяга'),
    () => t('T-Bar Row', 'Тяга Т-грифа'),
  ]),
  MuscleGroup(id: 'legs', emoji: '🦵', name: () => t('Legs', 'Ноги'), exercises: [
    () => t('Squat', 'Присед'),
    () => t('Leg Press', 'Жим ногами'),
    () => t('Lunges', 'Выпады'),
    () => t('Leg Extension', 'Разгибание ног'),
    () => t('Leg Curl', 'Сгибание ног'),
    () => t('Calf Raise', 'Подъём на носки'),
    () => t('Romanian Deadlift', 'Румынская тяга'),
    () => t('Bulgarian Split Squat', 'Болгарские выпады'),
  ]),
  MuscleGroup(id: 'shoulders', emoji: '🏋️', name: () => t('Shoulders', 'Плечи'), exercises: [
    () => t('Overhead Press', 'Жим стоя'),
    () => t('Lateral Raise', 'Махи в стороны'),
    () => t('Front Raise', 'Махи перед собой'),
    () => t('Face Pull', 'Тяга к лицу'),
    () => t('Arnold Press', 'Жим Арнольда'),
    () => t('Reverse Flyes', 'Обратные разведения'),
  ]),
  MuscleGroup(id: 'arms', emoji: '💪', name: () => t('Arms', 'Руки'), exercises: [
    () => t('Bicep Curl', 'Сгибание на бицепс'),
    () => t('Hammer Curl', 'Молотковые сгибания'),
    () => t('Tricep Pushdown', 'Разгибание на трицепс'),
    () => t('Skull Crushers', 'Французский жим'),
    () => t('Preacher Curl', 'Сгибание на скамье Скотта'),
    () => t('Dips (Triceps)', 'Брусья (трицепс)'),
  ]),
  MuscleGroup(id: 'core', emoji: '🧱', name: () => t('Core', 'Кор'), exercises: [
    () => t('Plank', 'Планка'),
    () => t('Crunches', 'Скручивания'),
    () => t('Leg Raise', 'Подъём ног'),
    () => t('Russian Twist', 'Русский твист'),
    () => t('Ab Wheel', 'Ролик для пресса'),
    () => t('Cable Woodchop', 'Дровосек на блоке'),
  ]),
  MuscleGroup(id: 'cardio', emoji: '🏃', name: () => t('Cardio', 'Кардио'), exercises: [
    () => t('Treadmill', 'Беговая дорожка'),
    () => t('Cycling', 'Велотренажёр'),
    () => t('Rowing', 'Гребной тренажёр'),
    () => t('Elliptical', 'Эллипс'),
    () => t('Jump Rope', 'Скакалка'),
    () => t('Stairmaster', 'Степпер'),
  ]),
];

class Exercise {
  final String id;
  String name;
  String muscleEmoji;
  final List<SetEntry> sets;
  int restSeconds;

  Exercise({
    required this.id,
    required this.name,
    this.muscleEmoji = '🏋️',
    List<SetEntry>? sets,
    this.restSeconds = 90,
  }) : sets = sets ?? [SetEntry()];

  int get doneSets => sets.where((s) => s.done).length;
  int get totalVolume => sets.where((s) => s.done).fold(0, (v, s) => v + s.weight * s.reps);
  bool get isCompleted => sets.isNotEmpty && sets.every((s) => s.done);
  double get progress => sets.isEmpty ? 0.0 : doneSets / sets.length;
}

class WorkoutSession {
  final String id;
  final DateTime date;
  final List<Exercise> exercises;
  bool finished;

  WorkoutSession({
    required this.id,
    required this.date,
    List<Exercise>? exercises,
    this.finished = false,
  }) : exercises = exercises ?? [];

  int get totalSets => exercises.fold(0, (s, e) => s + e.sets.length);
  int get doneSets => exercises.fold(0, (s, e) => s + e.doneSets);
  int get totalVolume => exercises.fold(0, (v, e) => v + e.totalVolume);
  int get totalExercises => exercises.length;
  bool get isCompleted => exercises.isNotEmpty && exercises.every((e) => e.isCompleted);
  double get progress => totalSets == 0 ? 0.0 : doneSets / totalSets;
  int get xp => doneSets * 10;

  String get dateLabel {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) return t('TODAY', 'СЕГОДНЯ');
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day && date.month == yesterday.month) return t('YESTERDAY', 'ВЧЕРА');
    final months = [t('JAN','ЯНВ'),t('FEB','ФЕВ'),t('MAR','МАР'),t('APR','АПР'),t('MAY','МАЙ'),t('JUN','ИЮН'),t('JUL','ИЮЛ'),t('AUG','АВГ'),t('SEP','СЕН'),t('OCT','ОКТ'),t('NOV','НОЯ'),t('DEC','ДЕК')];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class WorkoutStore {
  static final List<WorkoutSession> sessions = [];
  static int _nextId = 1;
  static String nextId() => '${_nextId++}';

  /// Tracks last used weight/reps per exercise name for "previous performance" display
  static final Map<String, ({int weight, int reps})> lastPerformance = {};

  static void recordPerformance(String exerciseName, int weight, int reps) {
    lastPerformance[exerciseName] = (weight: weight, reps: reps);
  }
}

// ── Screen ──────────────────────────────────────────────────────────────────

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});
  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  // Rest timer state
  Timer? _restTimer;
  int _restRemaining = 0;
  int _restTotal = 0;
  bool get _resting => _restRemaining > 0;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restTotal = seconds;
      _restRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemaining <= 1) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _restRemaining = 0);
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _restRemaining = 0);
  }

  void _completeSet(Exercise exercise, int setIndex) {
    if (exercise.sets[setIndex].done) return;
    HapticFeedback.mediumImpact();
    setState(() => exercise.sets[setIndex].done = true);
    WorkoutStore.recordPerformance(exercise.name, exercise.sets[setIndex].weight, exercise.sets[setIndex].reps);
    GameState.instance.recordCompletion();
    GameState.instance.addXp(10);
    // Auto-start rest timer
    _startRest(exercise.restSeconds);
  }

  void _changeWeight(Exercise ex, int si, int delta) {
    setState(() => ex.sets[si].weight = (ex.sets[si].weight + delta).clamp(0, 500));
  }

  void _changeReps(Exercise ex, int si, int delta) {
    setState(() => ex.sets[si].reps = (ex.sets[si].reps + delta).clamp(1, 100));
  }

  void _addSet(Exercise exercise) {
    HapticFeedback.lightImpact();
    final last = exercise.sets.isNotEmpty ? exercise.sets.last : null;
    setState(() => exercise.sets.add(SetEntry(
      weight: last?.weight ?? 20,
      reps: last?.reps ?? 10,
    )));
  }

  void _deleteExercise(WorkoutSession session, int exerciseIndex) {
    HapticFeedback.lightImpact();
    setState(() => session.exercises.removeAt(exerciseIndex));
  }

  void _deleteSession(String id) {
    HapticFeedback.lightImpact();
    setState(() => WorkoutStore.sessions.removeWhere((s) => s.id == id));
  }

  void _newSession() {
    final session = WorkoutSession(id: WorkoutStore.nextId(), date: DateTime.now());
    setState(() => WorkoutStore.sessions.insert(0, session));
    _showAddExercise(session);
  }

  void _showAddExercise(WorkoutSession session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF10080C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _AddExerciseSheet(
        onAdd: (exercise) {
          setState(() => session.exercises.add(exercise));
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = WorkoutStore.sessions;
    final todaySessions = sessions.where((s) {
      final n = DateTime.now();
      return s.date.day == n.day && s.date.month == n.month && s.date.year == n.year;
    }).toList();
    final totalSets = todaySessions.fold(0, (v, s) => v + s.totalSets);
    final doneSets = todaySessions.fold(0, (v, s) => v + s.doneSets);
    return SwipeToPop(child: Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(children: [
        // Background
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.2,
            colors: [Color(0xFF1A0A10), Color(0xFF0A0A0F)],
          )),
        )),

        SafeArea(child: Column(children: [
          // Header
          _Header(totalSets: totalSets, doneSets: doneSets),
          const SizedBox(height: 10),
          Container(height: 1, color: Colors.white.withAlpha(12)),

          // Rest timer banner
          if (_resting) _RestTimerBanner(
            remaining: _restRemaining,
            total: _restTotal,
            onSkip: _skipRest,
          ),

          // Content
          Expanded(
            child: sessions.isEmpty
                ? AnimatedEmpty(
                    icon: Icons.fitness_center_rounded,
                    title: t('No workouts yet', 'Тренировок пока нет'),
                    subtitle: t('Tap + to start your session', 'Нажми + чтобы начать тренировку'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: sessions.length,
                    itemBuilder: (ctx, i) => _SessionCard(
                      session: sessions[i],
                      onCompleteSet: _completeSet,
                      onAddSet: _addSet,
                      onAddExercise: () => _showAddExercise(sessions[i]),
                      onDeleteExercise: (ei) => _deleteExercise(sessions[i], ei),
                      onDeleteSession: () => _deleteSession(sessions[i].id),
                      onChangeWeight: _changeWeight,
                      onChangeReps: _changeReps,
                    ),
                  ),
          ),
        ])),

        // FAB
        Positioned(bottom: 36, left: 52, right: 52,
          child: ClipRRect(borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: JellyButton(onTap: _newSession,
                child: Container(height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(22), borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withAlpha(40)),
                  ),
                  child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: _kBordo, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _kBordo.withAlpha(100), blurRadius: 12)]),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    Text(t('NEW  WORKOUT', 'НОВАЯ  ТРЕНИРОВКА'), style: GoogleFonts.playfairDisplay(
                      fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2,
                      color: Colors.white.withAlpha(200))),
                  ])),
                ),
              ),
            ),
          ),
        ),
      ]),
    ));
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int totalSets, doneSets;
  const _Header({required this.totalSets, required this.doneSets});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(40))),
            child: Icon(Icons.chevron_left_rounded, size: 22,
              color: Colors.white.withAlpha(200)))),
        const Spacer(),
        Text(t('WORKOUT', 'ТРЕНИРОВКА'), style: GoogleFonts.playfairDisplay(
          fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic,
          letterSpacing: 2, color: const Color(0xFFE0C4C4))),
        const Spacer(),
        if (totalSets > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _kBordo.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$doneSets/$totalSets', style: GoogleFonts.jetBrainsMono(
              fontSize: 11, fontWeight: FontWeight.w700, color: _kBordo)),
          )
        else
          const SizedBox(width: 36), // balance
      ]),
    );
  }
}

// ── Rest Timer Banner ───────────────────────────────────────────────────────

class _RestTimerBanner extends StatelessWidget {
  final int remaining, total;
  final VoidCallback onSkip;
  const _RestTimerBanner({required this.remaining, required this.total, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? remaining / total : 0.0;
    final mins = remaining ~/ 60;
    final secs = remaining % 60;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: _kBordo.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBordo.withAlpha(60)),
      ),
      child: Row(children: [
        // Circular timer
        SizedBox(width: 44, height: 44,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 44, height: 44,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: Colors.white.withAlpha(15),
                valueColor: AlwaysStoppedAnimation(_kBordo),
              )),
            Text('$mins:${secs.toString().padLeft(2, '0')}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ])),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('REST', 'ОТДЫХ'), style: GoogleFonts.jetBrainsMono(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 2, color: _kBordo)),
            const SizedBox(height: 2),
            Text(t('Next set in $remaining s', 'Следующий подход через $remaining с'),
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withAlpha(140))),
          ],
        )),
        GestureDetector(
          onTap: onSkip,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            child: Text(t('SKIP', 'ПРОПУСТИТЬ'), style: GoogleFonts.jetBrainsMono(
              fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(180))),
          ),
        ),
      ]),
    );
  }
}

// ── Session Card ────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  final void Function(Exercise, int) onCompleteSet;
  final void Function(Exercise) onAddSet;
  final VoidCallback onAddExercise;
  final void Function(int) onDeleteExercise;
  final VoidCallback onDeleteSession;
  final void Function(Exercise, int, int) onChangeWeight;
  final void Function(Exercise, int, int) onChangeReps;

  const _SessionCard({
    required this.session,
    required this.onCompleteSet,
    required this.onAddSet,
    required this.onAddExercise,
    required this.onDeleteExercise,
    required this.onDeleteSession,
    required this.onChangeWeight,
    required this.onChangeReps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF12080C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Session header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
          child: Row(children: [
            Icon(Icons.fitness_center_rounded, size: 16, color: _kBordo),
            const SizedBox(width: 8),
            Text(session.dateLabel, style: GoogleFonts.jetBrainsMono(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 1.5, color: Colors.white.withAlpha(120))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(15),
                borderRadius: BorderRadius.circular(6)),
              child: Text('+${session.xp} XP', style: GoogleFonts.jetBrainsMono(
                fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.gold)),
            ),
            const Spacer(),
            // Progress
            SizedBox(width: 32, height: 32,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(width: 32, height: 32,
                  child: CircularProgressIndicator(
                    value: session.progress,
                    strokeWidth: 2.5,
                    backgroundColor: Colors.white.withAlpha(12),
                    valueColor: AlwaysStoppedAnimation(session.isCompleted ? const Color(0xFF22C55E) : _kBordo),
                  )),
                Text('${session.doneSets}/${session.totalSets}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 7, fontWeight: FontWeight.w700, color: Colors.white)),
              ])),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onDeleteSession,
              child: Icon(Icons.close_rounded, size: 14, color: Colors.white.withAlpha(60)),
            ),
          ]),
        ),

        const SizedBox(height: 8),

        // Exercise cards
        ...session.exercises.asMap().entries.map((entry) =>
          _ExerciseCard(
            exercise: entry.value,
            onCompleteSet: (si) => onCompleteSet(entry.value, si),
            onAddSet: () => onAddSet(entry.value),
            onDelete: () => onDeleteExercise(entry.key),
            onChangeWeight: (si, delta) => onChangeWeight(entry.value, si, delta),
            onChangeReps: (si, delta) => onChangeReps(entry.value, si, delta),
          )),

        // Add exercise button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: GestureDetector(
            onTap: onAddExercise,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(15)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_rounded, size: 16, color: _kBordo.withAlpha(180)),
                const SizedBox(width: 6),
                Text(t('ADD EXERCISE', 'ДОБАВИТЬ УПРАЖНЕНИЕ'), style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1,
                  color: _kBordo.withAlpha(180))),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Exercise Card ───────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final void Function(int) onCompleteSet;
  final VoidCallback onAddSet;
  final VoidCallback onDelete;
  final void Function(int setIndex, int delta) onChangeWeight;
  final void Function(int setIndex, int delta) onChangeReps;

  const _ExerciseCard({
    required this.exercise,
    required this.onCompleteSet,
    required this.onAddSet,
    required this.onDelete,
    required this.onChangeWeight,
    required this.onChangeReps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Exercise header
        Row(children: [
          Text(exercise.muscleEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text(exercise.name, style: GoogleFonts.playfairDisplay(
            fontSize: 15, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic,
            color: const Color(0xFFE0C4C4)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(6)),
            child: Text('${exercise.restSeconds}s ${t('rest', 'отд.')}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(80))),
          ),
          const SizedBox(width: 6),
          GestureDetector(onTap: onDelete,
            child: Icon(Icons.close_rounded, size: 13, color: Colors.white.withAlpha(50))),
        ]),
        if (WorkoutStore.lastPerformance.containsKey(exercise.name)) ...[
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.history_rounded, size: 12, color: Colors.white.withAlpha(40)),
            const SizedBox(width: 4),
            Text('${t('Last', 'Пред')}: ${WorkoutStore.lastPerformance[exercise.name]!.weight}kg \u00d7 ${WorkoutStore.lastPerformance[exercise.name]!.reps}',
              style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(40))),
          ]),
        ],
        const SizedBox(height: 10),

        // Sets header
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            SizedBox(width: 36, child: Text(t('SET', 'ПОД'), style: _headerStyle())),
            Expanded(child: Center(child: Text(t('KG', 'КГ'), style: _headerStyle()))),
            Expanded(child: Center(child: Text(t('REPS', 'ПОВТ'), style: _headerStyle()))),
            const SizedBox(width: 44),
          ]),
        ),

        // Set rows
        ...exercise.sets.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: s.done ? _kBordo.withAlpha(10) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              SizedBox(width: 36,
                child: Text('${i + 1}', style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: s.done ? _kBordo : Colors.white.withAlpha(100)))),
              Expanded(child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(onTap: s.done ? null : () => onChangeWeight(i, -5),
                    child: Icon(Icons.chevron_left_rounded, size: 16, color: Colors.white.withAlpha(60))),
                  const SizedBox(width: 4),
                  Text('${s.weight}', style: GoogleFonts.jetBrainsMono(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: s.done ? Colors.white.withAlpha(100) : Colors.white)),
                  const SizedBox(width: 4),
                  GestureDetector(onTap: s.done ? null : () => onChangeWeight(i, 5),
                    child: Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white.withAlpha(60))),
                ]))),
              Expanded(child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(onTap: s.done ? null : () => onChangeReps(i, -1),
                    child: Icon(Icons.chevron_left_rounded, size: 16, color: Colors.white.withAlpha(60))),
                  const SizedBox(width: 4),
                  Text('${s.reps}', style: GoogleFonts.jetBrainsMono(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: s.done ? Colors.white.withAlpha(100) : Colors.white)),
                  const SizedBox(width: 4),
                  GestureDetector(onTap: s.done ? null : () => onChangeReps(i, 1),
                    child: Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white.withAlpha(60))),
                ]))),
              SizedBox(width: 44,
                child: GestureDetector(
                  onTap: s.done ? null : () => onCompleteSet(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: s.done
                          ? AppColors.success.withAlpha(20)
                          : _kBordo.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: s.done
                          ? AppColors.success.withAlpha(60)
                          : _kBordo.withAlpha(40)),
                    ),
                    child: Center(child: Icon(
                      s.done ? Icons.check_rounded : Icons.play_arrow_rounded,
                      size: 16,
                      color: s.done ? AppColors.success : _kBordo)),
                  ),
                ),
              ),
            ]),
          );
        }),

        // Add set button
        GestureDetector(
          onTap: onAddSet,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withAlpha(12)),
            ),
            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, size: 14, color: Colors.white.withAlpha(60)),
              const SizedBox(width: 4),
              Text(t('ADD SET', 'ДОБАВИТЬ ПОДХОД'), style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(60))),
            ])),
          ),
        ),
      ]),
    );
  }

  TextStyle _headerStyle() => GoogleFonts.jetBrainsMono(
    fontSize: 8, fontWeight: FontWeight.w700,
    letterSpacing: 1.5, color: Colors.white.withAlpha(50));
}

// ── Add Exercise Sheet ──────────────────────────────────────────────────────

class _AddExerciseSheet extends StatefulWidget {
  final void Function(Exercise) onAdd;
  const _AddExerciseSheet({required this.onAdd});
  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _nameCtrl = TextEditingController();
  int _sets = 3;
  int _reps = 10;
  int _weight = 20;
  int _rest = 90;
  String _selectedEmoji = '🏋️';

  // null = show catalog, non-null = show config for selected exercise
  String? _pickedName;

  static const _restOptions = [30, 60, 90, 120, 180];

  void _pickExercise(String name, String emoji) {
    setState(() {
      _pickedName = name;
      _selectedEmoji = emoji;
      _nameCtrl.text = name;
    });
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onAdd(Exercise(
      id: WorkoutStore.nextId(),
      name: name,
      muscleEmoji: _selectedEmoji,
      sets: List.generate(_sets, (_) => SetEntry(weight: _weight, reps: _reps)),
      restSeconds: _rest,
    ));
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;

    // Step 2: configure sets/reps/weight/rest
    if (_pickedName != null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, kb + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          // Back + title
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _pickedName = null),
              child: Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white.withAlpha(140)),
            ),
            const SizedBox(width: 12),
            Text(_selectedEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(child: Text(_pickedName!, style: GoogleFonts.playfairDisplay(
              fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic,
              color: const Color(0xFFE0C4C4)))),
          ]),
          const SizedBox(height: 20),

          // Counters row
          Row(children: [
            _MiniCounter(label: t('SETS', 'ПОДХ'), value: _sets,
              onChanged: (v) => setState(() => _sets = v), min: 1, max: 10),
            const SizedBox(width: 10),
            _MiniCounter(label: t('REPS', 'ПОВТ'), value: _reps,
              onChanged: (v) => setState(() => _reps = v), min: 1, max: 50),
            const SizedBox(width: 10),
            _MiniCounter(label: t('KG', 'КГ'), value: _weight,
              onChanged: (v) => setState(() => _weight = v), min: 0, max: 300, step: 5),
          ]),
          const SizedBox(height: 14),

          // Rest selector
          SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Row(children: [
              Text(t('REST', 'ОТДЫХ'), style: GoogleFonts.jetBrainsMono(
                fontSize: 9, fontWeight: FontWeight.w700,
                letterSpacing: 1.5, color: Colors.white.withAlpha(60))),
              const SizedBox(width: 10),
              ...(_restOptions.map((sec) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _rest = sec),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _rest == sec ? _kBordo.withAlpha(25) : Colors.white.withAlpha(6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _rest == sec
                          ? _kBordo.withAlpha(80) : Colors.white.withAlpha(15))),
                    child: Text('${sec}s', style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: _rest == sec ? _kBordo : Colors.white.withAlpha(80))),
                  ),
                ),
              ))),
            ]),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: _kBordo, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _kBordo.withAlpha(70), blurRadius: 14, offset: const Offset(0, 4))]),
              child: Center(child: Text(t('ADD', 'ДОБАВИТЬ'), style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.white))),
            ),
          ),
        ]),
      );
    }

    // Step 1: exercise catalog
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          Text(t('CHOOSE EXERCISE', 'ВЫБЕРИ УПРАЖНЕНИЕ'), style: GoogleFonts.playfairDisplay(
            fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic,
            letterSpacing: 1, color: const Color(0xFFE0C4C4))),
          const SizedBox(height: 12),

          // Custom name field
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            decoration: InputDecoration(
              hintText: t('or type custom name...', 'или введи своё...'),
              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white.withAlpha(30)),
              filled: true, fillColor: Colors.white.withAlpha(6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(Icons.arrow_forward_rounded, color: _kBordo, size: 20),
                onPressed: () {
                  if (_nameCtrl.text.trim().isNotEmpty) {
                    _pickExercise(_nameCtrl.text.trim(), '🏋️');
                  }
                },
              ),
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) _pickExercise(v.trim(), '🏋️');
            },
          ),
          const SizedBox(height: 12),

          // Muscle group catalog
          Expanded(child: ListView(
            children: kMuscleGroups.map((group) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Text(group.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(group.name().toUpperCase(), style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      letterSpacing: 2, color: _kBordo)),
                  ]),
                ),
                Wrap(spacing: 6, runSpacing: 6,
                  children: group.exercises.map((exFn) {
                    final name = exFn();
                    return GestureDetector(
                      onTap: () => _pickExercise(name, group.emoji),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withAlpha(12)),
                        ),
                        child: Text(name, style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(200))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
              ],
            )).toList(),
          )),
        ]),
      ),
    );
  }
}

class _MiniCounter extends StatelessWidget {
  final String label;
  final int value, min, max, step;
  final ValueChanged<int> onChanged;
  const _MiniCounter({required this.label, required this.value,
    required this.onChanged, this.min = 0, this.max = 100, this.step = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(children: [
        Text(label, style: GoogleFonts.jetBrainsMono(
          fontSize: 8, fontWeight: FontWeight.w700,
          letterSpacing: 1.5, color: Colors.white.withAlpha(50))),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: value > min ? () => onChanged(value - step) : null,
            child: Icon(Icons.remove_rounded, size: 18,
              color: value > min ? Colors.white.withAlpha(140) : Colors.white.withAlpha(30))),
          const SizedBox(width: 10),
          Text('$value', style: GoogleFonts.jetBrainsMono(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: value < max ? () => onChanged(value + step) : null,
            child: Icon(Icons.add_rounded, size: 18,
              color: value < max ? Colors.white.withAlpha(140) : Colors.white.withAlpha(30))),
        ]),
      ]),
    ));
  }
}
