import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import 'workout_storage.dart';

class WorkoutController extends ChangeNotifier {
  static WorkoutController _instance = WorkoutController._internal();
  static WorkoutController get instance => _instance;

  @visibleForTesting
  static void setInstance(WorkoutController customInstance) {
    _instance = customInstance;
  }

  final IWorkoutStorage _storage;

  WorkoutController({IWorkoutStorage? storage})
      : _storage = storage ?? LocalWorkoutStorage() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _viewingWeekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  WorkoutController._internal({IWorkoutStorage? storage})
      : _storage = storage ?? LocalWorkoutStorage() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _viewingWeekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  bool _isInitialized = false;
  bool _isLoading = false;

  late DateTime _selectedDate;
  late DateTime _viewingWeekStart;

  Map<String, Workout> _workouts = {};
  Map<String, DaySchedule> _schedules = {};

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  DateTime get viewingWeekStart => _viewingWeekStart;

  /// Returns the 7 days of the currently viewed week (Monday to Sunday)
  List<DateTime> get daysOfViewingWeek {
    return List.generate(7, (i) {
      return _viewingWeekStart.add(Duration(days: i));
    });
  }

  /// Whether the selected date is today
  bool get isTodaySelected {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  /// Initialize controller and load cached workouts / schedules
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      _workouts = await _storage.loadWorkouts();
      _schedules = await _storage.loadSchedules();
      _isInitialized = true;
    } catch (e) {
      debugPrint('WorkoutController.initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a date on the calendar
  void selectDate(DateTime date) {
    final norm = DateTime(date.year, date.month, date.day);
    if (_selectedDate == norm) return;
    _selectedDate = norm;

    // Check if selected date is in another week; if so, update viewing week
    final weekStart = DateTime(norm.year, norm.month, norm.day - (norm.weekday - 1));
    if (_viewingWeekStart != weekStart) {
      _viewingWeekStart = weekStart;
    }

    notifyListeners();
  }

  /// Move to previous week
  void previousWeek() {
    _viewingWeekStart = _viewingWeekStart.subtract(const Duration(days: 7));
    notifyListeners();
  }

  /// Move to next week
  void nextWeek() {
    _viewingWeekStart = _viewingWeekStart.add(const Duration(days: 7));
    notifyListeners();
  }

  /// Reset to current week & select today
  void jumpToToday() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _viewingWeekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    notifyListeners();
  }

  /// Retrieve the schedule for a given date
  DaySchedule getDaySchedule(DateTime date) {
    final key = DaySchedule.dateKey(date);
    if (_schedules.containsKey(key)) {
      return _schedules[key]!;
    }

    // Default to unassigned if not explicitly scheduled
    return DaySchedule(
      date: DateTime(date.year, date.month, date.day),
      type: ScheduledDayType.unassigned,
    );
  }

  /// Retrieve the workout assigned to a given date (either custom or template)
  Workout? getWorkoutForDate(DateTime date) {
    final schedule = getDaySchedule(date);
    if (schedule.type != ScheduledDayType.workout) {
      return null;
    }

    // Custom workout takes precedence
    if (schedule.customWorkout != null) {
      return schedule.customWorkout;
    }

    // Fall back to template workout ID
    if (schedule.workoutId != null && _workouts.containsKey(schedule.workoutId)) {
      return _workouts[schedule.workoutId];
    }

    // Fall back to standard push routine if template not found
    return _workouts.values.isNotEmpty ? _workouts.values.first : null;
  }

  /// Modify/save workout assigned to a specific date
  Future<bool> updateWorkoutForDate(DateTime date, Workout updatedWorkout) async {
    final norm = DateTime(date.year, date.month, date.day);
    final key = DaySchedule.dateKey(norm);

    DaySchedule schedule = getDaySchedule(norm);
    schedule = schedule.copyWith(
      type: ScheduledDayType.workout,
      customWorkout: updatedWorkout,
      workoutId: updatedWorkout.id,
    );

    _schedules[key] = schedule;
    notifyListeners();

    try {
      final success = await _storage.saveDaySchedule(schedule);
      return success;
    } catch (e) {
      debugPrint('Failed to save updated workout: $e');
      return false;
    }
  }

  /// Toggle or set workout completion status
  Future<bool> markWorkoutCompleted(DateTime date, bool isCompleted) async {
    final norm = DateTime(date.year, date.month, date.day);
    final key = DaySchedule.dateKey(norm);

    DaySchedule schedule = getDaySchedule(norm);
    schedule = schedule.copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
    );

    _schedules[key] = schedule;
    notifyListeners();

    try {
      return await _storage.saveDaySchedule(schedule);
    } catch (e) {
      debugPrint('Failed to mark workout completion: $e');
      return false;
    }
  }

  /// Assign a workout template or change day type
  Future<bool> setDayType(
    DateTime date,
    ScheduledDayType type, {
    String? workoutId,
  }) async {
    final norm = DateTime(date.year, date.month, date.day);
    final key = DaySchedule.dateKey(norm);

    DaySchedule schedule = getDaySchedule(norm);
    schedule = schedule.copyWith(
      type: type,
      workoutId: workoutId,
      customWorkout: type == ScheduledDayType.workout ? schedule.customWorkout : null,
    );

    _schedules[key] = schedule;
    notifyListeners();

    try {
      return await _storage.saveDaySchedule(schedule);
    } catch (e) {
      debugPrint('Failed to set day type: $e');
      return false;
    }
  }
}
