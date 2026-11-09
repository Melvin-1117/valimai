import 'package:flutter/foundation.dart';

import '../models/daily_workout.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../models/workout_rotation.dart';
import 'daily_workout_storage.dart';
import 'workout_controller.dart';
import 'workout_rotation_engine.dart';

class DailyWorkoutController extends ChangeNotifier {
  static DailyWorkoutController _instance = DailyWorkoutController._internal();
  static DailyWorkoutController get instance => _instance;

  @visibleForTesting
  static void setInstance(DailyWorkoutController customInstance) {
    _instance = customInstance;
  }

  final IDailyWorkoutStorage _storage;

  DailyWorkoutController({IDailyWorkoutStorage? storage})
    : _storage = storage ?? LocalDailyWorkoutStorage();

  DailyWorkoutController._internal({IDailyWorkoutStorage? storage})
    : _storage = storage ?? LocalDailyWorkoutStorage();

  bool _isInitialized = false;
  bool _isLoading = false;
  Map<String, DailyWorkout> _records = {};

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  Map<String, DailyWorkout> get allRecords => Map.unmodifiable(_records);

  /// Initialize and load daily workout decisions
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      _records = await _storage.loadDailyWorkouts();
      _isInitialized = true;
    } catch (e) {
      debugPrint('DailyWorkoutController.initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check whether a daily decision (planned workout, rest, or skipped) already exists for the given date
  bool hasDecisionForToday([DateTime? date]) {
    final key = DailyWorkout.formatLocalDate(date ?? DateTime.now());
    return _records.containsKey(key);
  }

  /// Get the decision record for the given date
  DailyWorkout? getDailyWorkoutForDate([DateTime? date]) {
    final key = DailyWorkout.formatLocalDate(date ?? DateTime.now());
    return _records[key];
  }

  /// Full recommendation resolving all rules: today's selection, scheduled workout, or rotation
  WorkoutRecommendation getRecommendation(DateTime date) {
    return WorkoutRotationEngine.instance.getRecommendationForDate(date);
  }

  /// Determine the recommended routine for a date using the WorkoutRotationEngine
  WorkoutRoutine? getSuggestedRoutine(DateTime date) {
    return WorkoutRotationEngine.instance.getSuggestedRoutineForRotation(date);
  }

  /// Check whether the routine is explicitly scheduled on the calendar for this date
  bool isScheduledForToday(DateTime date, WorkoutRoutine routine) {
    return WorkoutRotationEngine.instance.isScheduledForDate(date, routine);
  }

  /// Record that a workout session was completed for the date.
  /// Advances the rotation engine.
  Future<bool> markCompletedForDate(
    DateTime date, {
    String? routineId,
    DateTime? completedAt,
  }) async {
    final localDate = DailyWorkout.formatLocalDate(date);
    final now = completedAt ?? DateTime.now();

    DailyWorkout? existing = _records[localDate];
    final effectiveRoutineId =
        routineId ??
        existing?.selectedRoutineId ??
        WorkoutController.instance.getDaySchedule(date).workoutId;

    final updated =
        (existing ??
                DailyWorkout(
                  id: 'dw_${date.millisecondsSinceEpoch}',
                  localDate: localDate,
                  selectedRoutineId: effectiveRoutineId,
                  selectionType: DailySelectionType.manual,
                  status: DailyWorkoutStatus.completed,
                  selectedAt: now,
                ))
            .copyWith(
              selectedRoutineId: effectiveRoutineId,
              status: DailyWorkoutStatus.completed,
              completedAt: now,
            );

    _records[localDate] = updated;
    notifyListeners();

    return await _storage.saveDailyWorkout(updated);
  }

  /// User selects a routine for today
  Future<bool> selectRoutineForToday(
    WorkoutRoutine routine, {
    required DailySelectionType selectionType,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final localDate = DailyWorkout.formatLocalDate(targetDate);

    final record = DailyWorkout(
      id: 'dw_${targetDate.millisecondsSinceEpoch}',
      localDate: localDate,
      selectedRoutineId: routine.id,
      selectionType: selectionType,
      status: DailyWorkoutStatus.planned,
      selectedAt: DateTime.now(),
      routineName: routine.name,
      targetMuscleGroups: routine.targetMuscleGroups.join(', '),
      exerciseCount: routine.totalExercises,
      totalSets: routine.totalSets,
      estimatedDurationMinutes: routine.estimatedDurationMinutes,
    );

    _records[localDate] = record;
    notifyListeners();

    // Assign routine workout to today's date in WorkoutController
    await WorkoutController.instance.updateWorkoutForDate(
      targetDate,
      routine.toWorkout(),
    );

    return await _storage.saveDailyWorkout(record);
  }

  /// User chooses to take a Rest Day
  Future<bool> selectRestDayForToday({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final localDate = DailyWorkout.formatLocalDate(targetDate);

    final record = DailyWorkout(
      id: 'dw_${targetDate.millisecondsSinceEpoch}',
      localDate: localDate,
      selectedRoutineId: null,
      selectionType: DailySelectionType.rest,
      status: DailyWorkoutStatus.rest,
      selectedAt: DateTime.now(),
      routineName: 'Rest & Recovery Day',
    );

    _records[localDate] = record;
    notifyListeners();

    // Update WorkoutController to Rest Day (does NOT advance rotation)
    await WorkoutController.instance.setDayType(
      targetDate,
      ScheduledDayType.rest,
    );

    return await _storage.saveDailyWorkout(record);
  }

  /// User chooses to Skip for Now
  Future<bool> skipForToday({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final localDate = DailyWorkout.formatLocalDate(targetDate);

    final record = DailyWorkout(
      id: 'dw_${targetDate.millisecondsSinceEpoch}',
      localDate: localDate,
      selectedRoutineId: null,
      selectionType: DailySelectionType.skipped,
      status: DailyWorkoutStatus.skipped,
      selectedAt: DateTime.now(),
    );

    _records[localDate] = record;
    notifyListeners();

    // Does NOT assign workout, does NOT advance rotation
    return await _storage.saveDailyWorkout(record);
  }
}
