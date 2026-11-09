import 'package:flutter/foundation.dart';

import '../models/daily_workout.dart';
import '../models/weekly_schedule.dart';
import '../models/workout.dart';
import 'daily_workout_controller.dart';
import 'routine_controller.dart';
import 'workout_history_controller.dart';
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
    _viewingWeekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
  }

  WorkoutController._internal({IWorkoutStorage? storage})
    : _storage = storage ?? LocalWorkoutStorage() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _viewingWeekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
  }

  bool _isInitialized = false;
  bool _isLoading = false;

  late DateTime _selectedDate;
  late DateTime _viewingWeekStart;

  Map<String, Workout> _workouts = {};
  Map<String, DaySchedule> _schedules = {};
  Map<int, WeeklyDayAssignment> _weeklyPlan = {};

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  DateTime get viewingWeekStart => _viewingWeekStart;
  Map<String, DaySchedule> get schedules => Map.unmodifiable(_schedules);
  Map<int, WeeklyDayAssignment> get weeklyPlan => Map.unmodifiable(_weeklyPlan);

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

  /// Initialize controller and load cached workouts / schedules / weekly plan
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      _workouts = await _storage.loadWorkouts();
      _schedules = await _storage.loadSchedules();
      _weeklyPlan = await _storage.loadWeeklyPlan();
      _isInitialized = true;
    } catch (e) {
      debugPrint('WorkoutController.initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retrieve the recurring weekly plan assignment for a weekday (1 = Monday, 7 = Sunday)
  WeeklyDayAssignment getWeeklyAssignment(int weekday) {
    if (_weeklyPlan.containsKey(weekday)) {
      return _weeklyPlan[weekday]!;
    }
    return WeeklyDayAssignment(
      weekday: weekday,
      type: ScheduledDayType.unassigned,
    );
  }

  /// Assign an active routine to a weekday
  Future<bool> assignRoutineToWeekday(int weekday, String routineId) async {
    final assignment = WeeklyDayAssignment(
      weekday: weekday,
      type: ScheduledDayType.workout,
      routineId: routineId,
    );
    _weeklyPlan[weekday] = assignment;
    notifyListeners();

    try {
      return await _storage.saveWeeklyPlan(_weeklyPlan);
    } catch (e) {
      debugPrint('Failed to assign routine to weekday: $e');
      return false;
    }
  }

  /// Mark a weekday as Rest Day
  Future<bool> setWeekdayAsRest(int weekday) async {
    final assignment = WeeklyDayAssignment(
      weekday: weekday,
      type: ScheduledDayType.rest,
    );
    _weeklyPlan[weekday] = assignment;
    notifyListeners();

    try {
      return await _storage.saveWeeklyPlan(_weeklyPlan);
    } catch (e) {
      debugPrint('Failed to set weekday as rest: $e');
      return false;
    }
  }

  /// Remove an assignment from a weekday
  Future<bool> removeWeekdayAssignment(int weekday) async {
    final assignment = WeeklyDayAssignment(
      weekday: weekday,
      type: ScheduledDayType.unassigned,
    );
    _weeklyPlan[weekday] = assignment;
    notifyListeners();

    try {
      return await _storage.saveWeeklyPlan(_weeklyPlan);
    } catch (e) {
      debugPrint('Failed to remove weekday assignment: $e');
      return false;
    }
  }

  /// Save the entire recurring weekly plan
  Future<bool> saveWeeklyPlan(Map<int, WeeklyDayAssignment> newPlan) async {
    _weeklyPlan = Map<int, WeeklyDayAssignment>.from(newPlan);
    notifyListeners();

    try {
      return await _storage.saveWeeklyPlan(_weeklyPlan);
    } catch (e) {
      debugPrint('Failed to save weekly plan: $e');
      return false;
    }
  }

  /// Select a date on the calendar
  void selectDate(DateTime date) {
    final norm = DateTime(date.year, date.month, date.day);
    if (_selectedDate == norm) return;
    _selectedDate = norm;

    // Check if selected date is in another week; if so, update viewing week
    final weekStart = DateTime(
      norm.year,
      norm.month,
      norm.day - (norm.weekday - 1),
    );
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
    _viewingWeekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    notifyListeners();
  }

  /// Retrieve the schedule for a given date resolving across the 4 data priorities:
  /// 1. Explicit daily selection or date-specific override
  /// 2. Scheduled routine for that weekday (Recurring weekly plan)
  /// 3. Rotation recommendation if no schedule exists
  /// 4. Rest Day or unassigned state
  DaySchedule getDaySchedule(DateTime date) {
    final norm = DateTime(date.year, date.month, date.day);
    final key = DaySchedule.dateKey(norm);

    // 1. PRIORITY 1: Explicit daily selection or date-specific override
    try {
      final dailyRecord = DailyWorkoutController.instance
          .getDailyWorkoutForDate(norm);
      if (dailyRecord != null) {
        final existingSchedule = _schedules[key];
        final customWorkoutOverride = existingSchedule?.customWorkout;

        if (dailyRecord.status == DailyWorkoutStatus.completed) {
          final routine = dailyRecord.selectedRoutineId != null
              ? RoutineController.instance.getRoutineById(
                  dailyRecord.selectedRoutineId!,
                )
              : null;
          return DaySchedule(
            date: norm,
            type: ScheduledDayType.workout,
            workoutId: dailyRecord.selectedRoutineId,
            customWorkout: customWorkoutOverride ?? routine?.toWorkout(),
            isCompleted: true,
            completedAt: dailyRecord.completedAt,
          );
        } else if (dailyRecord.isRest) {
          return DaySchedule(date: norm, type: ScheduledDayType.rest);
        } else if (dailyRecord.isSkipped) {
          return DaySchedule(date: norm, type: ScheduledDayType.unassigned);
        } else if (dailyRecord.hasWorkout) {
          final routine = RoutineController.instance.getRoutineById(
            dailyRecord.selectedRoutineId!,
          );
          return DaySchedule(
            date: norm,
            type: ScheduledDayType.workout,
            workoutId: dailyRecord.selectedRoutineId,
            customWorkout: customWorkoutOverride ?? routine?.toWorkout(),
            isCompleted: false,
          );
        }
      }
    } catch (_) {}

    // Check explicit date-specific record in _schedules
    if (_schedules.containsKey(key)) {
      final schedule = _schedules[key]!;
      if (schedule.isCompleted || schedule.customWorkout != null) {
        return schedule;
      }
      if (schedule.type == ScheduledDayType.rest ||
          schedule.type == ScheduledDayType.unassigned) {
        return schedule;
      }
      if (schedule.workoutId != null) {
        final routine = RoutineController.instance.getRoutineById(
          schedule.workoutId!,
        );
        if (routine != null) {
          return schedule.copyWith(customWorkout: routine.toWorkout());
        }
        return schedule;
      }
    }

    // 2. PRIORITY 2: Scheduled routine for that weekday (Recurring weekly plan)
    final assignment = getWeeklyAssignment(norm.weekday);
    if (assignment.isWorkout && assignment.routineId != null) {
      final routine = RoutineController.instance.getRoutineById(
        assignment.routineId!,
      );
      return DaySchedule(
        date: norm,
        type: ScheduledDayType.workout,
        workoutId: assignment.routineId,
        customWorkout: routine?.toWorkout(),
        isCompleted: false,
      );
    } else if (assignment.isRest) {
      return DaySchedule(date: norm, type: ScheduledDayType.rest);
    }

    // 3. PRIORITY 3: Unassigned (no scheduled routine or rest day)
    return DaySchedule(date: norm, type: ScheduledDayType.unassigned);
  }

  /// Retrieve the workout assigned to a given date (either custom, template, or rotation)
  Workout? getWorkoutForDate(DateTime date) {
    final schedule = getDaySchedule(date);
    if (schedule.type != ScheduledDayType.workout) {
      return null;
    }

    // Custom workout takes precedence
    if (schedule.customWorkout != null) {
      return schedule.customWorkout;
    }

    // Find routine in RoutineController
    if (schedule.workoutId != null) {
      final routine = RoutineController.instance.getRoutineById(
        schedule.workoutId!,
      );
      if (routine != null) {
        return routine.toWorkout();
      }
      if (_workouts.containsKey(schedule.workoutId)) {
        return _workouts[schedule.workoutId];
      }
    }

    return _workouts.values.isNotEmpty ? _workouts.values.first : null;
  }

  /// Modify/save workout assigned to a specific date
  Future<bool> updateWorkoutForDate(
    DateTime date,
    Workout updatedWorkout,
  ) async {
    final norm = DateTime(date.year, date.month, date.day);
    final key = DaySchedule.dateKey(norm);

    DaySchedule schedule = getDaySchedule(norm);
    schedule = schedule.copyWith(
      type: ScheduledDayType.workout,
      customWorkout: updatedWorkout,
      workoutId: updatedWorkout.id,
    );

    _schedules[key] = schedule;
    _workouts[updatedWorkout.id] = updatedWorkout;
    notifyListeners();

    try {
      await _storage.saveWorkout(updatedWorkout);
      final success = await _storage.saveDaySchedule(schedule);
      return success;
    } catch (e) {
      debugPrint('Failed to save updated workout: $e');
      return true; // Changes are safely retained in-memory
    }
  }

  /// Toggle or set workout completion status
  Future<bool> markWorkoutCompleted(
    DateTime date,
    bool isCompleted, {
    Workout? completedWorkout,
  }) async {
    final norm = DateTime(date.year, date.month, date.day);
    final key = DaySchedule.dateKey(norm);

    DaySchedule schedule = getDaySchedule(norm);
    schedule = schedule.copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
      customWorkout: completedWorkout ?? schedule.customWorkout,
    );

    _schedules[key] = schedule;
    notifyListeners();

    try {
      final success = await _storage.saveDaySchedule(schedule);
      if (isCompleted) {
        final workoutSnapshot =
            completedWorkout ??
            schedule.customWorkout ??
            getWorkoutForDate(norm);
        try {
          await WorkoutHistoryController.instance.recordCompletedSession(
            date: norm,
            routineId:
                schedule.workoutId ??
                workoutSnapshot?.id ??
                'workout_${norm.millisecondsSinceEpoch}',
            routineName: workoutSnapshot?.name ?? 'Completed Workout',
            targetMuscleGroups: workoutSnapshot?.targetMuscleGroups,
            workoutSnapshot: workoutSnapshot,
            completedAt: schedule.completedAt,
          );
        } catch (_) {}
        try {
          await DailyWorkoutController.instance.markCompletedForDate(
            norm,
            routineId: schedule.workoutId,
            completedAt: schedule.completedAt,
          );
        } catch (_) {}
      } else {
        try {
          final sessions = WorkoutHistoryController.instance.getSessionsForDate(
            norm,
          );
          for (final sess in sessions) {
            await WorkoutHistoryController.instance.deleteSession(sess.id);
          }
        } catch (_) {}
      }
      return success;
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
      customWorkout: type == ScheduledDayType.workout
          ? schedule.customWorkout
          : null,
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

  /// Assign a specific routine to a calendar date
  Future<bool> assignRoutineToDate(DateTime date, String routineId) async {
    final norm = DateTime(date.year, date.month, date.day);
    final key = DaySchedule.dateKey(norm);

    final routine = RoutineController.instance.getRoutineById(routineId);
    final existing = _schedules[key];
    final schedule = DaySchedule(
      date: norm,
      type: ScheduledDayType.workout,
      workoutId: routineId,
      customWorkout: routine?.toWorkout(),
      isCompleted: existing?.isCompleted ?? false,
      completedAt: existing?.completedAt,
    );

    _schedules[key] = schedule;
    notifyListeners();

    try {
      return await _storage.saveDaySchedule(schedule);
    } catch (e) {
      debugPrint('Failed to assign routine to date: $e');
      return false;
    }
  }

  /// Mark a calendar date as an explicit Rest Day
  Future<bool> setRestDayForDate(DateTime date) async {
    final norm = DateTime(date.year, date.month, date.day);
    final key = DaySchedule.dateKey(norm);

    final existing = _schedules[key];
    final schedule = DaySchedule(
      date: norm,
      type: ScheduledDayType.rest,
      workoutId: null,
      customWorkout: null,
      isCompleted: existing?.isCompleted ?? false,
      completedAt: existing?.completedAt,
    );

    _schedules[key] = schedule;
    notifyListeners();

    try {
      return await _storage.saveDaySchedule(schedule);
    } catch (e) {
      debugPrint('Failed to set rest day for date: $e');
      return false;
    }
  }

  /// Clear any assignment for a calendar date, reverting it to Unassigned
  Future<bool> clearDateAssignment(DateTime date) async {
    final norm = DateTime(date.year, date.month, date.day);
    final key = DaySchedule.dateKey(norm);

    final existing = _schedules[key];
    final schedule = DaySchedule(
      date: norm,
      type: ScheduledDayType.unassigned,
      workoutId: null,
      customWorkout: null,
      isCompleted: existing?.isCompleted ?? false,
      completedAt: existing?.completedAt,
    );

    _schedules[key] = schedule;
    notifyListeners();

    try {
      return await _storage.saveDaySchedule(schedule);
    } catch (e) {
      debugPrint('Failed to clear date assignment: $e');
      return false;
    }
  }

  /// Clean up any future or uncompleted scheduled references when a routine is deleted
  Future<void> handleRoutineDeleted(String deletedRoutineId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool modified = false;

    final updatedMap = Map<String, DaySchedule>.from(_schedules);
    for (final entry in updatedMap.entries) {
      final schedule = entry.value;
      final isFutureOrUncompletedToday =
          schedule.date.isAfter(today) ||
          (schedule.date == today && !schedule.isCompleted);

      if (isFutureOrUncompletedToday &&
          schedule.workoutId == deletedRoutineId) {
        _schedules[entry.key] = DaySchedule(
          date: schedule.date,
          type: ScheduledDayType.unassigned,
        );
        modified = true;
      }
    }

    for (final entry in _weeklyPlan.entries) {
      if (entry.value.routineId == deletedRoutineId) {
        _weeklyPlan[entry.key] = WeeklyDayAssignment(
          weekday: entry.key,
          type: ScheduledDayType.unassigned,
        );
        modified = true;
      }
    }

    if (modified) {
      notifyListeners();
      try {
        await _storage.saveAllSchedules(_schedules);
        await _storage.saveWeeklyPlan(_weeklyPlan);
      } catch (e) {
        debugPrint('Error saving schedules after routine deletion: $e');
      }
    }
  }

  /// Helper to get the schedule type for calendar indicators and panel
  ScheduledDayType getDateScheduleType(DateTime date) {
    final norm = DateTime(date.year, date.month, date.day);
    final key = DaySchedule.dateKey(norm);

    if (_schedules.containsKey(key)) {
      return _schedules[key]!.type;
    }

    // Check if recorded in DailyWorkoutController
    final daily = DailyWorkoutController.instance.getDailyWorkoutForDate(norm);
    if (daily != null) {
      if (daily.isRest) return ScheduledDayType.rest;
      if (daily.hasWorkout || daily.status == DailyWorkoutStatus.completed) {
        return ScheduledDayType.workout;
      }
    }

    return ScheduledDayType.unassigned;
  }
}
