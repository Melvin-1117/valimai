import 'package:flutter/foundation.dart';

import '../models/active_workout_session.dart';
import '../models/workout.dart';
import 'active_workout_storage.dart';

/// Centralized state controller managing active, in-progress workout sessions
class ActiveWorkoutSessionController extends ChangeNotifier {
  static ActiveWorkoutSessionController _instance =
      ActiveWorkoutSessionController._internal();
  static ActiveWorkoutSessionController get instance => _instance;

  @visibleForTesting
  static void setInstance(ActiveWorkoutSessionController customInstance) {
    _instance = customInstance;
  }

  final IActiveWorkoutStorage _storage;

  ActiveWorkoutSessionController({IActiveWorkoutStorage? storage})
    : _storage = storage ?? LocalActiveWorkoutStorage();

  ActiveWorkoutSessionController._internal({IActiveWorkoutStorage? storage})
    : _storage = storage ?? LocalActiveWorkoutStorage();

  ActiveWorkoutSession? _activeSession;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  ActiveWorkoutSession? get currentSession => _activeSession;
  bool get hasActiveSession =>
      _activeSession != null && _activeSession!.isActive;

  /// Initialize controller and restore any persisted unfinished workout session
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _activeSession = await _storage.loadActiveSession();
      _isInitialized = true;
    } catch (e) {
      debugPrint('ActiveWorkoutSessionController.initialize error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Start a new session or return an existing matching active session
  Future<ActiveWorkoutSession> startOrResumeSession({
    required Workout workout,
    required DateTime targetDate,
    bool forceNew = false,
  }) async {
    // If an unfinished active session exists for this workout and forceNew is false, resume it
    if (!forceNew &&
        _activeSession != null &&
        _activeSession!.isActive &&
        (_activeSession!.workoutId == workout.id ||
            _activeSession!.workoutTitle == workout.name)) {
      return _activeSession!;
    }

    final now = DateTime.now();
    int defaultWeight = 34;
    int defaultReps = 10;
    if (workout.exercises.isNotEmpty) {
      final firstEx = workout.exercises.first;
      if (firstEx.effectiveSetConfigs.isNotEmpty) {
        defaultWeight = firstEx.effectiveSetConfigs.first.weightKg.toInt();
        defaultReps = firstEx.effectiveSetConfigs.first.reps;
      } else {
        defaultWeight = firstEx.weightKg > 0 ? firstEx.weightKg.toInt() : 34;
        defaultReps = firstEx.reps > 0 ? firstEx.reps : 10;
      }
    }

    final newSession = ActiveWorkoutSession(
      sessionId: 'session_${now.millisecondsSinceEpoch}',
      workoutId: workout.id,
      workoutTitle: workout.name,
      targetDate: DateTime(targetDate.year, targetDate.month, targetDate.day),
      startTime: now,
      lastUpdatedAt: now,
      secondsElapsed: 0,
      currentExerciseIndex: 0,
      currentWeight: defaultWeight,
      currentReps: defaultReps,
      currentRpe: 8.5,
      exercises: List<WorkoutExercise>.from(workout.exercises),
      loggedSets: const {},
      status: ActiveSessionStatus.inProgress,
    );

    _activeSession = newSession;
    await _storage.saveActiveSession(newSession);
    notifyListeners();
    return newSession;
  }

  /// Persist session updates immediately to offline storage
  Future<void> updateProgress({
    int? secondsElapsed,
    int? currentExerciseIndex,
    int? currentWeight,
    int? currentReps,
    double? currentRpe,
    List<WorkoutExercise>? exercises,
    Map<int, List<Map<String, dynamic>>>? rawLoggedSetsMap,
    Map<int, List<LoggedSetItem>>? loggedSets,
  }) async {
    if (_activeSession == null) return;

    final updated = _activeSession!.copyWith(
      lastUpdatedAt: DateTime.now(),
      secondsElapsed: secondsElapsed ?? _activeSession!.secondsElapsed,
      currentExerciseIndex:
          currentExerciseIndex ?? _activeSession!.currentExerciseIndex,
      currentWeight: currentWeight ?? _activeSession!.currentWeight,
      currentReps: currentReps ?? _activeSession!.currentReps,
      currentRpe: currentRpe ?? _activeSession!.currentRpe,
      exercises: exercises ?? _activeSession!.exercises,
      loggedSets:
          loggedSets ??
          (rawLoggedSetsMap != null
              ? ActiveWorkoutSession.fromLoggedSetsMap(rawLoggedSetsMap)
              : _activeSession!.loggedSets),
    );

    _activeSession = updated;
    await _storage.saveActiveSession(updated);
    notifyListeners();
  }

  /// Mark the session completed and clear active session persistence
  Future<void> completeSession(Workout completedSnapshot) async {
    if (_activeSession == null) return;

    // Delete active session file so it can never be mistakenly restored
    await _storage.clearActiveSession();
    _activeSession = null;
    notifyListeners();
  }

  /// Explicitly discard the active workout session
  Future<void> discardSession() async {
    await _storage.clearActiveSession();
    _activeSession = null;
    notifyListeners();
  }
}

