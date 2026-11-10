import 'workout.dart';

/// Representation of a single logged set in an active workout session
class LoggedSetItem {
  final int setNumber;
  final num weight;
  final int reps;
  final double rpe;
  final bool completed;
  final String? prevSummary;

  const LoggedSetItem({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.completed,
    this.prevSummary,
  });

  LoggedSetItem copyWith({
    int? setNumber,
    num? weight,
    int? reps,
    double? rpe,
    bool? completed,
    String? prevSummary,
  }) {
    return LoggedSetItem(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      completed: completed ?? this.completed,
      prevSummary: prevSummary ?? this.prevSummary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'set': setNumber,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'completed': completed,
      if (prevSummary != null) 'prev': prevSummary,
    };
  }

  factory LoggedSetItem.fromJson(Map<String, dynamic> json) {
    return LoggedSetItem(
      setNumber: (json['set'] as num?)?.toInt() ?? 1,
      weight: (json['weight'] as num?) ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 10,
      rpe: (json['rpe'] as num?)?.toDouble() ?? 8.5,
      completed: json['completed'] as bool? ?? true,
      prevSummary: json['prev'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'set': setNumber,
      'prev': prevSummary ?? '${weight} kg × $reps',
      'weight':
          weight is int ? weight : (weight % 1 == 0 ? weight.toInt() : weight),
      'reps': reps,
      'rpe': rpe,
      'completed': completed,
    };
  }

  factory LoggedSetItem.fromMap(Map<String, dynamic> map) {
    return LoggedSetItem(
      setNumber: (map['set'] as num?)?.toInt() ?? 1,
      weight: (map['weight'] as num?) ?? 0,
      reps: (map['reps'] as num?)?.toInt() ?? 10,
      rpe: (map['rpe'] as num?)?.toDouble() ?? 8.5,
      completed: map['completed'] as bool? ?? true,
      prevSummary: map['prev'] as String?,
    );
  }
}

/// Lifecycle status of an active workout session
enum ActiveSessionStatus {
  inProgress,
  completed,
  discarded;

  String get value => toString().split('.').last;

  static ActiveSessionStatus fromString(String? val) {
    switch (val) {
      case 'completed':
        return ActiveSessionStatus.completed;
      case 'discarded':
        return ActiveSessionStatus.discarded;
      default:
        return ActiveSessionStatus.inProgress;
    }
  }
}

/// Persistent model representing a live, in-progress workout session
class ActiveWorkoutSession {
  final String sessionId;
  final String? workoutId;
  final String workoutTitle;
  final DateTime targetDate;
  final DateTime startTime;
  final DateTime lastUpdatedAt;
  final int secondsElapsed;
  final int currentExerciseIndex;
  final int currentWeight;
  final int currentReps;
  final double currentRpe;
  final List<WorkoutExercise> exercises;
  final Map<int, List<LoggedSetItem>> loggedSets;
  final ActiveSessionStatus status;

  const ActiveWorkoutSession({
    required this.sessionId,
    this.workoutId,
    required this.workoutTitle,
    required this.targetDate,
    required this.startTime,
    required this.lastUpdatedAt,
    required this.secondsElapsed,
    required this.currentExerciseIndex,
    required this.currentWeight,
    required this.currentReps,
    required this.currentRpe,
    required this.exercises,
    required this.loggedSets,
    this.status = ActiveSessionStatus.inProgress,
  });

  bool get isActive => status == ActiveSessionStatus.inProgress;

  int get totalCompletedSets {
    int count = 0;
    for (final sets in loggedSets.values) {
      count += sets.where((s) => s.completed).length;
    }
    return count;
  }

  int get totalLoggedSets {
    int count = 0;
    for (final sets in loggedSets.values) {
      count += sets.length;
    }
    return count;
  }

