import 'routine.dart';

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
  final String routineId;
  final DateTime completedAt;
  final String? routineName;

  const CompletedWorkoutSession({
    required this.routineId,
    required this.completedAt,
    this.routineName,
  });

  /// Local date key in standard YYYY-MM-DD format
  String get dateKey {
    return '${completedAt.year.toString().padLeft(4, '0')}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'routineId': routineId,
      'completedAt': completedAt.toIso8601String(),
      'routineName': routineName,
    };
  }

  factory CompletedWorkoutSession.fromJson(Map<String, dynamic> json) {
    return CompletedWorkoutSession(
      routineId: json['routineId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      routineName: json['routineName'] as String?,
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
  bool get isRotation => source == RecommendationSource.rotation || source == RecommendationSource.initial;
}

