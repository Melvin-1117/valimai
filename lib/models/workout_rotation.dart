import 'routine.dart';
import 'workout.dart';

/// Source or justification for a workout recommendation
enum RecommendationSource {
  /// User has already made a selection (workout, rest, or skip) for today
  todaySelection,

  /// A specific routine is scheduled for today on the weekly calendar
  scheduled,

  /// Recommended next routine advancing from completed workout history
  rotation,

  /// Starting routine when no completed workout history exists
  initial,

  /// No active routines are configured
  none;

  String get displayName {
    switch (this) {
      case RecommendationSource.todaySelection:
        return 'Today\'s Selection';
      case RecommendationSource.scheduled:
        return 'Scheduled for Today';
      case RecommendationSource.rotation:
        return 'Suggested Workout';
      case RecommendationSource.initial:
        return 'Suggested Workout';
      case RecommendationSource.none:
        return 'No Active Routines';
    }
  }
}

/// A structured record of a completed workout session
class CompletedWorkoutSession {
  final String id;
  final String routineId;
  final DateTime completedAt;
  final String? routineName;
  final String? targetMuscleGroups;
  final int? totalSets;
  final int? exerciseCount;
  final int? totalReps;
  final double? totalVolumeKg;
  final Workout? workoutSnapshot;

  CompletedWorkoutSession({
    String? id,
    required this.routineId,
    required this.completedAt,
    this.routineName,
    this.targetMuscleGroups,
    this.totalSets,
    this.exerciseCount,
    this.totalReps,
    this.totalVolumeKg,
    this.workoutSnapshot,
  }) : id = id ?? 'sess_${completedAt.millisecondsSinceEpoch}_$routineId';

  /// Local date key in standard YYYY-MM-DD format
  String get dateKey {
    return '${completedAt.year.toString().padLeft(4, '0')}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')}';
  }

  /// Exercises performed count
  int get calculatedExercisesCount =>
      workoutSnapshot?.exerciseCount ?? exerciseCount ?? 0;

  /// Completed sets count
  int get calculatedTotalSets => workoutSnapshot?.totalSets ?? totalSets ?? 0;

  /// Total repetitions sum across all completed sets
  int get calculatedTotalReps {
    if (totalReps != null && totalReps! > 0) return totalReps!;
    if (workoutSnapshot != null) {
      return workoutSnapshot!.exercises.fold<int>(
        0,
        (sum, ex) =>
            sum +
            ex.effectiveSetConfigs.fold<int>(0, (sSum, s) => sSum + s.reps),
      );
    }
    return 0;
  }

  /// Total training volume in kg: Sum of (Actual Weight x Actual Reps)
  double get calculatedVolumeKg {
    if (totalVolumeKg != null && totalVolumeKg! > 0) return totalVolumeKg!;
    if (workoutSnapshot != null) {
      return workoutSnapshot!.exercises.fold<double>(
        0.0,
        (sum, ex) =>
            sum +
            ex.effectiveSetConfigs.fold<double>(
              0.0,
              (sSum, s) => sSum + (s.weightKg * s.reps),
            ),
      );
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineId': routineId,
      'completedAt': completedAt.toIso8601String(),
      'routineName': routineName,
      'targetMuscleGroups': targetMuscleGroups,
      'totalSets': calculatedTotalSets,
      'exerciseCount': calculatedExercisesCount,
      'totalReps': calculatedTotalReps,
      'totalVolumeKg': calculatedVolumeKg,
      'workoutSnapshot': workoutSnapshot?.toJson(),
    };
  }

  factory CompletedWorkoutSession.fromJson(Map<String, dynamic> json) {
    final completedAt = DateTime.parse(json['completedAt'] as String);
    final routineId = json['routineId'] as String;
    return CompletedWorkoutSession(
      id:
          json['id'] as String? ??
          'sess_${completedAt.millisecondsSinceEpoch}_$routineId',
      routineId: routineId,
      completedAt: completedAt,
      routineName: json['routineName'] as String?,
      targetMuscleGroups: json['targetMuscleGroups'] as String?,
      totalSets: (json['totalSets'] as num?)?.toInt(),
      exerciseCount: (json['exerciseCount'] as num?)?.toInt(),
      totalReps: (json['totalReps'] as num?)?.toInt(),
      totalVolumeKg: (json['totalVolumeKg'] as num?)?.toDouble(),
      workoutSnapshot: json['workoutSnapshot'] != null
          ? Workout.fromJson(json['workoutSnapshot'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// The result returned by the Workout Rotation Engine
class WorkoutRecommendation {
  final WorkoutRoutine? routine;
  final RecommendationSource source;
  final String reason;
  final bool isRestDay;
  final bool isSkipped;
  final bool isCompleted;
  final String? routineId;

  const WorkoutRecommendation({
    this.routine,
    required this.source,
    required this.reason,
    this.isRestDay = false,
    this.isSkipped = false,
    this.isCompleted = false,
    this.routineId,
  });

  bool get hasWorkout => routine != null && !isRestDay && !isSkipped;

  bool get isScheduled => source == RecommendationSource.scheduled;
  bool get isRotation =>
      source == RecommendationSource.rotation ||
      source == RecommendationSource.initial;
}