  ActiveWorkoutSession copyWith({
    String? sessionId,
    String? workoutId,
    String? workoutTitle,
    DateTime? targetDate,
    DateTime? startTime,
    DateTime? lastUpdatedAt,
    int? secondsElapsed,
    int? currentExerciseIndex,
    int? currentWeight,
    int? currentReps,
    double? currentRpe,
    List<WorkoutExercise>? exercises,
    Map<int, List<LoggedSetItem>>? loggedSets,
    ActiveSessionStatus? status,
  }) {
    return ActiveWorkoutSession(
      sessionId: sessionId ?? this.sessionId,
      workoutId: workoutId ?? this.workoutId,
      workoutTitle: workoutTitle ?? this.workoutTitle,
      targetDate: targetDate ?? this.targetDate,
      startTime: startTime ?? this.startTime,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      secondsElapsed: secondsElapsed ?? this.secondsElapsed,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentWeight: currentWeight ?? this.currentWeight,
      currentReps: currentReps ?? this.currentReps,
      currentRpe: currentRpe ?? this.currentRpe,
      exercises: exercises ?? this.exercises,
      loggedSets: loggedSets ?? this.loggedSets,
      status: status ?? this.status,
    );
  }

  Workout toWorkout() {
    return Workout(
      id: workoutId ?? 'workout_$sessionId',
      name: workoutTitle,
      targetMuscleGroups:
          exercises.map((e) => e.targetMuscle).toSet().join(' • '),
      estimatedDurationMinutes: (secondsElapsed / 60).ceil().clamp(1, 300),
      exercises: exercises,
    );
  }

  Map<int, List<Map<String, dynamic>>> toLoggedSetsMap() {
    return loggedSets.map(
      (key, list) =>
          MapEntry(key, list.map((item) => item.toMap()).toList()),
    );
  }

  static Map<int, List<LoggedSetItem>> fromLoggedSetsMap(
    Map<int, List<Map<String, dynamic>>> rawMap,
  ) {
    return rawMap.map(
      (key, list) =>
          MapEntry(key, list.map((item) => LoggedSetItem.fromMap(item)).toList()),
    );
  }

  Map<String, dynamic> toJson() {
    final setsJson = <String, dynamic>{};
    loggedSets.forEach((key, list) {
      setsJson[key.toString()] = list.map((e) => e.toJson()).toList();
    });

    return {
      'sessionId': sessionId,
      'workoutId': workoutId,
      'workoutTitle': workoutTitle,
      'targetDate': targetDate.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'secondsElapsed': secondsElapsed,
      'currentExerciseIndex': currentExerciseIndex,
      'currentWeight': currentWeight,
      'currentReps': currentReps,
      'currentRpe': currentRpe,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'loggedSets': setsJson,
      'status': status.value,
    };
  }

  factory ActiveWorkoutSession.fromJson(Map<String, dynamic> json) {
    final rawSets = json['loggedSets'] as Map<String, dynamic>? ?? {};
    final parsedSets = <int, List<LoggedSetItem>>{};

    rawSets.forEach((key, val) {
      final intIndex = int.tryParse(key);
      if (intIndex != null && val is List) {
        parsedSets[intIndex] =
            val
                .whereType<Map<String, dynamic>>()
                .map((e) => LoggedSetItem.fromJson(e))
                .toList();
      }
    });

    final rawExercises = json['exercises'] as List? ?? [];
    final parsedExercises =
        rawExercises
            .whereType<Map<String, dynamic>>()
            .map((e) => WorkoutExercise.fromJson(e))
            .toList();

    return ActiveWorkoutSession(
      sessionId:
          json['sessionId'] as String? ??
          'session_${DateTime.now().millisecondsSinceEpoch}',
      workoutId: json['workoutId'] as String?,
      workoutTitle: json['workoutTitle'] as String? ?? 'Workout Session',
      targetDate:
          json['targetDate'] != null
              ? DateTime.parse(json['targetDate'] as String)
              : DateTime.now(),
      startTime:
          json['startTime'] != null
              ? DateTime.parse(json['startTime'] as String)
              : DateTime.now(),
      lastUpdatedAt:
          json['lastUpdatedAt'] != null
              ? DateTime.parse(json['lastUpdatedAt'] as String)
              : DateTime.now(),
      secondsElapsed: (json['secondsElapsed'] as num?)?.toInt() ?? 0,
      currentExerciseIndex:
          (json['currentExerciseIndex'] as num?)?.toInt() ?? 0,
      currentWeight: (json['currentWeight'] as num?)?.toInt() ?? 34,
      currentReps: (json['currentReps'] as num?)?.toInt() ?? 10,
      currentRpe: (json['currentRpe'] as num?)?.toDouble() ?? 8.5,
      exercises: parsedExercises,
      loggedSets: parsedSets,
      status: ActiveSessionStatus.fromString(json['status'] as String?),
    );
  }
}

