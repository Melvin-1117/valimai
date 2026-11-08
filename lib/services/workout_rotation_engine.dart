import 'package:flutter/foundation.dart';
import '../models/daily_workout.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../models/workout_rotation.dart';
import 'daily_workout_controller.dart';
import 'routine_controller.dart';
import 'workout_controller.dart';
import 'workout_history_controller.dart';

/// Automatic workout recommendation engine for VALIMAI.
/// Determines the next routine based on completed workout history,
/// weekly schedules, and daily user selections.
class WorkoutRotationEngine {
  static WorkoutRotationEngine _instance = WorkoutRotationEngine._internal();
  static WorkoutRotationEngine get instance => _instance;

  @visibleForTesting
  static void setInstance(WorkoutRotationEngine customInstance) {
    _instance = customInstance;
  }

  WorkoutRotationEngine();
  WorkoutRotationEngine._internal();

  /// Pure deterministic recommendation algorithm.
  /// Given the current state, computes the recommendation for [targetDate].
  WorkoutRecommendation computeRecommendation({
    required DateTime targetDate,
    required List<WorkoutRoutine> activeRoutines,
    List<WorkoutRoutine> allRoutines = const [],
    List<CompletedWorkoutSession> completedHistory = const [],
    DailyWorkout? todayDecision,
    DaySchedule? todaySchedule,
  }) {
    // 1. RULE 1: If today's workout has already been selected, restore that selection.
    if (todayDecision != null) {
      if (todayDecision.isRest) {
        return const WorkoutRecommendation(
          source: RecommendationSource.todaySelection,
          isRestDay: true,
          reason: 'Rest Day selected for today',
        );
      }

      if (todayDecision.isSkipped) {
        return const WorkoutRecommendation(
          source: RecommendationSource.todaySelection,
          isSkipped: true,
          reason: 'Workout skipped for today',
        );
      }

      final isCompleted =
          todayDecision.status == DailyWorkoutStatus.completed;
      final routine = _resolveRoutine(
        todayDecision.selectedRoutineId,
        activeRoutines,
        allRoutines,
      );

      return WorkoutRecommendation(
        routine: routine,
        routineId: todayDecision.selectedRoutineId,
        source: RecommendationSource.todaySelection,
        isCompleted: isCompleted,
        reason: isCompleted
            ? 'Workout completed for today'
            : 'Today\'s workout already selected',
      );
    }

    // Also check if todaySchedule was directly completed
    if (todaySchedule != null && todaySchedule.isCompleted) {
      final routine = _resolveRoutine(
        todaySchedule.workoutId,
        activeRoutines,
        allRoutines,
      );
      return WorkoutRecommendation(
        routine: routine,
        routineId: todaySchedule.workoutId,
        source: RecommendationSource.todaySelection,
        isCompleted: true,
        reason: 'Workout completed for today',
      );
    }

    // 2. RULE 2: If a routine is scheduled for today, present it as the scheduled workout.
    if (todaySchedule != null &&
        todaySchedule.type == ScheduledDayType.workout &&
        todaySchedule.workoutId != null) {
      final scheduled = activeRoutines.cast<WorkoutRoutine?>().firstWhere(
            (r) => r?.id == todaySchedule.workoutId,
            orElse: () => null,
          );
      if (scheduled != null) {
        return WorkoutRecommendation(
          routine: scheduled,
          routineId: scheduled.id,
          source: RecommendationSource.scheduled,
          reason: 'Scheduled for Today',
        );
      }
    }

    // 3. RULES 3, 4, 5: If no routine is scheduled, suggest the next routine in the rotation.
    if (activeRoutines.isEmpty) {
      return const WorkoutRecommendation(
        source: RecommendationSource.none,
        reason: 'No active routines available',
      );
    }

    final isInitial = completedHistory.isEmpty;
    final nextRoutine = computeNextRoutineInRotation(
      activeRoutines: activeRoutines,
      allRoutines: allRoutines,
      completedHistory: completedHistory,
    );

    return WorkoutRecommendation(
      routine: nextRoutine,
      routineId: nextRoutine?.id,
      source: isInitial
          ? RecommendationSource.initial
          : RecommendationSource.rotation,
      reason: isInitial
          ? 'Initial rotation workout'
          : 'Suggested Workout // Rotation',
    );
  }

  /// Pure deterministic routine suggestion based strictly on completed workout history.
  /// Ignores uncompleted selections, rest days, and skipped days.
  WorkoutRoutine? computeNextRoutineInRotation({
    required List<WorkoutRoutine> activeRoutines,
    List<WorkoutRoutine> allRoutines = const [],
    required List<CompletedWorkoutSession> completedHistory,
  }) {
    if (activeRoutines.isEmpty) return null;

    // RULE 4: If no completed workout exists, suggest the first active routine.
    if (completedHistory.isEmpty) {
      return activeRoutines.first;
    }

    // Sort completed sessions descending: most recent completion first.
    final sortedHistory = List<CompletedWorkoutSession>.from(completedHistory)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    // Iterate through completed sessions to find the most recent valid reference.
    for (final session in sortedHistory) {
      // Case A: The routine exists in the current active routines.
      final activeIndex =
          activeRoutines.indexWhere((r) => r.id == session.routineId);
      if (activeIndex >= 0) {
        // RULE 5: After a completed workout, advance to the next active routine.
        final nextIndex = (activeIndex + 1) % activeRoutines.length;
        return activeRoutines[nextIndex];
      }

      // Case B: The routine is inactive, but still in the routine repository.
      final allIndex =
          allRoutines.indexWhere((r) => r.id == session.routineId);
      if (allIndex >= 0) {
        final completedOrder = allRoutines[allIndex].rotationOrder;
        // Find the first active routine with a rotationOrder higher than the inactive one
        final subsequent = activeRoutines
            .where((r) => r.rotationOrder > completedOrder)
            .toList();
        if (subsequent.isNotEmpty) {
          return subsequent.first;
        }
        // If wrapped around, start at first active routine
        return activeRoutines.first;
      }

      // Case C: The routine was permanently deleted from the repository.
      // Continue checking earlier completed sessions in the history.
    }

    // If none of the completed sessions match any active or known routine,
    // fallback safely to the first active routine.
    return activeRoutines.first;
  }

