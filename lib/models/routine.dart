import 'workout.dart';

/// An exercise configured specifically within a workout routine
class RoutineExercise {
  final String id;
  final String routineId;
  final String exerciseId;
  final String name;
  final String targetMuscle;
  final int exerciseOrder;
  final List<ExerciseSetConfig> setsConfiguration;
  final String? equipment;
  final List<String> secondaryMuscles;
  final String? notes;

  const RoutineExercise({
    required this.id,
    required this.routineId,
    required this.exerciseId,
    required this.name,
    required this.targetMuscle,
    required this.exerciseOrder,
    this.setsConfiguration = const [],
    this.equipment,
    this.secondaryMuscles = const [],
    this.notes,
  });

  /// Guaranteed list of at least 1 set config
  List<ExerciseSetConfig> get effectiveSets {
    if (setsConfiguration.isNotEmpty) {
      return setsConfiguration;
    }
    return const [
      ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 20.0),
      ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 20.0),
      ExerciseSetConfig(setNumber: 3, reps: 10, weightKg: 20.0),
    ];
  }

  int get setsCount =>
      setsConfiguration.isNotEmpty ? setsConfiguration.length : 3;

  RoutineExercise copyWith({
    String? id,
    String? routineId,
    String? exerciseId,
    String? name,
    String? targetMuscle,
    int? exerciseOrder,
    List<ExerciseSetConfig>? setsConfiguration,
    String? equipment,
    List<String>? secondaryMuscles,
    String? notes,
  }) {
    return RoutineExercise(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      exerciseOrder: exerciseOrder ?? this.exerciseOrder,
      setsConfiguration: setsConfiguration ?? this.setsConfiguration,
      equipment: equipment ?? this.equipment,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to WorkoutExercise for reuse in existing WorkoutEditor
  WorkoutExercise toWorkoutExercise() {
    return WorkoutExercise(
      id: id,
      exerciseId: exerciseId,
      name: name,
      targetMuscle: targetMuscle,
      setConfigs: effectiveSets,
      sets: effectiveSets.length,
      reps: effectiveSets.first.reps,
      weightKg: effectiveSets.first.weightKg,
      order: exerciseOrder,
      equipment: equipment,
      secondaryMuscles: secondaryMuscles,
    );
  }

  /// Construct RoutineExercise from existing WorkoutExercise
  factory RoutineExercise.fromWorkoutExercise(
    String routineId,
    WorkoutExercise ex, {
    int? order,
  }) {
    return RoutineExercise(
      id: ex.id,
      routineId: routineId,
      exerciseId: ex.exerciseId ?? ex.id,
      name: ex.name,
      targetMuscle: ex.targetMuscle,
      exerciseOrder: order ?? ex.order,
      setsConfiguration: ex.effectiveSetConfigs,
      equipment: ex.equipment,
      secondaryMuscles: ex.secondaryMuscles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineId': routineId,
      'exerciseId': exerciseId,
      'name': name,
      'targetMuscle': targetMuscle,
      'exerciseOrder': exerciseOrder,
      'setsConfiguration': effectiveSets.map((s) => s.toJson()).toList(),
      'equipment': equipment,
      'secondaryMuscles': secondaryMuscles,
      'notes': notes,
    };
  }

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    final setsList =
        (json['setsConfiguration'] as List<dynamic>?)
            ?.map((e) => ExerciseSetConfig.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <ExerciseSetConfig>[];

    final secondaries =
        (json['secondaryMuscles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    return RoutineExercise(
      id:
          json['id'] as String? ??
          're_${DateTime.now().millisecondsSinceEpoch}',
      routineId: json['routineId'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? '',
      name: json['name'] as String? ?? 'Exercise',
      targetMuscle: json['targetMuscle'] as String? ?? 'General',
      exerciseOrder: (json['exerciseOrder'] as num?)?.toInt() ?? 0,
      setsConfiguration: setsList,
      equipment: json['equipment'] as String?,
      secondaryMuscles: secondaries,
      notes: json['notes'] as String?,
    );
  }
}

/// A reusable, customizable workout routine
class WorkoutRoutine {
  final String id;
  final String name;
  final String description;
  final List<String> targetMuscleGroups;
  final int rotationOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RoutineExercise> exercises;

  const WorkoutRoutine({
    required this.id,
    required this.name,
    this.description = '',
    this.targetMuscleGroups = const [],
    required this.rotationOrder,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.exercises = const [],
  });

  /// Total number of working sets across all exercises
  int get totalSets => exercises.fold<int>(0, (sum, ex) => sum + ex.setsCount);

  /// Total number of exercises
  int get totalExercises => exercises.length;

  /// Estimate workout duration in minutes based on total sets
  int get estimatedDurationMinutes {
    if (exercises.isEmpty) return 30;
    // Standard gym pacing estimate: ~2.5 mins per working set + 5 mins warm-up
    int totalWorkingSets = totalSets;
    final calculated = (totalWorkingSets * 2.5).round() + 5;
    return calculated < 15 ? 15 : calculated;
  }

  WorkoutRoutine copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? targetMuscleGroups,
    int? rotationOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RoutineExercise>? exercises,
  }) {
    return WorkoutRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      rotationOrder: rotationOrder ?? this.rotationOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? this.exercises,
    );
  }

  /// Convert to Workout model so it can be edited by WorkoutEditorScreen
  Workout toWorkout() {
    return Workout(
      id: id,
      name: name,
      targetMuscleGroups: targetMuscleGroups.join(', '),
      estimatedDurationMinutes: estimatedDurationMinutes,
      exercises: exercises.map((e) => e.toWorkoutExercise()).toList(),
    );
  }

  /// Create or update WorkoutRoutine from a Workout edited in WorkoutEditorScreen
  WorkoutRoutine updateFromWorkout(Workout workout) {
    final now = DateTime.now();
    final muscles = workout.targetMuscleGroups
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final updatedExercises = workout.exercises.asMap().entries.map((entry) {
      return RoutineExercise.fromWorkoutExercise(
        id,
        entry.value,
        order: entry.key,
      );
    }).toList();

    return copyWith(
      name: workout.name,
      targetMuscleGroups: muscles.isNotEmpty ? muscles : targetMuscleGroups,
      updatedAt: now,
      exercises: updatedExercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetMuscleGroups': targetMuscleGroups,
      'rotationOrder': rotationOrder,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    final exerciseList =
        (json['exercises'] as List<dynamic>?)
            ?.map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <RoutineExercise>[];

    final muscles =
        (json['targetMuscleGroups'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    return WorkoutRoutine(
      id:
          json['id'] as String? ??
          'routine_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Workout Routine',
      description: json['description'] as String? ?? '',
      targetMuscleGroups: muscles,
      rotationOrder: (json['rotationOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      exercises: exerciseList,
    );
  }
}
