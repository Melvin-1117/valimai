import 'dart:convert';
import '../models/weekly_schedule.dart';
import '../models/workout.dart';
import 'storage_helper.dart';

abstract class IWorkoutStorage {
  Future<Map<String, Workout>> loadWorkouts();
  Future<Map<String, DaySchedule>> loadSchedules();
  Future<Map<int, WeeklyDayAssignment>> loadWeeklyPlan();
  Future<bool> saveWorkout(Workout workout);
  Future<bool> saveDaySchedule(DaySchedule schedule);
  Future<bool> saveAllSchedules(Map<String, DaySchedule> schedules);
  Future<bool> saveWeeklyPlan(Map<int, WeeklyDayAssignment> plan);
}

class LocalWorkoutStorage implements IWorkoutStorage {
  static const String _scheduleFileName = 'valimai_schedule.json';
  static const String _workoutsFileName = 'valimai_workouts.json';
  static const String _weeklyPlanFileName = 'valimai_weekly_plan.json';

  Map<String, Workout>? _cachedWorkouts;
  Map<String, DaySchedule>? _cachedSchedules;
  Map<int, WeeklyDayAssignment>? _cachedWeeklyPlan;

  @override
  Future<Map<String, Workout>> loadWorkouts() async {
    if (_cachedWorkouts != null) {
      return _cachedWorkouts!;
    }

    try {
      final content = await StorageHelper.safeReadString(_workoutsFileName);
      if (content != null && content.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(content);
        final result = <String, Workout>{};
        jsonMap.forEach((key, val) {
          result[key] = Workout.fromJson(val as Map<String, dynamic>);
        });
        _cachedWorkouts = result;
        return result;
      }
    } catch (_) {}

    // Fresh user state: start with an empty workouts map
    _cachedWorkouts = <String, Workout>{};
    return _cachedWorkouts!;
  }

  @override
  Future<Map<String, DaySchedule>> loadSchedules() async {
    if (_cachedSchedules != null) {
      return _cachedSchedules!;
    }

    try {
      final content = await StorageHelper.safeReadString(_scheduleFileName);
      if (content != null && content.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(content);
        final result = <String, DaySchedule>{};
        jsonMap.forEach((key, val) {
          result[key] = DaySchedule.fromJson(val as Map<String, dynamic>);
        });
        _cachedSchedules = result;
        return result;
      }
    } catch (_) {}

    // Fresh user state: start with an empty schedule map
    _cachedSchedules = <String, DaySchedule>{};
    return _cachedSchedules!;
  }

