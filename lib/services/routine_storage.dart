import 'dart:convert';
import '../models/routine.dart';
import '../models/workout.dart';
import 'storage_helper.dart';

abstract class IRoutineStorage {
  Future<List<WorkoutRoutine>> loadRoutines();
  Future<bool> saveRoutine(WorkoutRoutine routine);
  Future<bool> deleteRoutine(String routineId);
  Future<bool> saveAllRoutines(List<WorkoutRoutine> routines);
}

class LocalRoutineStorage implements IRoutineStorage {
  static const String _fileName = 'valimai_routines.json';
  List<WorkoutRoutine>? _cachedRoutines;

  @override
  Future<List<WorkoutRoutine>> loadRoutines() async {
    if (_cachedRoutines != null) {
      return List<WorkoutRoutine>.from(_cachedRoutines!);
    }

    try {
      final content = await StorageHelper.safeReadString(_fileName);
      if (content != null && content.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(content);
        final loaded = jsonList
            .map((item) =>
                WorkoutRoutine.fromJson(item as Map<String, dynamic>))
            .toList();

        // Sort by rotationOrder
        loaded.sort((a, b) => a.rotationOrder.compareTo(b.rotationOrder));
        _cachedRoutines = loaded;
        return List<WorkoutRoutine>.from(loaded);
      }
    } catch (_) {}

    // First time launch: seed default canonical routines
    final defaults = _buildDefaultRoutines();
    _cachedRoutines = defaults;
    try {
      await saveAllRoutines(defaults);
    } catch (_) {}

    return List<WorkoutRoutine>.from(defaults);
  }

  @override
  Future<bool> saveRoutine(WorkoutRoutine routine) async {
    _cachedRoutines ??= await loadRoutines();
    final index = _cachedRoutines!.indexWhere((r) => r.id == routine.id);
    if (index >= 0) {
      _cachedRoutines![index] = routine;
    } else {
      _cachedRoutines!.add(routine);
    }

    _cachedRoutines!.sort((a, b) => a.rotationOrder.compareTo(b.rotationOrder));
    return saveAllRoutines(_cachedRoutines!);
  }

  @override
  Future<bool> deleteRoutine(String routineId) async {
    _cachedRoutines ??= await loadRoutines();
    _cachedRoutines!.removeWhere((r) => r.id == routineId);

    // Re-index rotationOrder
    for (int i = 0; i < _cachedRoutines!.length; i++) {
      _cachedRoutines![i] = _cachedRoutines![i].copyWith(rotationOrder: i);
    }

    return saveAllRoutines(_cachedRoutines!);
  }

  static List<WorkoutRoutine> getDefaultRoutines() {
    return LocalRoutineStorage()._buildDefaultRoutines();
  }

  @override
  Future<bool> saveAllRoutines(List<WorkoutRoutine> routines) async {
    _cachedRoutines = List<WorkoutRoutine>.from(routines);
    try {
      final jsonList = routines.map((r) => r.toJson()).toList();
      await StorageHelper.safeWriteString(_fileName, jsonEncode(jsonList));
      return true;
    } catch (_) {
      return true;
    }
  }

