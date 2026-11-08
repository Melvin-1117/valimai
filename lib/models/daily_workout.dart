/// Selection type for the daily workout decision
enum DailySelectionType {
  scheduled,
  suggested,
  manual,
  rest,
  skipped;

  String get displayName {
    switch (this) {
      case DailySelectionType.scheduled:
        return 'Scheduled for Today';
      case DailySelectionType.suggested:
        return 'Suggested Workout';
      case DailySelectionType.manual:
        return 'Manual Selection';
      case DailySelectionType.rest:
        return 'Rest Day';
      case DailySelectionType.skipped:
        return 'Skipped for Now';
    }
  }
}

/// Status of the daily workout
enum DailyWorkoutStatus {
  planned,
  inProgress,
  completed,
  rest,
  skipped;

  String get displayName {
    switch (this) {
      case DailyWorkoutStatus.planned:
        return 'Planned';
      case DailyWorkoutStatus.inProgress:
        return 'In Progress';
      case DailyWorkoutStatus.completed:
        return 'Completed';
      case DailyWorkoutStatus.rest:
        return 'Rest Day';
      case DailyWorkoutStatus.skipped:
        return 'Skipped';
    }
  }
}

/// A persistent record of the daily workout decision for a local calendar day
class DailyWorkout {
  final String id;
  final String localDate; // YYYY-MM-DD local calendar date (avoids timezone issues)
  final String? selectedRoutineId;
  final DailySelectionType selectionType;
  final DailyWorkoutStatus status;
  final DateTime selectedAt;
  final DateTime? completedAt;
  final String? routineName;
  final String? targetMuscleGroups;
  final int? exerciseCount;
  final int? totalSets;
  final int? estimatedDurationMinutes;

  const DailyWorkout({
    required this.id,
    required this.localDate,
    this.selectedRoutineId,
    required this.selectionType,
    required this.status,
    required this.selectedAt,
    this.completedAt,
    this.routineName,
    this.targetMuscleGroups,
    this.exerciseCount,
    this.totalSets,
    this.estimatedDurationMinutes,
  });

  /// Consistent local calendar date representation: YYYY-MM-DD
  static String formatLocalDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  bool get isRest => status == DailyWorkoutStatus.rest;
  bool get isSkipped => status == DailyWorkoutStatus.skipped;
  bool get hasWorkout => selectedRoutineId != null && !isRest && !isSkipped;

  DailyWorkout copyWith({
    String? id,
    String? localDate,
    String? selectedRoutineId,
    DailySelectionType? selectionType,
    DailyWorkoutStatus? status,
    DateTime? selectedAt,
    DateTime? completedAt,
    String? routineName,
    String? targetMuscleGroups,
    int? exerciseCount,
    int? totalSets,
    int? estimatedDurationMinutes,
  }) {
    return DailyWorkout(
      id: id ?? this.id,
      localDate: localDate ?? this.localDate,
      selectedRoutineId: selectedRoutineId ?? this.selectedRoutineId,
      selectionType: selectionType ?? this.selectionType,
      status: status ?? this.status,
      selectedAt: selectedAt ?? this.selectedAt,
      completedAt: completedAt ?? this.completedAt,
      routineName: routineName ?? this.routineName,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      exerciseCount: exerciseCount ?? this.exerciseCount,
      totalSets: totalSets ?? this.totalSets,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localDate': localDate,
      'selectedRoutineId': selectedRoutineId,
      'selectionType': selectionType.name,
      'status': status.name,
      'selectedAt': selectedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'routineName': routineName,
      'targetMuscleGroups': targetMuscleGroups,
      'exerciseCount': exerciseCount,
      'totalSets': totalSets,
      'estimatedDurationMinutes': estimatedDurationMinutes,
    };
  }

  factory DailyWorkout.fromJson(Map<String, dynamic> json) {
    return DailyWorkout(
      id: json['id'] as String? ?? 'dw_${DateTime.now().millisecondsSinceEpoch}',
      localDate: json['localDate'] as String? ??
          formatLocalDate(DateTime.now()),
      selectedRoutineId: json['selectedRoutineId'] as String?,
      selectionType: _parseSelectionType(json['selectionType'] as String?),
      status: _parseStatus(json['status'] as String?),
      selectedAt: json['selectedAt'] != null
          ? DateTime.tryParse(json['selectedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      routineName: json['routineName'] as String?,
      targetMuscleGroups: json['targetMuscleGroups'] as String?,
      exerciseCount: (json['exerciseCount'] as num?)?.toInt(),
      totalSets: (json['totalSets'] as num?)?.toInt(),
      estimatedDurationMinutes:
          (json['estimatedDurationMinutes'] as num?)?.toInt(),
    );
  }

  static DailySelectionType _parseSelectionType(String? val) {
    if (val == null) return DailySelectionType.suggested;
    return DailySelectionType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => DailySelectionType.suggested,
    );
  }

  static DailyWorkoutStatus _parseStatus(String? val) {
    if (val == null) return DailyWorkoutStatus.planned;
    return DailyWorkoutStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => DailyWorkoutStatus.planned,
    );
  }
}