  @override
  Future<bool> saveWorkout(Workout workout) async {
    _cachedWorkouts ??= await loadWorkouts();
    _cachedWorkouts![workout.id] = workout;

    try {
      final map = _cachedWorkouts!.map((k, v) => MapEntry(k, v.toJson()));
      await StorageHelper.safeWriteString(_workoutsFileName, jsonEncode(map));
      return true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> saveDaySchedule(DaySchedule schedule) async {
    _cachedSchedules ??= await loadSchedules();
    final key = DaySchedule.dateKey(schedule.date);
    _cachedSchedules![key] = schedule;

    return saveAllSchedules(_cachedSchedules!);
  }

  @override
  Future<bool> saveAllSchedules(Map<String, DaySchedule> schedules) async {
    _cachedSchedules = Map<String, DaySchedule>.from(schedules);
    try {
      final map = schedules.map((k, v) => MapEntry(k, v.toJson()));
      await StorageHelper.safeWriteString(_scheduleFileName, jsonEncode(map));
      return true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<Map<int, WeeklyDayAssignment>> loadWeeklyPlan() async {
    if (_cachedWeeklyPlan != null) {
      return _cachedWeeklyPlan!;
    }

    try {
      final content = await StorageHelper.safeReadString(_weeklyPlanFileName);
      if (content != null && content.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(content);
        final result = <int, WeeklyDayAssignment>{};
        jsonMap.forEach((key, val) {
          final weekday = int.tryParse(key);
          if (weekday != null) {
            result[weekday] =
                WeeklyDayAssignment.fromJson(val as Map<String, dynamic>);
          }
        });
        _cachedWeeklyPlan = result;
        return result;
      }
    } catch (_) {}

    // Fresh user state: start with an empty weekly plan
    _cachedWeeklyPlan = <int, WeeklyDayAssignment>{};
    return _cachedWeeklyPlan!;
  }

  @override
  Future<bool> saveWeeklyPlan(Map<int, WeeklyDayAssignment> plan) async {
    _cachedWeeklyPlan = Map<int, WeeklyDayAssignment>.from(plan);
    try {
      final map = plan.map((k, v) => MapEntry(k.toString(), v.toJson()));
      await StorageHelper.safeWriteString(_weeklyPlanFileName, jsonEncode(map));
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Helper for sample testing
  static Map<int, WeeklyDayAssignment> getDefaultWeeklyPlan() {
    return {
      1: const WeeklyDayAssignment(
        weekday: 1,
        type: ScheduledDayType.workout,
        routineId: 'routine_a_push',
      ),
      2: const WeeklyDayAssignment(
        weekday: 2,
        type: ScheduledDayType.workout,
        routineId: 'routine_b_pull',
      ),
      3: const WeeklyDayAssignment(
        weekday: 3,
        type: ScheduledDayType.rest,
      ),
      4: const WeeklyDayAssignment(
        weekday: 4,
        type: ScheduledDayType.workout,
        routineId: 'routine_c_legs',
      ),
      5: const WeeklyDayAssignment(
        weekday: 5,
        type: ScheduledDayType.workout,
        routineId: 'routine_a_push',
      ),
      6: const WeeklyDayAssignment(
        weekday: 6,
        type: ScheduledDayType.workout,
        routineId: 'routine_b_pull',
      ),
      7: const WeeklyDayAssignment(
        weekday: 7,
        type: ScheduledDayType.rest,
      ),
    };
  }

  /// Helper for sample testing
  static Map<String, Workout> getDefaultWorkouts() {
    return {
      'workout_push': const Workout(
        id: 'workout_push',
        name: 'Chest & Triceps Hypertrophy',
        targetMuscleGroups:
            'Pectorals (Sternocostal & Clavicular), Anterior Deltoids, Lateral Triceps',
        estimatedDurationMinutes: 52,
        exercises: [
          WorkoutExercise(
            id: 'ex_1',
            name: 'Incline Dumbbell Bench Press',
            targetMuscle: 'Clavicular Pectoral',
            sets: 4,
            reps: 10,
            weightKg: 34.0,
            order: 0,
          ),
          WorkoutExercise(
            id: 'ex_2',
            name: 'Weighted Tricep Dips',
            targetMuscle: 'Lateral Triceps',
            sets: 3,
            reps: 12,
            weightKg: 16.0,
            order: 1,
          ),
          WorkoutExercise(
            id: 'ex_3',
            name: 'Standing Dual-Cable Flyes',
            targetMuscle: 'Sternal Head',
            sets: 4,
            reps: 15,
            weightKg: 14.0,
            order: 2,
          ),
          WorkoutExercise(
            id: 'ex_4',
            name: 'Close-Grip Barbell Bench Press',
            targetMuscle: 'Triceps Brachii',
            sets: 3,
            reps: 8,
            weightKg: 60.0,
            order: 3,
          ),
          WorkoutExercise(
            id: 'ex_5',
            name: 'Overhead Rope Triceps Extension',
            targetMuscle: 'Long Head Triceps',
            sets: 4,
            reps: 12,
            weightKg: 24.0,
            order: 4,
          ),
        ],
      ),
      'workout_pull': const Workout(
        id: 'workout_pull',
        name: 'Heavy Back & Biceps Focus',
        targetMuscleGroups:
            'Latissimus Dorsi, Rhomboids, Biceps Brachii, Rear Delts',
        estimatedDurationMinutes: 58,
        exercises: [
          WorkoutExercise(
            id: 'ex_pull_1',
            name: 'Neutral Grip Lat Pulldown',
            targetMuscle: 'Latissimus Dorsi',
            sets: 4,
            reps: 10,
            weightKg: 65.0,
            order: 0,
          ),
          WorkoutExercise(
            id: 'ex_pull_2',
            name: 'Chest-Supported T-Bar Row',
            targetMuscle: 'Mid Back & Rhomboids',
            sets: 4,
            reps: 8,
            weightKg: 55.0,
            order: 1,
          ),
          WorkoutExercise(
            id: 'ex_pull_3',
            name: 'Incline Dumbbell Bicep Curls',
            targetMuscle: 'Biceps Brachii',
            sets: 3,
            reps: 12,
            weightKg: 14.0,
            order: 2,
          ),
          WorkoutExercise(
            id: 'ex_pull_4',
            name: 'Face Pulls with Cable Rope',
            targetMuscle: 'Rear Delts & Rotator Cuff',
            sets: 4,
            reps: 15,
            weightKg: 20.0,
            order: 3,
          ),
        ],
      ),
      'workout_legs': const Workout(
        id: 'workout_legs',
        name: 'Quad Dominant & Calves',
        targetMuscleGroups: 'Quadriceps, Adductors, Gastrocnemius, Core',
        estimatedDurationMinutes: 60,
        exercises: [
          WorkoutExercise(
            id: 'ex_legs_1',
            name: 'Barbell Back Squats',
            targetMuscle: 'Quadriceps & Glutes',
            sets: 4,
            reps: 8,
            weightKg: 100.0,
            order: 0,
          ),
          WorkoutExercise(
            id: 'ex_legs_2',
            name: 'Hack Squat Wave',
            targetMuscle: 'Vastus Lateralis',
            sets: 4,
            reps: 10,
            weightKg: 120.0,
            order: 1,
          ),
          WorkoutExercise(
            id: 'ex_legs_3',
            name: 'Bulgarian Split Squats',
            targetMuscle: 'Unilateral Quads',
            sets: 3,
            reps: 10,
            weightKg: 22.0,
            order: 2,
          ),
          WorkoutExercise(
            id: 'ex_legs_4',
            name: 'Standing Calf Raises',
            targetMuscle: 'Gastrocnemius',
            sets: 4,
            reps: 15,
            weightKg: 70.0,
            order: 3,
          ),
        ],
      ),
      'workout_shoulders': const Workout(
        id: 'workout_shoulders',
        name: 'Posterior Chain & Deltoid Wave',
        targetMuscleGroups: 'Hamstrings, Gluteus Maximus, Lateral Deltoids',
        estimatedDurationMinutes: 55,
        exercises: [
          WorkoutExercise(
            id: 'ex_sh_1',
            name: 'Romanian Deadlift (RDL)',
            targetMuscle: 'Hamstring Complex',
            sets: 4,
            reps: 8,
            weightKg: 95.0,
            order: 0,
          ),
          WorkoutExercise(
            id: 'ex_sh_2',
            name: 'Seated Dumbbell Shoulder Press',
            targetMuscle: 'Anterior & Medial Delts',
            sets: 4,
            reps: 10,
            weightKg: 26.0,
            order: 1,
          ),
          WorkoutExercise(
            id: 'ex_sh_3',
            name: 'Cable Lateral Raise',
            targetMuscle: 'Lateral Deltoids',
            sets: 4,
            reps: 15,
            weightKg: 10.0,
            order: 2,
          ),
        ],
      ),
      'workout_core': const Workout(
        id: 'workout_core',
        name: 'Core & Metabolic Conditioning',
        targetMuscleGroups: 'Rectus Abdominis, Obliques, Cardiovascular',
        estimatedDurationMinutes: 35,
        exercises: [
          WorkoutExercise(
            id: 'ex_core_1',
            name: 'Hanging Leg Raises',
            targetMuscle: 'Lower Abdominals',
            sets: 4,
            reps: 12,
            weightKg: 0.0,
            order: 0,
          ),
          WorkoutExercise(
            id: 'ex_core_2',
            name: 'Ab Wheel Rollout',
            targetMuscle: 'Core Stabilizers',
            sets: 3,
            reps: 10,
            weightKg: 0.0,
            order: 1,
          ),
          WorkoutExercise(
            id: 'ex_core_3',
            name: 'Cable Woodchoppers',
            targetMuscle: 'Obliques',
            sets: 3,
            reps: 15,
            weightKg: 15.0,
            order: 2,
          ),
        ],
      ),
    };
  }

  /// Helper for sample testing
  static Map<String, DaySchedule> getDefaultWeekSchedules() {
    final now = DateTime.now();
    // Monday of current week (DateTime.weekday: 1 = Mon, 7 = Sun)
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    final Map<String, DaySchedule> map = {};

    final weekPlan = [
      {'dayOffset': 0, 'type': ScheduledDayType.workout, 'id': 'workout_push'},
      {'dayOffset': 1, 'type': ScheduledDayType.workout, 'id': 'workout_pull'},
      {'dayOffset': 2, 'type': ScheduledDayType.rest, 'id': null},
      {'dayOffset': 3, 'type': ScheduledDayType.workout, 'id': 'workout_legs'},
      {'dayOffset': 4, 'type': ScheduledDayType.workout, 'id': 'workout_shoulders'},
      {'dayOffset': 5, 'type': ScheduledDayType.workout, 'id': 'workout_core'},
      {'dayOffset': 6, 'type': ScheduledDayType.rest, 'id': null},
    ];

    for (final item in weekPlan) {
      final date = monday.add(Duration(days: item['dayOffset'] as int));
      final dateNorm = DateTime(date.year, date.month, date.day);
      final key = DaySchedule.dateKey(dateNorm);
      final isPast = dateNorm.isBefore(DateTime(now.year, now.month, now.day));

      map[key] = DaySchedule(
        date: dateNorm,
        type: item['type'] as ScheduledDayType,
        workoutId: item['id'] as String?,
        isCompleted: isPast && item['type'] == ScheduledDayType.workout,
      );
    }

    return map;
  }
}

