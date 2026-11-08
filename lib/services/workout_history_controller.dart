import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/daily_workout.dart';
import '../models/workout.dart';
import '../models/workout_rotation.dart';
import 'daily_workout_controller.dart';
import 'storage_helper.dart';
import 'workout_controller.dart';

/// Centralized state controller for completed workout sessions and historical analytics.
class WorkoutHistoryController extends ChangeNotifier {
  static final WorkoutHistoryController instance =
      WorkoutHistoryController._internal();

  WorkoutHistoryController._internal();

  static const String _fileName = 'valimai_history.json';

  final List<CompletedWorkoutSession> _sessions = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// All completed workout sessions, sorted newest first
  List<CompletedWorkoutSession> get allSessions =>
      List<CompletedWorkoutSession>.unmodifiable(_sessions);

  /// Total count of completed workout sessions
  int get totalCompletedCount => _sessions.length;

  /// Initialize controller and load saved history
  Future<void> initialize() async {
    if (_isInitialized) return;

    _sessions.clear();

    try {
      final content = await StorageHelper.safeReadString(_fileName);
      if (content != null && content.trim().isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(content);
        for (final item in jsonList) {
          try {
            _sessions.add(
                CompletedWorkoutSession.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            debugPrint('Failed to parse completed session: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading history storage: $e');
    }

    // Discover completed sessions from WorkoutController schedules
    bool hasNewDiscovered = false;
    try {
      final schedules = WorkoutController.instance.schedules;
      for (final schedule in schedules.values) {
        if (schedule.isCompleted && schedule.workoutId != null) {
          final dateKey = DaySchedule.dateKey(schedule.date);
          final alreadyCaptured = _sessions.any((s) =>
              s.routineId == schedule.workoutId && s.dateKey == dateKey);

          if (!alreadyCaptured) {
            final completedAt = schedule.completedAt ??
                DateTime(schedule.date.year, schedule.date.month,
                    schedule.date.day, 12, 0);
            final snapshot = schedule.customWorkout ??
                WorkoutController.instance.getWorkoutForDate(schedule.date);

            _sessions.add(
              CompletedWorkoutSession(
                routineId: schedule.workoutId!,
                completedAt: completedAt,
                routineName: snapshot?.name ?? schedule.workoutId,
                targetMuscleGroups: snapshot?.targetMuscleGroups,
                workoutSnapshot: snapshot,
              ),
            );
            hasNewDiscovered = true;
          }
        }
      }
    } catch (_) {}

    // Discover completed sessions from DailyWorkoutController
    try {
      final dailyRecords = DailyWorkoutController.instance.allRecords;
      for (final record in dailyRecords.values) {
        if (record.status == DailyWorkoutStatus.completed &&
            record.selectedRoutineId != null) {
          final alreadyCaptured = _sessions.any((s) =>
              s.routineId == record.selectedRoutineId &&
              s.dateKey == record.localDate);

          if (!alreadyCaptured) {
            final completedAt = record.completedAt ?? record.selectedAt;
            final date = DateTime.tryParse(record.localDate) ?? completedAt;
            final snapshot =
                WorkoutController.instance.getWorkoutForDate(date);

            _sessions.add(
              CompletedWorkoutSession(
                routineId: record.selectedRoutineId!,
                completedAt: completedAt,
                routineName: record.routineName ?? snapshot?.name,
                targetMuscleGroups:
                    record.targetMuscleGroups ?? snapshot?.targetMuscleGroups,
                totalSets: record.totalSets,
                exerciseCount: record.exerciseCount,
                workoutSnapshot: snapshot,
              ),
            );
            hasNewDiscovered = true;
          }
        }
      }
    } catch (_) {}

    // Sort newest first
    _sessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    _isInitialized = true;
    notifyListeners();

    if (hasNewDiscovered) {
      await _saveSessions();
    }
  }

  /// Record a newly completed workout session
  Future<bool> recordCompletedSession({
    required DateTime date,
    required String routineId,
    required String routineName,
    String? targetMuscleGroups,
    Workout? workoutSnapshot,
    DateTime? completedAt,
  }) async {
    final effectiveCompletedAt = completedAt ?? DateTime.now();

    final session = CompletedWorkoutSession(
      routineId: routineId,
      completedAt: effectiveCompletedAt,
      routineName: routineName,
      targetMuscleGroups: targetMuscleGroups ?? workoutSnapshot?.targetMuscleGroups,
      workoutSnapshot: workoutSnapshot,
    );

    // Replace any previous session on the same date for this routine with the actual performed snapshot
    _sessions.removeWhere((s) =>
        s.completedAt.year == effectiveCompletedAt.year &&
        s.completedAt.month == effectiveCompletedAt.month &&
        s.completedAt.day == effectiveCompletedAt.day &&
        (s.routineId == routineId || s.routineName == routineName));

    // Insert at beginning and sort
    _sessions.insert(0, session);
    _sessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    notifyListeners();

    return await _saveSessions();
  }

  /// Get completed sessions on a specific calendar date (supports multiple sessions)
  List<CompletedWorkoutSession> getSessionsForDate(DateTime date) {
    return _sessions.where((s) {
      return s.completedAt.year == date.year &&
          s.completedAt.month == date.month &&
          s.completedAt.day == date.day;
    }).toList();
  }

  /// Check whether any workout session was completed on the given date
  bool hasCompletedWorkoutOnDate(DateTime date) {
    // Cannot have completed workouts in the future
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target.isAfter(today)) return false;

    return getSessionsForDate(date).isNotEmpty;
  }

  /// Check if the date was recorded as a Rest Day
  bool isRestDayOnDate(DateTime date) {
    try {
      final dailyRecord =
          DailyWorkoutController.instance.getDailyWorkoutForDate(date);
      if (dailyRecord != null && dailyRecord.isRest) return true;

      final schedule = WorkoutController.instance.getDaySchedule(date);
      return schedule.type == ScheduledDayType.rest;
    } catch (_) {
      return false;
    }
  }

  /// Check if the date was recorded as Skipped
  bool isSkippedOnDate(DateTime date) {
    try {
      final dailyRecord =
          DailyWorkoutController.instance.getDailyWorkoutForDate(date);
      return dailyRecord != null && dailyRecord.isSkipped;
    } catch (_) {
      return false;
    }
  }

  /// Find session by ID
  CompletedWorkoutSession? getSessionById(String id) {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Delete a session (safe maintenance)
  Future<bool> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    notifyListeners();
    return await _saveSessions();
  }

  Future<bool> _saveSessions() async {
    try {
      final jsonList = _sessions.map((s) => s.toJson()).toList();
      return await StorageHelper.safeWriteString(_fileName, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to persist history sessions: $e');
      return true; // Preserved in-memory
    }
  }
}