  /// Collects completed workout sessions across both DailyWorkout records and DaySchedule entries.
  /// Deduplicates sessions by (routineId + dateKey) and sorts newest first.
  List<CompletedWorkoutSession> getCompletedHistory() {
    final Map<String, CompletedWorkoutSession> sessionMap = {};

    // 0. Extract from WorkoutHistoryController if initialized
    try {
      if (WorkoutHistoryController.instance.isInitialized) {
        for (final sess in WorkoutHistoryController.instance.allSessions) {
          final dateKey = DaySchedule.dateKey(sess.completedAt);
          final key = '${sess.routineId}_$dateKey';
          sessionMap[key] = sess;
        }
      }
    } catch (_) {}

    // 1. Extract from DailyWorkoutController records
    try {
      final dailyRecords = DailyWorkoutController.instance.allRecords;
      for (final record in dailyRecords.values) {
        if (record.status == DailyWorkoutStatus.completed &&
            record.selectedRoutineId != null) {
          final completedAt = record.completedAt ?? record.selectedAt;
          final key = '${record.selectedRoutineId}_${record.localDate}';
          sessionMap[key] = CompletedWorkoutSession(
            routineId: record.selectedRoutineId!,
            completedAt: completedAt,
            routineName: record.routineName,
          );
        }
      }
    } catch (_) {
      // Controller may not be initialized in isolated tests
    }

    // 2. Extract from WorkoutController schedules
    try {
      final schedules = WorkoutController.instance.schedules;
      for (final schedule in schedules.values) {
        if (schedule.isCompleted && schedule.workoutId != null) {
          final dateKey = DaySchedule.dateKey(schedule.date);
          final key = '${schedule.workoutId}_$dateKey';
          final completedAt = schedule.completedAt ??
              DateTime(schedule.date.year, schedule.date.month, schedule.date.day, 12, 0);

          // Only add if not already captured or if newer
          if (!sessionMap.containsKey(key) ||
              completedAt.isAfter(sessionMap[key]!.completedAt)) {
            sessionMap[key] = CompletedWorkoutSession(
              routineId: schedule.workoutId!,
              completedAt: completedAt,
              routineName: schedule.customWorkout?.name,
            );
          }
        }
      }
    } catch (_) {
      // Controller may not be initialized in isolated tests
    }

    final list = sessionMap.values.toList();
    list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return list;
  }

  /// Live application recommendation for [date].
  WorkoutRecommendation getRecommendationForDate(DateTime date) {
    final activeRoutines = RoutineController.instance.activeRoutines;
    final allRoutines = RoutineController.instance.allRoutines;
    final completedHistory = getCompletedHistory();
    final todayDecision =
        DailyWorkoutController.instance.getDailyWorkoutForDate(date);
    final todaySchedule = WorkoutController.instance.getDaySchedule(date);

    return computeRecommendation(
      targetDate: date,
      activeRoutines: activeRoutines,
      allRoutines: allRoutines,
      completedHistory: completedHistory,
      todayDecision: todayDecision,
      todaySchedule: todaySchedule,
    );
  }

  /// Live application rotation suggestion for [date].
  /// Returns either the scheduled routine (if scheduled) or next rotation routine.
  WorkoutRoutine? getSuggestedRoutineForRotation(DateTime date) {
    final activeRoutines = RoutineController.instance.activeRoutines;
    if (activeRoutines.isEmpty) return null;

    // Check calendar schedule
    final schedule = WorkoutController.instance.getDaySchedule(date);
    if (schedule.type == ScheduledDayType.workout && schedule.workoutId != null) {
      final scheduled = activeRoutines.cast<WorkoutRoutine?>().firstWhere(
            (r) => r?.id == schedule.workoutId,
            orElse: () => null,
          );
      if (scheduled != null) {
        return scheduled;
      }
    }

    // Rotation from completed history
    final allRoutines = RoutineController.instance.allRoutines;
    final completedHistory = getCompletedHistory();

    return computeNextRoutineInRotation(
      activeRoutines: activeRoutines,
      allRoutines: allRoutines,
      completedHistory: completedHistory,
    );
  }

  /// Checks if [routine] is scheduled for [date] on the calendar
  bool isScheduledForDate(DateTime date, WorkoutRoutine routine) {
    final schedule = WorkoutController.instance.getDaySchedule(date);
    return schedule.type == ScheduledDayType.workout &&
        schedule.workoutId == routine.id;
  }

  WorkoutRoutine? _resolveRoutine(
    String? id,
    List<WorkoutRoutine> active,
    List<WorkoutRoutine> all,
  ) {
    if (id == null) return null;
    try {
      return active.firstWhere(
        (r) => r.id == id,
        orElse: () => all.firstWhere((r) => r.id == id),
      );
    } catch (_) {
      return null;
    }
  }
}

