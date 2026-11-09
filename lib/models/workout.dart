/// Type of day in the workout schedule
enum ScheduledDayType {
  workout,
  rest,
  unassigned;

  String get displayName {
    switch (this) {
      case ScheduledDayType.workout:
        return 'Workout';
      case ScheduledDayType.rest:
        return 'Rest Day';
      case ScheduledDayType.unassigned:
        return 'Unassigned';
    }
  }
}

/// An individual set configuration with independent reps and weight
class ExerciseSetConfig {
  final int setNumber;
  final int reps;
  final double weightKg;

  const ExerciseSetConfig({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
  });

  ExerciseSetConfig copyWith({int? setNumber, int? reps, double? weightKg}) {
    return ExerciseSetConfig(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  Map<String, dynamic> toJson() {
    return {'setNumber': setNumber, 'reps': reps, 'weightKg': weightKg};
  }

  factory ExerciseSetConfig.fromJson(Map<String, dynamic> json) {
    return ExerciseSetConfig(
      setNumber: (json['setNumber'] as num?)?.toInt() ?? 1,
      reps: (json['reps'] as num?)?.toInt() ?? 10,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 20.0,
    );
  }
}

/// An individual exercise within a workout with configurable sets
class WorkoutExercise {
  final String id;
  final String? exerciseId;
  final String name;
  final String targetMuscle;
  final List<ExerciseSetConfig> setConfigs;
  final int sets;
  final int reps;
  final double weightKg;
  final int order;
  final String? equipment;
  final List<String> secondaryMuscles;

  const WorkoutExercise({
    required this.id,
    this.exerciseId,
    required this.name,
    required this.targetMuscle,
    this.setConfigs = const [],
    this.sets = 3,
    this.reps = 10,
    this.weightKg = 20.0,
    this.order = 0,
    this.equipment,
    this.secondaryMuscles = const [],
  });

  /// Effective list of sets (guarantees at least 1 set and per-set configurations)
  List<ExerciseSetConfig> get effectiveSetConfigs {
    if (setConfigs.isNotEmpty) {
      return setConfigs;
    }
    final count = sets > 0 ? sets : 1;
    return List.generate(
      count,
      (i) =>
          ExerciseSetConfig(setNumber: i + 1, reps: reps, weightKg: weightKg),
    );
  }

  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    String? name,
    String? targetMuscle,
    List<ExerciseSetConfig>? setConfigs,
    int? sets,
    int? reps,
    double? weightKg,
    int? order,
    String? equipment,
    List<String>? secondaryMuscles,
  }) {
    final effectiveSets = setConfigs ?? this.setConfigs;
    final int resolvedSets =
        sets ?? (effectiveSets.isNotEmpty ? effectiveSets.length : this.sets);
    final int resolvedReps =
        reps ??
        (effectiveSets.isNotEmpty ? effectiveSets.first.reps : this.reps);
    final double resolvedWeight =
        weightKg ??
        (effectiveSets.isNotEmpty
            ? effectiveSets.first.weightKg
            : this.weightKg);

    return WorkoutExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      setConfigs: effectiveSets,
      sets: resolvedSets,
      reps: resolvedReps,
      weightKg: resolvedWeight,
      order: order ?? this.order,
      equipment: equipment ?? this.equipment,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
    );
  }

  Map<String, dynamic> toJson() {
    final activeSets = effectiveSetConfigs;
    return {
      'id': id,
      'exerciseId': exerciseId,
      'name': name,
      'targetMuscle': targetMuscle,
      'sets': activeSets.length,
      'reps': activeSets.isNotEmpty ? activeSets.first.reps : reps,
      'weightKg': activeSets.isNotEmpty ? activeSets.first.weightKg : weightKg,
      'order': order,
      'equipment': equipment,
      'secondaryMuscles': secondaryMuscles,
      'setConfigs': activeSets.map((s) => s.toJson()).toList(),
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    final setsList =
        (json['setConfigs'] as List<dynamic>?)
            ?.map((e) => ExerciseSetConfig.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <ExerciseSetConfig>[];

    final secondaries =
        (json['secondaryMuscles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    final legacySets = (json['sets'] as num?)?.toInt() ?? 3;
    final legacyReps = (json['reps'] as num?)?.toInt() ?? 10;
    final legacyWeight = (json['weightKg'] as num?)?.toDouble() ?? 20.0;

    return WorkoutExercise(
      id:
          json['id'] as String? ??
          'ex_${DateTime.now().millisecondsSinceEpoch}',
      exerciseId: json['exerciseId'] as String?,
      name: json['name'] as String? ?? 'Exercise',
      targetMuscle: json['targetMuscle'] as String? ?? 'General',
      setConfigs: setsList.isNotEmpty ? setsList : const [],
      sets: legacySets,
      reps: legacyReps,
      weightKg: legacyWeight,
      order: (json['order'] as num?)?.toInt() ?? 0,
      equipment: json['equipment'] as String?,
      secondaryMuscles: secondaries,
    );
  }
}

/// A structured workout routine
class Workout {
  final String id;
  final String name;
  final String targetMuscleGroups;
  final int estimatedDurationMinutes;
  final List<WorkoutExercise> exercises;

  const Workout({
    required this.id,
    required this.name,
    required this.targetMuscleGroups,
    required this.estimatedDurationMinutes,
    required this.exercises,
  });

  /// Total number of planned sets across all exercises
  int get totalSets =>
      exercises.fold(0, (sum, ex) => sum + ex.effectiveSetConfigs.length);

  /// Total number of exercises
  int get exerciseCount => exercises.length;

  Workout copyWith({
    String? id,
    String? name,
    String? targetMuscleGroups,
    int? estimatedDurationMinutes,
    List<WorkoutExercise>? exercises,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetMuscleGroups': targetMuscleGroups,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    final list = json['exercises'] as List<dynamic>? ?? [];
    return Workout(
      id:
          json['id'] as String? ??
          'workout_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Workout',
      targetMuscleGroups: json['targetMuscleGroups'] as String? ?? 'Full Body',
      estimatedDurationMinutes:
          (json['estimatedDurationMinutes'] as num?)?.toInt() ?? 45,
      exercises: list
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Schedule configuration for an individual day
class DaySchedule {
  final DateTime date;
  final ScheduledDayType type;
  final String? workoutId;
  final Workout? customWorkout;
  final bool isCompleted;
  final DateTime? completedAt;

  const DaySchedule({
    required this.date,
    required this.type,
    this.workoutId,
    this.customWorkout,
    this.isCompleted = false,
    this.completedAt,
  });

  DaySchedule copyWith({
    DateTime? date,
    ScheduledDayType? type,
    String? workoutId,
    Workout? customWorkout,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return DaySchedule(
      date: date ?? this.date,
      type: type ?? this.type,
      workoutId: workoutId ?? this.workoutId,
      customWorkout: customWorkout ?? this.customWorkout,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'type': type.name,
      'workoutId': workoutId,
      'customWorkout': customWorkout?.toJson(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String;
    final date = DateTime.parse(dateStr);
    final typeName = json['type'] as String? ?? 'workout';
    final type = ScheduledDayType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => ScheduledDayType.workout,
    );
    final customJson = json['customWorkout'] as Map<String, dynamic>?;

    return DaySchedule(
      date: DateTime(date.year, date.month, date.day),
      type: type,
      workoutId: json['workoutId'] as String?,
      customWorkout: customJson != null ? Workout.fromJson(customJson) : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  /// Helper to generate a standardized date key (yyyy-MM-dd)
  static String dateKey(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
