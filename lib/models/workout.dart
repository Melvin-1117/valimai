import 'dart:convert';

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

/// An individual exercise within a workout
class WorkoutExercise {
  final String id;
  final String name;
  final String targetMuscle;
  final int sets;
  final int reps;
  final double weightKg;
  final int restSeconds;
  final int order;

  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.restSeconds,
    this.order = 0,
  });

  WorkoutExercise copyWith({
    String? id,
    String? name,
    String? targetMuscle,
    int? sets,
    int? reps,
    double? weightKg,
    int? restSeconds,
    int? order,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds ?? this.restSeconds,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetMuscle': targetMuscle,
      'sets': sets,
      'reps': reps,
      'weightKg': weightKg,
      'restSeconds': restSeconds,
      'order': order,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'] as String? ?? 'ex_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Exercise',
      targetMuscle: json['targetMuscle'] as String? ?? 'General',
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      reps: (json['reps'] as num?)?.toInt() ?? 10,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 20.0,
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 90,
      order: (json['order'] as num?)?.toInt() ?? 0,
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
  int get totalSets => exercises.fold(0, (sum, ex) => sum + ex.sets);

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
      id: json['id'] as String? ?? 'workout_${DateTime.now().millisecondsSinceEpoch}',
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
      customWorkout:
          customJson != null ? Workout.fromJson(customJson) : null,
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