  List<WorkoutRoutine> _buildDefaultRoutines() {
    final now = DateTime(2026, 1, 1);

    return [
      WorkoutRoutine(
        id: 'routine_a_push',
        name: 'Workout A – Chest + Triceps',
        description: 'Clavicular pectoral hypertrophy and tricep lockouts',
        targetMuscleGroups: const ['Chest', 'Triceps', 'Shoulders'],
        rotationOrder: 0,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        exercises: const [
          RoutineExercise(
            id: 're_a_1',
            routineId: 'routine_a_push',
            exerciseId: 'ex_1',
            name: 'Incline Dumbbell Bench Press',
            targetMuscle: 'Chest',
            exerciseOrder: 0,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 34.0),
              ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 34.0),
              ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 36.0),
              ExerciseSetConfig(setNumber: 4, reps: 8, weightKg: 36.0),
            ],
            equipment: 'Dumbbell',
            secondaryMuscles: ['Shoulders', 'Triceps'],
          ),
          RoutineExercise(
            id: 're_a_2',
            routineId: 'routine_a_push',
            exerciseId: 'ex_2',
            name: 'Weighted Tricep Dips',
            targetMuscle: 'Triceps',
            exerciseOrder: 1,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 12, weightKg: 16.0),
              ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 20.0),
              ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 24.0),
            ],
            equipment: 'Bodyweight',
            secondaryMuscles: ['Chest', 'Shoulders'],
          ),
          RoutineExercise(
            id: 're_a_3',
            routineId: 'routine_a_push',
            exerciseId: 'ex_3',
            name: 'Standing Dual-Cable Flyes',
            targetMuscle: 'Chest',
            exerciseOrder: 2,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 15, weightKg: 14.0),
              ExerciseSetConfig(setNumber: 2, reps: 15, weightKg: 14.0),
              ExerciseSetConfig(setNumber: 3, reps: 12, weightKg: 16.0),
            ],
            equipment: 'Cable',
          ),
          RoutineExercise(
            id: 're_a_4',
            routineId: 'routine_a_push',
            exerciseId: 'ex_5',
            name: 'Overhead Rope Triceps Extension',
            targetMuscle: 'Triceps',
            exerciseOrder: 3,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 12, weightKg: 25.0),
              ExerciseSetConfig(setNumber: 2, reps: 12, weightKg: 25.0),
              ExerciseSetConfig(setNumber: 3, reps: 10, weightKg: 30.0),
            ],
            equipment: 'Cable',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'routine_b_pull',
        name: 'Workout B – Lats + Biceps',
        description: 'Vertical pulling density and focused elbow flexion',
        targetMuscleGroups: const ['Back', 'Biceps'],
        rotationOrder: 1,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        exercises: const [
          RoutineExercise(
            id: 're_b_1',
            routineId: 'routine_b_pull',
            exerciseId: 'ex_6',
            name: 'Neutral-Grip Lat Pulldown',
            targetMuscle: 'Back',
            exerciseOrder: 0,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 12, weightKg: 65.0),
              ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 70.0),
              ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 75.0),
              ExerciseSetConfig(setNumber: 4, reps: 8, weightKg: 75.0),
            ],
            equipment: 'Cable',
            secondaryMuscles: ['Biceps', 'Forearms'],
          ),
          RoutineExercise(
            id: 're_b_2',
            routineId: 'routine_b_pull',
            exerciseId: 'ex_7',
            name: 'Chest-Supported Row',
            targetMuscle: 'Back',
            exerciseOrder: 1,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 40.0),
              ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 40.0),
              ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 45.0),
            ],
            equipment: 'Machine',
            secondaryMuscles: ['Biceps'],
          ),
          RoutineExercise(
            id: 're_b_3',
            routineId: 'routine_b_pull',
            exerciseId: 'ex_8',
            name: 'Incline Dumbbell Bicep Curl',
            targetMuscle: 'Biceps',
            exerciseOrder: 2,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 12, weightKg: 14.0),
              ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 16.0),
              ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 16.0),
            ],
            equipment: 'Dumbbell',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'routine_c_legs',
        name: 'Workout C – Legs + Shoulders',
        description: 'Compound leg mechanics paired with lateral deltoid volume',
        targetMuscleGroups: const ['Quadriceps', 'Hamstrings', 'Shoulders'],
        rotationOrder: 2,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        exercises: const [
          RoutineExercise(
            id: 're_c_1',
            routineId: 'routine_c_legs',
            exerciseId: 'ex_11',
            name: 'Barbell Back Squat',
            targetMuscle: 'Quadriceps',
            exerciseOrder: 0,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 8, weightKg: 100.0),
              ExerciseSetConfig(setNumber: 2, reps: 8, weightKg: 105.0),
              ExerciseSetConfig(setNumber: 3, reps: 6, weightKg: 110.0),
            ],
            equipment: 'Barbell',
            secondaryMuscles: ['Glutes', 'Hamstrings'],
          ),
          RoutineExercise(
            id: 're_c_2',
            routineId: 'routine_c_legs',
            exerciseId: 'ex_12',
            name: 'Romanian Deadlift',
            targetMuscle: 'Hamstrings',
            exerciseOrder: 1,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 80.0),
              ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 85.0),
              ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 90.0),
            ],
            equipment: 'Barbell',
            secondaryMuscles: ['Glutes', 'Back'],
          ),
          RoutineExercise(
            id: 're_c_3',
            routineId: 'routine_c_legs',
            exerciseId: 'ex_13',
            name: 'Dumbbell Lateral Raise',
            targetMuscle: 'Shoulders',
            exerciseOrder: 2,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 15, weightKg: 12.0),
              ExerciseSetConfig(setNumber: 2, reps: 12, weightKg: 14.0),
              ExerciseSetConfig(setNumber: 3, reps: 12, weightKg: 14.0),
              ExerciseSetConfig(setNumber: 4, reps: 15, weightKg: 10.0),
            ],
            equipment: 'Dumbbell',
          ),
        ],
      ),
      WorkoutRoutine(
        id: 'routine_d_back_delts',
        name: 'Workout D – Back + Rear Delts',
        description: 'Scapular retractors, upper back thickness, and rear delts',
        targetMuscleGroups: const ['Back', 'Shoulders'],
        rotationOrder: 3,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        exercises: const [
          RoutineExercise(
            id: 're_d_1',
            routineId: 'routine_d_back_delts',
            exerciseId: 'ex_16',
            name: 'Barbell Bent-Over Row',
            targetMuscle: 'Back',
            exerciseOrder: 0,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 70.0),
              ExerciseSetConfig(setNumber: 2, reps: 8, weightKg: 75.0),
              ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 75.0),
            ],
            equipment: 'Barbell',
            secondaryMuscles: ['Biceps', 'Forearms'],
          ),
          RoutineExercise(
            id: 're_d_2',
            routineId: 'routine_d_back_delts',
            exerciseId: 'ex_17',
            name: 'Reverse Pec Deck (Rear Delt Fly)',
            targetMuscle: 'Shoulders',
            exerciseOrder: 1,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 15, weightKg: 45.0),
              ExerciseSetConfig(setNumber: 2, reps: 12, weightKg: 50.0),
              ExerciseSetConfig(setNumber: 3, reps: 12, weightKg: 50.0),
            ],
            equipment: 'Machine',
          ),
        ],
      ),
    ];
  }
}
