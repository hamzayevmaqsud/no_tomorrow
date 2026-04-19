import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/game_state.dart';
import '../screens/tasks_screen.dart' show TaskStore, TaskCombo;

/// Single-doc per-user persistence:
///   /users/{uid}/state/bag  →  one document with all data serialized
///
/// On auth sign-in: load bag into stores. If bag doesn't exist, app prompts
/// for username and creates initial bag. After that, autosave every [_period]
/// if anything has changed (cheap diff via JSON hash).
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  static const Duration _period = Duration(seconds: 3);

  final _fs = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSub;
  Timer? _autosave;
  String? _uid;
  String? _lastJsonHash;
  bool _loaded = false;
  bool _saving = false;

  bool get loaded => _loaded;
  String? get uid => _uid;

  /// Start listening to auth state — call once from main after Firebase.initializeApp.
  void start() {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        _stopAutosave();
        _uid = null;
        _loaded = false;
        _lastJsonHash = null;
        _clearStores();
      } else if (user.uid != _uid) {
        _uid = user.uid;
        _loaded = false;
        _lastJsonHash = null;
        _clearStores();
        // load will be triggered by the UI (AuthGate) via ensureLoaded.
      }
    });
  }

  /// Fetch the bag. Returns true if a bag exists (i.e. user already set up).
  Future<bool> ensureLoaded() async {
    final uid = _uid;
    if (uid == null) return false;
    if (_loaded) return true;
    final doc = await _fs
      .collection('users').doc(uid)
      .collection('state').doc('bag').get();
    if (!doc.exists) {
      // First-time user — caller will show UsernameScreen to set username.
      _loaded = false;
      return false;
    }
    final data = doc.data()!;
    _hydrate(data);
    _loaded = true;
    _lastJsonHash = _computeHash();
    _startAutosave();
    return true;
  }

  /// Create initial bag after first-time setup (sets username, saves empty state).
  Future<void> createInitialBag({required String username}) async {
    final uid = _uid;
    if (uid == null) return;
    GameState.instance.reset();
    GameState.instance.username = username;
    TaskStore.tasks.clear();
    TaskStore.nextId = 1;
    HabitStore.habits.clear();
    HabitStore.nextId = 1;
    RoutineStore.routines.clear();
    RoutineStore.nextId = 1;
    TaskCombo.current = 0;
    TaskCombo.lastCompletedDay = null;
    TaskCombo.freezeUsedWeek = null;
    await _saveNow();
    _loaded = true;
    _lastJsonHash = _computeHash();
    _startAutosave();
  }

  void _hydrate(Map<String, dynamic> data) {
    // GameState
    final gs = data['gameState'];
    if (gs is Map) {
      GameState.instance.loadFromJson(Map<String, dynamic>.from(gs));
    }
    // Tasks
    TaskStore.tasks.clear();
    final tasks = data['tasks'];
    if (tasks is List) {
      for (final t in tasks) {
        if (t is Map) {
          TaskStore.tasks.add(Task.fromJson(Map<String, dynamic>.from(t)));
        }
      }
    }
    TaskStore.nextId = (data['taskNextId'] as int?) ??
      (TaskStore.tasks.length + 1);
    // Habits
    HabitStore.habits.clear();
    final habits = data['habits'];
    if (habits is List) {
      for (final h in habits) {
        if (h is Map) {
          HabitStore.habits.add(Habit.fromJson(Map<String, dynamic>.from(h)));
        }
      }
    }
    HabitStore.nextId = (data['habitNextId'] as int?) ??
      (HabitStore.habits.length + 1);
    // TaskCombo
    final combo = data['combo'];
    if (combo is Map) {
      TaskCombo.current = combo['current'] ?? 0;
      TaskCombo.lastCompletedDay = combo['lastCompletedDay'] != null
        ? DateTime.parse(combo['lastCompletedDay']) : null;
      TaskCombo.freezeUsedWeek = combo['freezeUsedWeek'] != null
        ? DateTime.parse(combo['freezeUsedWeek']) : null;
    }
  }

  void _clearStores() {
    GameState.instance.reset();
    TaskStore.tasks.clear();
    TaskStore.nextId = 1;
    HabitStore.habits.clear();
    HabitStore.nextId = 1;
    RoutineStore.routines.clear();
    RoutineStore.nextId = 1;
    TaskCombo.current = 0;
    TaskCombo.lastCompletedDay = null;
    TaskCombo.freezeUsedWeek = null;
  }

  Map<String, dynamic> _snapshot() => {
    'gameState': GameState.instance.toJson(),
    'tasks': TaskStore.tasks.map((t) => t.toJson()).toList(),
    'taskNextId': TaskStore.nextId,
    'habits': HabitStore.habits.map((h) => h.toJson()).toList(),
    'habitNextId': HabitStore.nextId,
    'combo': {
      'current': TaskCombo.current,
      'lastCompletedDay': TaskCombo.lastCompletedDay?.toIso8601String(),
      'freezeUsedWeek': TaskCombo.freezeUsedWeek?.toIso8601String(),
    },
  };

  String _computeHash() => jsonEncode(_snapshot());

  void _startAutosave() {
    _autosave?.cancel();
    _autosave = Timer.periodic(_period, (_) => _tick());
  }

  void _stopAutosave() {
    _autosave?.cancel();
    _autosave = null;
  }

  Future<void> _tick() async {
    if (!_loaded || _uid == null || _saving) return;
    final h = _computeHash();
    if (h == _lastJsonHash) return;
    _lastJsonHash = h;
    await _saveNow();
  }

  Future<void> _saveNow() async {
    final uid = _uid;
    if (uid == null) return;
    _saving = true;
    try {
      final data = _snapshot();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _fs
        .collection('users').doc(uid)
        .collection('state').doc('bag').set(data);
    } finally {
      _saving = false;
    }
  }

  /// Force a save (e.g. before a known critical moment).
  Future<void> flush() async {
    if (!_loaded || _uid == null) return;
    _lastJsonHash = _computeHash();
    await _saveNow();
  }

  void dispose() {
    _authSub?.cancel();
    _stopAutosave();
  }
}
