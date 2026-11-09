import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valimai/models/daily_workout.dart';
import 'package:valimai/models/exercise.dart';
import 'package:valimai/models/routine.dart';
import 'package:valimai/models/user_profile.dart';
import 'package:valimai/models/weekly_schedule.dart';
import 'package:valimai/models/workout.dart';
import 'package:valimai/models/workout_rotation.dart';
import 'package:valimai/screens/active_workout_screen.dart';
import 'package:valimai/screens/add_exercise_screen.dart';
import 'package:valimai/screens/daily_analytics_screen.dart';
import 'package:valimai/screens/daily_workout_selection_screen.dart';
import 'package:valimai/screens/exercise_configuration_screen.dart';
import 'package:valimai/screens/history_screen.dart';
import 'package:valimai/screens/home_screen.dart';
import 'package:valimai/screens/profile_screen.dart';
import 'package:valimai/screens/schedule_screen.dart';
import 'package:valimai/screens/workout_editor_screen.dart';
import 'package:valimai/screens/workouts_screen.dart';
import 'package:valimai/services/daily_workout_controller.dart';
import 'package:valimai/services/daily_workout_storage.dart';
import 'package:valimai/services/exercise_controller.dart';
import 'package:valimai/services/exercise_storage.dart';
import 'package:valimai/services/profile_analytics_service.dart';
import 'package:valimai/services/profile_controller.dart';
import 'package:valimai/services/profile_storage.dart';
import 'package:valimai/services/routine_controller.dart';
import 'package:valimai/services/routine_storage.dart';
import 'package:valimai/services/workout_controller.dart';
import 'package:valimai/services/storage_helper.dart';
import 'package:valimai/services/workout_history_controller.dart';
import 'package:valimai/services/workout_rotation_engine.dart';
import 'package:valimai/services/workout_storage.dart';

class MockProfileStorage implements IProfileStorage {
  UserProfile? storedProfile;

  @override
  Future<UserProfile?> loadProfile() async => storedProfile;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    storedProfile = profile;
  }

  @override
  Future<void> clearProfile() async {
    storedProfile = null;
  }
}

class MockWorkoutStorage implements IWorkoutStorage {
  Map<String, Workout> workouts = {};
  Map<String, DaySchedule> schedules = {};
  Map<int, WeeklyDayAssignment> weeklyPlan = {};

  MockWorkoutStorage() {
    _seed();
  }

  void _seed() {
    weeklyPlan = {
      1: const WeeklyDayAssignment(
          weekday: 1, type: ScheduledDayType.workout, routineId: 'routine_a_push'),
      2: const WeeklyDayAssignment(
          weekday: 2, type: ScheduledDayType.workout, routineId: 'routine_b_pull'),
      3: const WeeklyDayAssignment(
          weekday: 3, type: ScheduledDayType.rest),
      4: const WeeklyDayAssignment(
          weekday: 4, type: ScheduledDayType.workout, routineId: 'routine_c_legs'),
      5: const WeeklyDayAssignment(
          weekday: 5, type: ScheduledDayType.workout, routineId: 'routine_a_push'),
      6: const WeeklyDayAssignment(
          weekday: 6, type: ScheduledDayType.workout, routineId: 'routine_b_pull'),
      7: const WeeklyDayAssignment(
          weekday: 7, type: ScheduledDayType.rest),
    };

    final pushWorkout = const Workout(
      id: 'workout_push',
      name: 'Chest & Triceps Hypertrophy',
      targetMuscleGroups: 'Pectorals, Anterior Deltoids, Lateral Triceps',
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
      ],
    );

    workouts[pushWorkout.id] = pushWorkout;
  }

  @override
  Future<Map<String, Workout>> loadWorkouts() async =>
      Map<String, Workout>.from(workouts);

  @override
  Future<Map<String, DaySchedule>> loadSchedules() async =>
      Map<String, DaySchedule>.from(schedules);

  @override
  Future<bool> saveWorkout(Workout workout) async {
    workouts[workout.id] = workout;
    return true;
  }

  @override
  Future<bool> saveDaySchedule(DaySchedule schedule) async {
    schedules[DaySchedule.dateKey(schedule.date)] = schedule;
    return true;
  }

  @override
  Future<bool> saveAllSchedules(Map<String, DaySchedule> newSchedules) async {
    schedules = Map<String, DaySchedule>.from(newSchedules);
    return true;
  }

  @override
  Future<Map<int, WeeklyDayAssignment>> loadWeeklyPlan() async =>
      Map<int, WeeklyDayAssignment>.from(weeklyPlan);

  @override
  Future<bool> saveWeeklyPlan(Map<int, WeeklyDayAssignment> plan) async {
    weeklyPlan = Map<int, WeeklyDayAssignment>.from(plan);
    return true;
  }
}

class MockExerciseStorage implements IExerciseStorage {
  List<Exercise> exercises = [];

  MockExerciseStorage() {
    exercises = LocalExerciseStorage.getPresetExercises();
  }

  @override
  Future<List<Exercise>> loadExercises() async =>
      List<Exercise>.from(exercises);

  @override
  Future<bool> saveCustomExercise(Exercise exercise) async {
    final index = exercises.indexWhere((e) =>
        e.name.toLowerCase().trim() == exercise.name.toLowerCase().trim());
    if (index >= 0) {
      exercises[index] = exercise;
    } else {
      exercises.add(exercise);
    }
    return true;
  }

  @override
  Future<bool> saveAllExercises(List<Exercise> all) async {
    exercises = List<Exercise>.from(all);
    return true;
  }
}

class MockRoutineStorage implements IRoutineStorage {
  List<WorkoutRoutine> routines = [];

  MockRoutineStorage() {
    routines = LocalRoutineStorage.getDefaultRoutines();
  }

  @override
  Future<List<WorkoutRoutine>> loadRoutines() async =>
      List<WorkoutRoutine>.from(routines);

  @override
  Future<bool> saveRoutine(WorkoutRoutine routine) async {
    final index = routines.indexWhere((r) => r.id == routine.id);
    if (index >= 0) {
      routines[index] = routine;
    } else {
      routines.add(routine);
    }
    return true;
  }

  @override
  Future<bool> deleteRoutine(String routineId) async {
    routines.removeWhere((r) => r.id == routineId);
    return true;
  }

  @override
  Future<bool> saveAllRoutines(List<WorkoutRoutine> newRoutines) async {
    routines = List<WorkoutRoutine>.from(newRoutines);
    return true;
  }
}

class MockDailyWorkoutStorage implements IDailyWorkoutStorage {
  Map<String, DailyWorkout> records = {};

  @override
  Future<Map<String, DailyWorkout>> loadDailyWorkouts() async =>
      Map<String, DailyWorkout>.from(records);

  @override
  Future<bool> saveDailyWorkout(DailyWorkout record) async {
    records[record.localDate] = record;
    return true;
  }

  @override
  Future<DailyWorkout?> getDailyWorkoutForDate(String localDate) async =>
      records[localDate];
}

class MockWorkoutHistoryStorage implements IWorkoutHistoryStorage {
  final List<CompletedWorkoutSession> sessions = [];

  @override
  Future<List<CompletedWorkoutSession>> loadSessions() async =>
      List<CompletedWorkoutSession>.from(sessions);

  @override
  Future<bool> saveSessions(List<CompletedWorkoutSession> newSessions) async {
    sessions.clear();
    sessions.addAll(newSessions);
    return true;
  }
}

void main() {
  late MockProfileStorage mockProfileStorage;
  late ProfileController profileController;
  late MockWorkoutStorage mockWorkoutStorage;
  late WorkoutController workoutController;
  late MockExerciseStorage mockExerciseStorage;
  late ExerciseController exerciseController;
  late MockRoutineStorage mockRoutineStorage;
  late RoutineController routineController;
  late MockDailyWorkoutStorage mockDailyWorkoutStorage;
  late DailyWorkoutController dailyWorkoutController;
  late MockWorkoutHistoryStorage mockWorkoutHistoryStorage;
  late WorkoutHistoryController workoutHistoryController;

  setUp(() {
    mockProfileStorage = MockProfileStorage();
    profileController = ProfileController(storage: mockProfileStorage);
    ProfileController.setInstance(profileController);

    mockWorkoutStorage = MockWorkoutStorage();
    workoutController = WorkoutController(storage: mockWorkoutStorage);
    WorkoutController.setInstance(workoutController);

    mockExerciseStorage = MockExerciseStorage();
    exerciseController = ExerciseController(storage: mockExerciseStorage);
    ExerciseController.setInstance(exerciseController);

    mockRoutineStorage = MockRoutineStorage();
    routineController = RoutineController(storage: mockRoutineStorage);
    RoutineController.setInstance(routineController);

    mockDailyWorkoutStorage = MockDailyWorkoutStorage();
    dailyWorkoutController =
        DailyWorkoutController(storage: mockDailyWorkoutStorage);
    DailyWorkoutController.setInstance(dailyWorkoutController);

    mockWorkoutHistoryStorage = MockWorkoutHistoryStorage();
    workoutHistoryController =
        WorkoutHistoryController(storage: mockWorkoutHistoryStorage);
    WorkoutHistoryController.setInstance(workoutHistoryController);

    WorkoutRotationEngine.setInstance(WorkoutRotationEngine());

    final tempDir = Directory.systemTemp.createTempSync('valimai_test_');
    StorageHelper.setStorageDirectory(tempDir);
  });

  group('UserProfile Model Tests', () {
    test('computes initials correctly', () {
      final p1 = UserProfile(
        name: 'Alex Mercer',
        currentWeight: 80.0,
        height: 180.0,
        age: 26,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(p1.initials, 'AM');

      final p2 = p1.copyWith(name: 'Marcus');
      expect(p2.initials, 'M');

      final p3 = p1.copyWith(name: 'John von Neumann');
      expect(p3.initials, 'JN');

      final p4 = p1.copyWith(name: '');
      expect(p4.initials, 'V');
    });

    test('serializes and deserializes to JSON accurately', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final profile = UserProfile(
        name: 'Sarah Connor',
        currentWeight: 65.5,
        height: 172.0,
        age: 29,
        targetWeight: 62.0,
        createdAt: now,
        updatedAt: now,
      );

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.name, 'Sarah Connor');
      expect(restored.currentWeight, 65.5);
      expect(restored.height, 172.0);
      expect(restored.age, 29);
      expect(restored.targetWeight, 62.0);
      expect(restored.isOnboardingCompleted, isTrue);
    });
  });

  group('Exercise Model & Controller Tests', () {
    test('verifies all 11 muscle group categories exist', () {
      expect(MuscleGroupCategories.all.length, 11);
      expect(MuscleGroupCategories.all, contains('Chest'));
      expect(MuscleGroupCategories.all, contains('Back'));
      expect(MuscleGroupCategories.all, contains('Shoulders'));
      expect(MuscleGroupCategories.all, contains('Biceps'));
      expect(MuscleGroupCategories.all, contains('Triceps'));
      expect(MuscleGroupCategories.all, contains('Forearms'));
      expect(MuscleGroupCategories.all, contains('Abs'));
      expect(MuscleGroupCategories.all, contains('Quadriceps'));
      expect(MuscleGroupCategories.all, contains('Hamstrings'));
      expect(MuscleGroupCategories.all, contains('Glutes'));
      expect(MuscleGroupCategories.all, contains('Calves'));
    });

    test('preset exercise library is fully populated across all categories', () async {
      await exerciseController.initialize();
      expect(exerciseController.allExercises.length, greaterThanOrEqualTo(50));

      for (final cat in MuscleGroupCategories.all) {
        final count = exerciseController.countByCategory(cat);
        expect(count, greaterThan(0), reason: 'Category $cat must have exercises');
      }
    });

    test('searches case-insensitively across name, muscle, and equipment', () async {
      await exerciseController.initialize();

      final r1 = exerciseController.searchExercises('bench press');
      expect(r1.length, greaterThanOrEqualTo(3));

      final r2 = exerciseController.searchExercises('CABLE');
      expect(r2.length, greaterThan(0));

      final r3 = exerciseController.searchExercises('quadriceps');
      expect(r3.length, greaterThan(0));

      final byId = exerciseController.getExerciseById(r1.first.id);
      expect(byId, isNotNull);
      expect(byId!.name, r1.first.name);

      final byName = exerciseController.getExerciseByName('barbell bench press');
      expect(byName, isNotNull);
      expect(byName!.primaryMuscleGroup, 'Chest');
    });

    test('creates custom exercise with validation and duplicate prevention', () async {
      await exerciseController.initialize();

      // Empty name fails
      final fail1 = await exerciseController.addCustomExercise(
        name: '   ',
        primaryMuscleGroup: 'Chest',
        equipment: 'Dumbbell',
      );
      expect(fail1, isNull);
      expect(exerciseController.lastError, contains('cannot be empty'));

      // Duplicate name fails
      final fail2 = await exerciseController.addCustomExercise(
        name: 'Barbell Bench Press', // Existing preset
        primaryMuscleGroup: 'Chest',
        equipment: 'Barbell',
      );
      expect(fail2, isNull);
      expect(exerciseController.lastError, contains('already exists'));

      // Valid custom exercise succeeds
      final custom = await exerciseController.addCustomExercise(
        name: 'Custom Landmine Press',
        primaryMuscleGroup: 'Shoulders',
        secondaryMuscleGroups: ['Chest', 'Triceps'],
        equipment: 'Barbell',
      );
      expect(custom, isNotNull);
      expect(custom!.isCustom, isTrue);
      expect(exerciseController.searchExercises('Landmine').length, 1);
    });
  });

  group('AddExerciseScreen UI Tests', () {
    testWidgets('Displays search bar, categories, and exercise list', (tester) async {
      await exerciseController.initialize();

      await tester.pumpWidget(
        const MaterialApp(
          home: AddExerciseScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Custom action
      expect(find.text('ADD EXERCISE'), findsOneWidget);
      expect(find.text('CUSTOM'), findsOneWidget);

      // Search bar
      expect(find.byType(TextField), findsOneWidget);

      // Category chips (ALL, CHEST, BACK, etc.)
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('CHEST'), findsOneWidget);

      // Exercise listing
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Incline Barbell Bench Press'), findsOneWidget);
    });

    testWidgets('Supports multi-selection and displays sticky bottom bar', (tester) async {
      await exerciseController.initialize();

      await tester.pumpWidget(
        const MaterialApp(
          home: AddExerciseScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Bottom bar not visible initially
      expect(find.text('ADD TO WORKOUT (1)'), findsNothing);

      // Tap first exercise
      await tester.tap(find.text('Barbell Bench Press'));
      await tester.pumpAndSettle();

      // Bottom bar appears
      expect(find.text('ADD TO WORKOUT (1)'), findsOneWidget);

      // Tap second exercise
      await tester.tap(find.text('Incline Barbell Bench Press'));
      await tester.pumpAndSettle();

      expect(find.text('ADD TO WORKOUT (2)'), findsOneWidget);
    });

    testWidgets('Prevents duplicate additions for exercises already in workout', (tester) async {
      await exerciseController.initialize();

      await tester.pumpWidget(
        const MaterialApp(
          home: AddExerciseScreen(
            existingExerciseNames: {'barbell bench press'},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('IN WORKOUT'), findsOneWidget);

      // Tapping does not add to selection
      await tester.tap(find.text('Barbell Bench Press'));
      await tester.pumpAndSettle();

      expect(find.text('ADD TO WORKOUT (1)'), findsNothing);
    });
  });

  group('ExerciseSetConfig & WorkoutExercise Data Model Tests', () {
    test('ExerciseSetConfig serialization, copyWith, and equality', () {
      const set1 = ExerciseSetConfig(setNumber: 1, reps: 12, weightKg: 40.0);
      final json = set1.toJson();
      final restored = ExerciseSetConfig.fromJson(json);

      expect(restored.setNumber, 1);
      expect(restored.reps, 12);
      expect(restored.weightKg, 40.0);

      final modified = set1.copyWith(reps: 15, weightKg: 45.0);
      expect(modified.setNumber, 1);
      expect(modified.reps, 15);
      expect(modified.weightKg, 45.0);
    });

    test('WorkoutExercise effectiveSetConfigs provides fallback for legacy data', () {
      const legacyExercise = WorkoutExercise(
        id: 'legacy_1',
        name: 'Dumbbell Bench Press',
        targetMuscle: 'Chest',
        sets: 3,
        reps: 10,
        weightKg: 24.0,
      );

      expect(legacyExercise.setConfigs.isEmpty, isTrue);
      expect(legacyExercise.effectiveSetConfigs.length, 3);
      expect(legacyExercise.effectiveSetConfigs[0].setNumber, 1);
      expect(legacyExercise.effectiveSetConfigs[0].reps, 10);
      expect(legacyExercise.effectiveSetConfigs[0].weightKg, 24.0);
      expect(legacyExercise.effectiveSetConfigs[2].setNumber, 3);
    });

    test('WorkoutExercise preserves individual set configurations in JSON', () {
      final customExercise = WorkoutExercise(
        id: 'custom_1',
        name: 'Barbell Squat',
        targetMuscle: 'Quadriceps',
        setConfigs: const [
          ExerciseSetConfig(setNumber: 1, reps: 12, weightKg: 80.0),
          ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 90.0),
          ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 100.0),
        ],
      );

      final json = customExercise.toJson();
      final restored = WorkoutExercise.fromJson(json);

      expect(restored.setConfigs.length, 3);
      expect(restored.setConfigs[0].reps, 12);
      expect(restored.setConfigs[0].weightKg, 80.0);
      expect(restored.setConfigs[1].reps, 10);
      expect(restored.setConfigs[1].weightKg, 90.0);
      expect(restored.setConfigs[2].reps, 8);
      expect(restored.setConfigs[2].weightKg, 100.0);
    });
  });

  group('ExerciseConfigurationScreen UI Tests', () {
    testWidgets('Renders exercise metadata and set cards without rest timer controls', (tester) async {
      const testEx = WorkoutExercise(
        id: 'ex_cfg_1',
        name: 'Incline Dumbbell Press',
        targetMuscle: 'Chest',
        equipment: 'Dumbbell',
        setConfigs: [
          ExerciseSetConfig(setNumber: 1, reps: 12, weightKg: 30.0),
          ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 35.0),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseConfigurationScreen(workoutExercise: testEx),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EXERCISE CONFIGURATION'), findsOneWidget);
      expect(find.text('Incline Dumbbell Press'), findsOneWidget);
      expect(find.text('SET 1'), findsOneWidget);
      expect(find.text('SET 2'), findsOneWidget);
      expect(find.text('30 kg'), findsOneWidget);
      expect(find.text('35 kg'), findsOneWidget);
      // Rest timer controls must be completely absent
      expect(find.text('REST INTERVAL BETWEEN SETS'), findsNothing);
      expect(find.text('1 min 30 sec'), findsNothing);
    });

    testWidgets('Adds new set prefilled with previous set reps and weight', (tester) async {
      const testEx = WorkoutExercise(
        id: 'ex_cfg_2',
        name: 'Barbell Row',
        targetMuscle: 'Back',
        equipment: 'Barbell',
        setConfigs: [
          ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 60.0),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseConfigurationScreen(workoutExercise: testEx),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SET 1'), findsOneWidget);
      expect(find.text('SET 2'), findsNothing);

      // Tap ADD SET
      await tester.tap(find.text('ADD SET'));
      await tester.pumpAndSettle();

      expect(find.text('SET 1'), findsOneWidget);
      expect(find.text('SET 2'), findsOneWidget);
      // Both sets should have 60 kg
      expect(find.text('60 kg'), findsNWidgets(2));
    });

    testWidgets('Apply to All sets copies reps and weight across all sets', (tester) async {
      const testEx = WorkoutExercise(
        id: 'ex_cfg_3',
        name: 'Cable Fly',
        targetMuscle: 'Chest',
        equipment: 'Cable',
        setConfigs: [
          ExerciseSetConfig(setNumber: 1, reps: 15, weightKg: 15.0),
          ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 20.0),
          ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 25.0),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseConfigurationScreen(workoutExercise: testEx),
        ),
      );
      await tester.pumpAndSettle();

      // Find "Apply to All" buttons (one per set)
      final applyButtons = find.text('Apply to All');
      expect(applyButtons, findsNWidgets(3));

      // Tap first "Apply to All"
      await tester.tap(applyButtons.first);
      await tester.pumpAndSettle();

      // Now all 3 sets should have 15 kg and 15 reps
      expect(find.text('15 kg'), findsNWidgets(3));
      expect(find.text('15'), findsNWidgets(3));
    });

    testWidgets('Prevents removing the only remaining set', (tester) async {
      const testEx = WorkoutExercise(
        id: 'ex_cfg_4',
        name: 'Lat Pulldown',
        targetMuscle: 'Back',
        equipment: 'Cable',
        setConfigs: [
          ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 45.0),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseConfigurationScreen(workoutExercise: testEx),
        ),
      );
      await tester.pumpAndSettle();

      // Delete icon is disabled when 1 set exists
      final deleteBtn = find.byIcon(Icons.delete_outline);
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Set 1 is still present
      expect(find.text('SET 1'), findsOneWidget);
    });
  });

  group('WorkoutEditor Integration Tests', () {
    testWidgets('Opening WorkoutEditor allows adding exercises', (tester) async {
      await workoutController.initialize();
      await exerciseController.initialize();

      final now = DateTime.now();
      final workout = workoutController.getWorkoutForDate(now)!;

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutEditorScreen(
            date: now,
            workout: workout,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WORKOUT EDITOR'), findsOneWidget);
      expect(find.text('Add Exercise'), findsOneWidget);
    });

    testWidgets('WorkoutEditor search filters exercises in real time', (tester) async {
      await workoutController.initialize();
      await exerciseController.initialize();

      final now = DateTime.now();
      final workout = workoutController.getWorkoutForDate(now)!;

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutEditorScreen(
            date: now,
            workout: workout,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search bar is present
      final searchField = find.byType(TextField).at(2); // After name and muscle inputs
      await tester.enterText(searchField, 'Tricep');
      await tester.pumpAndSettle();

      // Should show Weighted Tricep Dips, but not Incline Dumbbell Bench Press
      expect(find.text('Weighted Tricep Dips'), findsOneWidget);
      expect(find.text('Incline Dumbbell Bench Press'), findsNothing);

      // Clearing search restores both
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      expect(find.text('Weighted Tricep Dips'), findsOneWidget);
      expect(find.text('Incline Dumbbell Bench Press'), findsOneWidget);
    });
  });

  group('WorkoutRoutine & RoutineExercise Data Architecture Tests', () {
    test('RoutineExercise serializes and deserializes cleanly with setConfigs', () {
      const routineEx = RoutineExercise(
        id: 're_test_1',
        routineId: 'routine_1',
        exerciseId: 'ex_1',
        name: 'Incline Dumbbell Press',
        targetMuscle: 'Chest',
        exerciseOrder: 0,
        equipment: 'Dumbbell',
        secondaryMuscles: ['Triceps', 'Shoulders'],
        setsConfiguration: [
          ExerciseSetConfig(setNumber: 1, reps: 12, weightKg: 30.0),
          ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 35.0),
        ],
      );

      final json = routineEx.toJson();
      final restored = RoutineExercise.fromJson(json);

      expect(restored.id, 're_test_1');
      expect(restored.name, 'Incline Dumbbell Press');
      expect(restored.targetMuscle, 'Chest');
      expect(restored.setsConfiguration.length, 2);
      expect(restored.setsConfiguration[0].weightKg, 30.0);
      expect(restored.setsConfiguration[1].weightKg, 35.0);
    });

    test('WorkoutRoutine converts to Workout and updates back cleanly', () {
      final routine = WorkoutRoutine(
        id: 'routine_test_1',
        name: 'Workout A – Chest + Triceps',
        description: 'Pectoral hypertrophy focus',
        targetMuscleGroups: const ['Chest', 'Triceps'],
        rotationOrder: 0,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        exercises: const [
          RoutineExercise(
            id: 're_1',
            routineId: 'routine_test_1',
            exerciseId: 'ex_1',
            name: 'Incline Dumbbell Press',
            targetMuscle: 'Chest',
            exerciseOrder: 0,
            setsConfiguration: [
              ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 34.0),
            ],
          ),
        ],
      );

      // Convert to Workout for WorkoutEditorScreen
      final workout = routine.toWorkout();
      expect(workout.name, 'Workout A – Chest + Triceps');
      expect(workout.exercises.length, 1);
      expect(workout.exercises.first.name, 'Incline Dumbbell Press');

      // Update Workout
      final editedWorkout = workout.copyWith(
        name: 'Workout A – Heavy Chest',
        targetMuscleGroups: 'Chest, Front Delts',
      );

      final updatedRoutine = routine.updateFromWorkout(editedWorkout);
      expect(updatedRoutine.name, 'Workout A – Heavy Chest');
      expect(updatedRoutine.targetMuscleGroups, contains('Chest'));
      expect(updatedRoutine.targetMuscleGroups, contains('Front Delts'));
    });
  });

  group('RoutineController Management Tests', () {
    test('loads initial canonical routines on initialize', () async {
      await routineController.initialize();
      expect(routineController.allRoutines.length, greaterThanOrEqualTo(4));
      expect(routineController.allRoutines[0].name, contains('Workout A'));
      expect(routineController.allRoutines[1].name, contains('Workout B'));
      expect(routineController.allRoutines[2].name, contains('Workout C'));
      expect(routineController.allRoutines[3].name, contains('Workout D'));
    });

    test('creates new routine with validation and rotation ordering', () async {
      await routineController.initialize();
      final initialCount = routineController.allRoutines.length;

      // Empty name fails
      final failed = await routineController.createRoutine(name: '   ');
      expect(failed, isNull);
      expect(routineController.lastError, contains('cannot be empty'));

      // Valid name succeeds
      final newRoutine = await routineController.createRoutine(
        name: 'Workout E – Calves & Forearms',
        description: 'Auxiliary conditioning routine',
        targetMuscleGroups: ['Calves', 'Forearms'],
      );

      expect(newRoutine, isNotNull);
      expect(newRoutine!.rotationOrder, initialCount);
      expect(routineController.allRoutines.length, initialCount + 1);
      expect(routineController.getRoutineById(newRoutine.id), isNotNull);
    });

    test('renames routine and updates description', () async {
      await routineController.initialize();
      final first = routineController.allRoutines.first;

      final success = await routineController.renameRoutine(
        first.id,
        'Renamed Upper Power',
        description: 'New custom description',
      );

      expect(success, isTrue);
      final updated = routineController.getRoutineById(first.id)!;
      expect(updated.name, 'Renamed Upper Power');
      expect(updated.description, 'New custom description');
    });

    test('deletes routine and renumbers rotation order', () async {
      await routineController.initialize();
      final countBefore = routineController.allRoutines.length;
      final target = routineController.allRoutines[1]; // Remove second routine

      final success = await routineController.deleteRoutine(target.id);
      expect(success, isTrue);
      expect(routineController.allRoutines.length, countBefore - 1);
      expect(routineController.getRoutineById(target.id), isNull);

      // Verify rotation orders are strictly consecutive starting from 0
      for (int i = 0; i < routineController.allRoutines.length; i++) {
        expect(routineController.allRoutines[i].rotationOrder, i);
      }
    });

    test('reorders routines for rotation sequencing', () async {
      await routineController.initialize();
      final firstId = routineController.allRoutines[0].id;
      final secondId = routineController.allRoutines[1].id;

      // Move first item to index 2
      final success = await routineController.reorderRoutines(0, 2);
      expect(success, isTrue);

      expect(routineController.allRoutines[0].id, secondId);
      expect(routineController.allRoutines[1].id, firstId);
    });

    test('searches routines by name, description, and muscle', () async {
      await routineController.initialize();

      final r1 = routineController.searchRoutines('Chest');
      expect(r1.length, greaterThan(0));

      final r2 = routineController.searchRoutines('Biceps');
      expect(r2.length, greaterThan(0));
    });
  });

  group('WorkoutsScreen Routine Management UI Tests', () {
    testWidgets('Renders routines and supports routine creation dialog', (tester) async {
      await routineController.initialize();
      await exerciseController.initialize();

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Routine section header
      expect(find.text('WORKOUT ROUTINES'), findsOneWidget);
      expect(find.text('NEW ROUTINE'), findsOneWidget);

      // Verify routine cards loaded
      expect(find.text('Workout A – Chest + Triceps'), findsOneWidget);
      expect(find.text('Workout B – Lats + Biceps'), findsOneWidget);

      // Verify Explore Community Splits was removed
      expect(find.text('Explore Community Splits'), findsNothing);
      expect(find.text('Create Custom Routine'), findsOneWidget);

      // Tap NEW ROUTINE button
      await tester.tap(find.text('NEW ROUTINE'));
      await tester.pumpAndSettle();

      // Modal bottom sheet opens
      expect(find.text('CREATE WORKOUT ROUTINE'), findsOneWidget);
      expect(find.text('ROUTINE NAME *'), findsOneWidget);
      expect(find.text('CREATE ROUTINE'), findsOneWidget);
    });

    testWidgets('Filters routines using search bar', (tester) async {
      await routineController.initialize();
      await exerciseController.initialize();

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Search input
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Lats');
      await tester.pumpAndSettle();

      expect(find.text('Workout B – Lats + Biceps'), findsOneWidget);
      expect(find.text('Workout A – Chest + Triceps'), findsNothing);
    });
  });

  group('DailyWorkout Model & Storage Tests', () {
    test('DailyWorkout.formatLocalDate returns standard YYYY-MM-DD', () {
      final dt = DateTime(2026, 11, 7, 15, 30, 45);
      expect(DailyWorkout.formatLocalDate(dt), '2026-11-07');
    });

    test('DailyWorkout JSON serialization and deserialization', () {
      final now = DateTime(2026, 11, 7, 8, 0);
      final record = DailyWorkout(
        id: 'dw_123',
        localDate: '2026-11-07',
        selectedRoutineId: 'routine_push',
        selectionType: DailySelectionType.suggested,
        status: DailyWorkoutStatus.planned,
        selectedAt: now,
        routineName: 'Push Hypertrophy',
        targetMuscleGroups: 'Chest, Triceps',
        exerciseCount: 5,
        totalSets: 15,
        estimatedDurationMinutes: 55,
      );

      final json = record.toJson();
      final restored = DailyWorkout.fromJson(json);

      expect(restored.id, 'dw_123');
      expect(restored.localDate, '2026-11-07');
      expect(restored.selectedRoutineId, 'routine_push');
      expect(restored.selectionType, DailySelectionType.suggested);
      expect(restored.status, DailyWorkoutStatus.planned);
      expect(restored.routineName, 'Push Hypertrophy');
      expect(restored.exerciseCount, 5);
      expect(restored.totalSets, 15);
      expect(restored.hasWorkout, true);
      expect(restored.isRest, false);
      expect(restored.isSkipped, false);
    });

    test('MockDailyWorkoutStorage preserves and loads records by localDate',
        () async {
      final record = DailyWorkout(
        id: 'dw_456',
        localDate: '2026-11-07',
        selectedRoutineId: 'routine_pull',
        selectionType: DailySelectionType.manual,
        status: DailyWorkoutStatus.planned,
        selectedAt: DateTime.now(),
      );

      await mockDailyWorkoutStorage.saveDailyWorkout(record);
      final loaded =
          await mockDailyWorkoutStorage.getDailyWorkoutForDate('2026-11-07');
      expect(loaded, isNotNull);
      expect(loaded!.selectedRoutineId, 'routine_pull');
      expect(loaded.selectionType, DailySelectionType.manual);

      final all = await mockDailyWorkoutStorage.loadDailyWorkouts();
      expect(all.length, 1);
      expect(all.containsKey('2026-11-07'), true);
    });
  });

  group('DailyWorkoutController Tests', () {
    test('hasDecisionForToday returns false when unassigned, true when decided',
        () async {
      await routineController.initialize();
      await dailyWorkoutController.initialize();
      final today = DateTime.now();

      expect(dailyWorkoutController.hasDecisionForToday(today), false);

      final routine = routineController.activeRoutines.first;
      await dailyWorkoutController.selectRoutineForToday(
        routine,
        selectionType: DailySelectionType.suggested,
        date: today,
      );

      expect(dailyWorkoutController.hasDecisionForToday(today), true);
      final dec = dailyWorkoutController.getDailyWorkoutForDate(today);
      expect(dec, isNotNull);
      expect(dec!.selectedRoutineId, routine.id);
      expect(dec.status, DailyWorkoutStatus.planned);
    });

    test('Automatic rotation suggests next routine in sequence', () async {
      await routineController.initialize();
      await dailyWorkoutController.initialize();

      final routines = routineController.activeRoutines;
      expect(routines.length, greaterThanOrEqualTo(2));

      final day1 = DateTime(2026, 11, 1);
      final day2 = DateTime(2026, 11, 2);

      // Suggestion for day1 is first routine
      final s1 = dailyWorkoutController.getSuggestedRoutine(day1);
      expect(s1, isNotNull);
      expect(s1!.id, routines.first.id);

      // Select day1 routine
      await dailyWorkoutController.selectRoutineForToday(
        routines.first,
        selectionType: DailySelectionType.suggested,
        date: day1,
      );

      // Selecting alone does not advance rotation (Rule 8 & 9)
      final sMid = dailyWorkoutController.getSuggestedRoutine(day2);
      expect(sMid!.id, routines.first.id);

      // Completing day1 workout advances rotation
      await dailyWorkoutController.markCompletedForDate(day1);

      // Day 2 suggestion should rotate to the second active routine
      final s2 = dailyWorkoutController.getSuggestedRoutine(day2);
      expect(s2, isNotNull);
      expect(s2!.id, routines[1].id);
    });

    test('selectRestDayForToday records rest day and updates schedule',
        () async {
      await dailyWorkoutController.initialize();
      await workoutController.initialize();

      final today = DateTime(2026, 11, 7);
      await dailyWorkoutController.selectRestDayForToday(date: today);

      expect(dailyWorkoutController.hasDecisionForToday(today), true);
      final dec = dailyWorkoutController.getDailyWorkoutForDate(today);
      expect(dec, isNotNull);
      expect(dec!.isRest, true);
      expect(dec.selectionType, DailySelectionType.rest);

      // Check WorkoutController was updated to Rest Day
      final schedule = workoutController.getDaySchedule(today);
      expect(schedule.type, ScheduledDayType.rest);
    });

    test('skipForToday marks decision as skipped without altering schedule',
        () async {
      await dailyWorkoutController.initialize();
      final today = DateTime(2026, 11, 7);

      await dailyWorkoutController.skipForToday(date: today);

      expect(dailyWorkoutController.hasDecisionForToday(today), true);
      final dec = dailyWorkoutController.getDailyWorkoutForDate(today);
      expect(dec, isNotNull);
      expect(dec!.isSkipped, true);
      expect(dec.selectionType, DailySelectionType.skipped);
    });

    test('Different local dates have isolated decisions', () async {
      await dailyWorkoutController.initialize();
      final day1 = DateTime(2026, 11, 7);
      final day2 = DateTime(2026, 11, 8);

      await dailyWorkoutController.skipForToday(date: day1);

      expect(dailyWorkoutController.hasDecisionForToday(day1), true);
      expect(dailyWorkoutController.hasDecisionForToday(day2), false);
    });
  });

  group('DailyWorkoutSelectionScreen UI Tests', () {
    testWidgets('Renders heading, suggested routine card, rest day, and skip',
        (tester) async {
      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      await tester.pumpWidget(
        const MaterialApp(
          home: DailyWorkoutSelectionScreen(isModal: true),
        ),
      );
      await tester.pumpAndSettle();

      // Heading
      expect(find.text('What are we training today?'), findsOneWidget);
      expect(
        find.text('Calibrate your terminal for today’s session or choose recovery.'),
        findsOneWidget,
      );

      // Suggested Routine Card & Button
      expect(find.text('CHOOSE WORKOUT'), findsOneWidget);

      // Rest Day Card
      expect(find.text('Rest & Recovery Day'), findsOneWidget);
      expect(find.text('REST DAY'), findsOneWidget);

      // Skip options
      expect(find.text('Skip for Now'), findsOneWidget);
      expect(find.text('Skip for now, take me to Home'), findsOneWidget);
    });

    testWidgets('Tapping CHOOSE WORKOUT chooses suggested routine and finishes',
        (tester) async {
      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const DailyWorkoutSelectionScreen(isModal: true),
                      settings: const RouteSettings(name: '/daily-select'),
                    ),
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open selection modal
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('CHOOSE WORKOUT'), findsOneWidget);

      // Tap choose workout
      await tester.tap(find.text('CHOOSE WORKOUT'));
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.text('What are we training today?'), findsNothing);
      expect(find.text('OPEN'), findsOneWidget);

      // Verify decision was recorded
      expect(dailyWorkoutController.hasDecisionForToday(), true);
    });

    testWidgets('Tapping REST DAY records rest and finishes', (tester) async {
      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const DailyWorkoutSelectionScreen(isModal: true),
                      settings: const RouteSettings(name: '/daily-select'),
                    ),
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open modal
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      // Tap REST DAY
      await tester.ensureVisible(find.text('REST DAY'));
      await tester.tap(find.text('REST DAY'));
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.text('What are we training today?'), findsNothing);
      expect(dailyWorkoutController.hasDecisionForToday(), true);
      final dec = dailyWorkoutController.getDailyWorkoutForDate();
      expect(dec!.isRest, true);
    });

    testWidgets('Tapping Skip for Now records skipped decision',
        (tester) async {
      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const DailyWorkoutSelectionScreen(isModal: true),
                      settings: const RouteSettings(name: '/daily-select'),
                    ),
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open modal
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      // Tap Skip for Now button in appbar
      await tester.tap(find.text('Skip for Now'));
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.text('What are we training today?'), findsNothing);
      expect(dailyWorkoutController.hasDecisionForToday(), true);
      final dec = dailyWorkoutController.getDailyWorkoutForDate();
      expect(dec!.isSkipped, true);
    });
  });

  group('WorkoutRotationEngine Tests', () {
    late WorkoutRoutine routineA;
    late WorkoutRoutine routineB;
    late WorkoutRoutine routineC;
    late WorkoutRoutine routineD;

    setUp(() {
      final now = DateTime(2026, 11, 1);
      routineA = WorkoutRoutine(
        id: 'routine_a',
        name: 'Workout A – Chest + Triceps',
        rotationOrder: 0,
        createdAt: now,
        updatedAt: now,
      );
      routineB = WorkoutRoutine(
        id: 'routine_b',
        name: 'Workout B – Lats + Biceps',
        rotationOrder: 1,
        createdAt: now,
        updatedAt: now,
      );
      routineC = WorkoutRoutine(
        id: 'routine_c',
        name: 'Workout C – Legs + Shoulders',
        rotationOrder: 2,
        createdAt: now,
        updatedAt: now,
      );
      routineD = WorkoutRoutine(
        id: 'routine_d',
        name: 'Workout D – Back + Rear Delts',
        rotationOrder: 3,
        createdAt: now,
        updatedAt: now,
      );
    });

    test('Initial recommendation suggests first active routine when no history',
        () {
      final engine = WorkoutRotationEngine();
      final activeRoutines = [routineA, routineB, routineC];

      final rec = engine.computeRecommendation(
        targetDate: DateTime(2026, 11, 2),
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: const [],
      );

      expect(rec.source, RecommendationSource.initial);
      expect(rec.routine?.id, routineA.id);
      expect(rec.hasWorkout, true);
    });

    test('Normal rotation advances A -> B -> C -> A sequentially', () {
      final engine = WorkoutRotationEngine();
      final activeRoutines = [routineA, routineB, routineC];

      // After completing A, next is B
      final history1 = [
        CompletedWorkoutSession(
          routineId: routineA.id,
          completedAt: DateTime(2026, 11, 2, 10, 0),
        ),
      ];
      final next1 = engine.computeNextRoutineInRotation(
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: history1,
      );
      expect(next1?.id, routineB.id);

      // After completing B, next is C
      final history2 = [
        CompletedWorkoutSession(
          routineId: routineB.id,
          completedAt: DateTime(2026, 11, 4, 10, 0),
        ),
        CompletedWorkoutSession(
          routineId: routineA.id,
          completedAt: DateTime(2026, 11, 2, 10, 0),
        ),
      ];
      final next2 = engine.computeNextRoutineInRotation(
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: history2,
      );
      expect(next2?.id, routineC.id);

      // After completing C, wraps back to A
      final history3 = [
        CompletedWorkoutSession(
          routineId: routineC.id,
          completedAt: DateTime(2026, 11, 6, 10, 0),
        ),
        CompletedWorkoutSession(
          routineId: routineB.id,
          completedAt: DateTime(2026, 11, 4, 10, 0),
        ),
      ];
      final next3 = engine.computeNextRoutineInRotation(
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: history3,
      );
      expect(next3?.id, routineA.id);
    });

    test('Rest Day does not advance rotation', () {
      final engine = WorkoutRotationEngine();
      final activeRoutines = [routineA, routineB, routineC];

      // Monday: Complete A
      final mondayHistory = [
        CompletedWorkoutSession(
          routineId: routineA.id,
          completedAt: DateTime(2026, 11, 2, 10, 0),
        ),
      ];

      // Tuesday: Rest Day selected
      final tuesdayDecision = DailyWorkout(
        id: 'dw_tues',
        localDate: '2026-11-03',
        selectionType: DailySelectionType.rest,
        status: DailyWorkoutStatus.rest,
        selectedAt: DateTime(2026, 11, 3, 8, 0),
      );

      final tuesdayRec = engine.computeRecommendation(
        targetDate: DateTime(2026, 11, 3),
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: mondayHistory,
        todayDecision: tuesdayDecision,
      );
      expect(tuesdayRec.isRestDay, true);

      // Wednesday: Next suggestion remains Workout B
      final wednesdayRec = engine.computeRecommendation(
        targetDate: DateTime(2026, 11, 4),
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: mondayHistory,
      );
      expect(wednesdayRec.source, RecommendationSource.rotation);
      expect(wednesdayRec.routine?.id, routineB.id);
    });

    test('Skipped Day does not advance rotation', () {
      final engine = WorkoutRotationEngine();
      final activeRoutines = [routineA, routineB, routineC];

      // Monday: Complete A
      final mondayHistory = [
        CompletedWorkoutSession(
          routineId: routineA.id,
          completedAt: DateTime(2026, 11, 2, 10, 0),
        ),
      ];

      // Tuesday: Skipped for now
      final tuesdayDecision = DailyWorkout(
        id: 'dw_tues_skip',
        localDate: '2026-11-03',
        selectionType: DailySelectionType.skipped,
        status: DailyWorkoutStatus.skipped,
        selectedAt: DateTime(2026, 11, 3, 8, 0),
      );

      final tuesdayRec = engine.computeRecommendation(
        targetDate: DateTime(2026, 11, 3),
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: mondayHistory,
        todayDecision: tuesdayDecision,
      );
      expect(tuesdayRec.isSkipped, true);

      // Wednesday: Next suggestion remains Workout B
      final wednesdayRec = engine.computeRecommendation(
        targetDate: DateTime(2026, 11, 4),
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: mondayHistory,
      );
      expect(wednesdayRec.routine?.id, routineB.id);
    });

    test('Manual override completed session advances rotation from the manual routine',
        () {
      final engine = WorkoutRotationEngine();
      final activeRoutines = [routineA, routineB, routineC, routineD];

      // User manually chose Workout C on Monday and completed it
      final history = [
        CompletedWorkoutSession(
          routineId: routineC.id,
          completedAt: DateTime(2026, 11, 2, 10, 0),
        ),
      ];

      // Next suggestion should follow the configured rotation after C -> Workout D
      final next = engine.computeNextRoutineInRotation(
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: history,
      );
      expect(next?.id, routineD.id);
    });

    test('Routine deletion gracefully falls back to previous valid session or first routine',
        () {
      final engine = WorkoutRotationEngine();

      // History has completed deleted routine 'deleted_x', preceded by routineA
      final historyWithPrior = [
        CompletedWorkoutSession(
          routineId: 'deleted_x',
          completedAt: DateTime(2026, 11, 4, 10, 0),
        ),
        CompletedWorkoutSession(
          routineId: routineA.id,
          completedAt: DateTime(2026, 11, 2, 10, 0),
        ),
      ];

      final activeRoutines = [routineA, routineB, routineC];

      // Since deleted_x is missing, advances from routineA -> routineB
      final next = engine.computeNextRoutineInRotation(
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: historyWithPrior,
      );
      expect(next?.id, routineB.id);

      // When no prior session matches active routines, safely falls back to first active
      final historyOnlyMissing = [
        CompletedWorkoutSession(
          routineId: 'completely_unknown_id',
          completedAt: DateTime(2026, 11, 4, 10, 0),
        ),
      ];
      final fallback = engine.computeNextRoutineInRotation(
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: historyOnlyMissing,
      );
      expect(fallback?.id, routineA.id);
    });

    test('Routine reordering immediately updates next suggestion based on new sequence',
        () {
      final engine = WorkoutRotationEngine();

      // Original order: [A, B, C]. Completed A -> next is B.
      final history = [
        CompletedWorkoutSession(
          routineId: routineA.id,
          completedAt: DateTime(2026, 11, 2, 10, 0),
        ),
      ];

      // Reordered routines to: [A, C, B]
      final reordered = [
        routineA.copyWith(rotationOrder: 0),
        routineC.copyWith(rotationOrder: 1),
        routineB.copyWith(rotationOrder: 2),
      ];

      final next = engine.computeNextRoutineInRotation(
        activeRoutines: reordered,
        allRoutines: reordered,
        completedHistory: history,
      );
      // In the new order, C immediately follows A
      expect(next?.id, routineC.id);
    });

    test('Inactive routines are skipped in rotation sequence', () {
      final engine = WorkoutRotationEngine();

      // Routine B is inactive
      final inactiveB = routineB.copyWith(isActive: false);
      final activeRoutines = [routineA, routineC];
      final allRoutines = [routineA, inactiveB, routineC];

      // Completed A -> skips inactive B and suggests C
      final history = [
        CompletedWorkoutSession(
          routineId: routineA.id,
          completedAt: DateTime(2026, 11, 2, 10, 0),
        ),
      ];

      final next = engine.computeNextRoutineInRotation(
        activeRoutines: activeRoutines,
        allRoutines: allRoutines,
        completedHistory: history,
      );
      expect(next?.id, routineC.id);

      // If inactive B was completed before being disabled, advances to next active (C)
      final historyB = [
        CompletedWorkoutSession(
          routineId: inactiveB.id,
          completedAt: DateTime(2026, 11, 3, 10, 0),
        ),
      ];
      final nextAfterB = engine.computeNextRoutineInRotation(
        activeRoutines: activeRoutines,
        allRoutines: allRoutines,
        completedHistory: historyB,
      );
      expect(nextAfterB?.id, routineC.id);
    });

    test('Multiple completed sessions on the same day uses latest completion',
        () {
      final engine = WorkoutRotationEngine();
      final activeRoutines = [routineA, routineB, routineC, routineD];

      // Monday morning: Complete A (10:00 AM)
      // Monday evening: Complete B (6:00 PM)
      final history = [
        CompletedWorkoutSession(
          routineId: routineA.id,
          completedAt: DateTime(2026, 11, 2, 10, 0),
        ),
        CompletedWorkoutSession(
          routineId: routineB.id,
          completedAt: DateTime(2026, 11, 2, 18, 0),
        ),
      ];

      // Engine sorts by timestamp descending: B is latest, so next is C
      final next = engine.computeNextRoutineInRotation(
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: history,
      );
      expect(next?.id, routineC.id);
    });

    test('Scheduled routine for today is presented as scheduled without altering rotation',
        () {
      final engine = WorkoutRotationEngine();
      final activeRoutines = [routineA, routineB, routineC];

      // Routine C scheduled on calendar for today
      final schedule = DaySchedule(
        date: DateTime(2026, 11, 7),
        type: ScheduledDayType.workout,
        workoutId: routineC.id,
      );

      final rec = engine.computeRecommendation(
        targetDate: DateTime(2026, 11, 7),
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: const [],
        todaySchedule: schedule,
      );

      expect(rec.source, RecommendationSource.scheduled);
      expect(rec.routine?.id, routineC.id);
      expect(rec.isScheduled, true);
    });

    test('Restores today decision when already selected or completed', () {
      final engine = WorkoutRotationEngine();
      final activeRoutines = [routineA, routineB, routineC];

      final todayDecision = DailyWorkout(
        id: 'dw_today',
        localDate: '2026-11-07',
        selectedRoutineId: routineB.id,
        selectionType: DailySelectionType.suggested,
        status: DailyWorkoutStatus.completed,
        selectedAt: DateTime(2026, 11, 7, 8, 0),
        completedAt: DateTime(2026, 11, 7, 9, 30),
      );

      final rec = engine.computeRecommendation(
        targetDate: DateTime(2026, 11, 7),
        activeRoutines: activeRoutines,
        allRoutines: activeRoutines,
        completedHistory: const [],
        todayDecision: todayDecision,
      );

      expect(rec.source, RecommendationSource.todaySelection);
      expect(rec.routine?.id, routineB.id);
      expect(rec.isCompleted, true);
    });

    test('Live app integration: markWorkoutCompleted advances DailyWorkoutController suggestion',
        () async {
      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      final routines = routineController.activeRoutines;
      expect(routines.length, greaterThanOrEqualTo(2));

      final today = DateTime(2026, 11, 7);
      final tomorrow = DateTime(2026, 11, 8);

      // Select first routine for today
      await dailyWorkoutController.selectRoutineForToday(
        routines.first,
        selectionType: DailySelectionType.suggested,
        date: today,
      );

      // Complete workout for today
      await workoutController.markWorkoutCompleted(today, true);

      // Tomorrow's suggestion should advance to the second active routine
      final tomorrowSuggested =
          dailyWorkoutController.getSuggestedRoutine(tomorrow);
      expect(tomorrowSuggested, isNotNull);
      expect(tomorrowSuggested!.id, routines[1].id);
    });
  });

  group('Weekly Schedule and Home Dashboard Integration Tests', () {
    test('Weekly routine and rest-day assignments persist and resolve',
        () async {
      await routineController.initialize();
      await workoutController.initialize();

      // Assign Routine C to Monday (1)
      await workoutController.assignRoutineToWeekday(1, 'routine_c_legs');
      // Assign Rest Day to Wednesday (3)
      await workoutController.setWeekdayAsRest(3);

      final monAssign = workoutController.getWeeklyAssignment(1);
      expect(monAssign.isWorkout, true);
      expect(monAssign.routineId, 'routine_c_legs');

      final wedAssign = workoutController.getWeeklyAssignment(3);
      expect(wedAssign.isRest, true);

      // Verify date resolution for a Monday and Wednesday
      final monday = DateTime(2026, 11, 2); // Mon
      final wednesday = DateTime(2026, 11, 4); // Wed

      final monSchedule = workoutController.getDaySchedule(monday);
      expect(monSchedule.type, ScheduledDayType.workout);
      expect(monSchedule.workoutId, 'routine_c_legs');

      final wedSchedule = workoutController.getDaySchedule(wednesday);
      expect(wedSchedule.type, ScheduledDayType.rest);
    });

    test(
        'Daily override overrides specific date without modifying recurring schedule',
        () async {
      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      // Weekly schedule: Monday is assigned Routine A
      await workoutController.assignRoutineToWeekday(1, 'routine_a_push');

      final mon1 = DateTime(2026, 11, 2); // Monday
      final mon2 = DateTime(2026, 11, 9); // Next Monday

      // Override mon1 with Routine B
      final routineB = routineController.getRoutineById('routine_b_pull')!;
      await dailyWorkoutController.selectRoutineForToday(
        routineB,
        selectionType: DailySelectionType.manual,
        date: mon1,
      );

      // mon1 resolves to Routine B (Priority 1: Daily Override)
      final schedule1 = workoutController.getDaySchedule(mon1);
      expect(schedule1.workoutId, 'routine_b_pull');

      // Weekly plan remains Routine A for all Mondays
      final recurring = workoutController.getWeeklyAssignment(1);
      expect(recurring.routineId, 'routine_a_push');

      // mon2 resolves to Routine A (Priority 2: Recurring Schedule)
      final schedule2 = workoutController.getDaySchedule(mon2);
      expect(schedule2.workoutId, 'routine_a_push');
    });

    test(
        'Shared routine across weekdays updates all future uses when template is edited',
        () async {
      await routineController.initialize();
      await workoutController.initialize();

      // Assign Routine A to Monday (1) and Friday (5)
      await workoutController.assignRoutineToWeekday(1, 'routine_a_push');
      await workoutController.assignRoutineToWeekday(5, 'routine_a_push');

      // Edit template routine A
      final routineA = routineController.getRoutineById('routine_a_push')!;
      final updatedWorkout = routineA.toWorkout().copyWith(
            name: 'Push Max Power',
            targetMuscleGroups: 'Chest, Triceps, Delts',
          );
      await routineController.updateRoutineFromWorkout(updatedWorkout);

      // Monday and Friday both resolve to the updated template name
      final mon = DateTime(2026, 11, 2);
      final fri = DateTime(2026, 11, 6);

      final monWorkout = workoutController.getWorkoutForDate(mon);
      final friWorkout = workoutController.getWorkoutForDate(fri);

      expect(monWorkout?.name, 'Push Max Power');
      expect(friWorkout?.name, 'Push Max Power');
    });

    test(
        'Completed historical session retains completed status even after template edit',
        () async {
      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      final pastDate = DateTime(2026, 10, 26);
      final routineA = routineController.getRoutineById('routine_a_push')!;

      // Mark pastDate completed
      await dailyWorkoutController.selectRoutineForToday(
        routineA,
        selectionType: DailySelectionType.suggested,
        date: pastDate,
      );
      await workoutController.markWorkoutCompleted(pastDate, true);

      // Verify completed status
      var pastSchedule = workoutController.getDaySchedule(pastDate);
      expect(pastSchedule.isCompleted, true);

      // Edit template routine
      final updatedWorkout = routineA.toWorkout().copyWith(name: 'Chest Heavy');
      await routineController.updateRoutineFromWorkout(updatedWorkout);

      // Historical completed session still marked completed
      pastSchedule = workoutController.getDaySchedule(pastDate);
      expect(pastSchedule.isCompleted, true);
    });

    test('Weekly plan persists across controller re-initialization', () async {
      await workoutController.initialize();

      // Modify assignments
      await workoutController.assignRoutineToWeekday(2, 'routine_c_legs');
      await workoutController.setWeekdayAsRest(4);
      await workoutController.removeWeekdayAssignment(6);

      // Simulate app restart with fresh controller
      final restartedController =
          WorkoutController(storage: mockWorkoutStorage);
      await restartedController.initialize();

      expect(restartedController.getWeeklyAssignment(2).routineId,
          'routine_c_legs');
      expect(restartedController.getWeeklyAssignment(4).isRest, true);
      expect(restartedController.getWeeklyAssignment(6).isUnassigned, true);
    });

    testWidgets('Home Dashboard renders calendar, displays effective workout and updates on date selection',
        (tester) async {
      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      // Assign Monday to Routine A
      await workoutController.assignRoutineToWeekday(1, 'routine_a_push');
      // Assign Tuesday to Routine B
      await workoutController.assignRoutineToWeekday(2, 'routine_b_pull');

      final weekDays = workoutController.daysOfViewingWeek;
      final monday = weekDays[0];
      final tuesday = weekDays[1];

      workoutController.selectDate(monday);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Home Header
      expect(find.text('Home'), findsOneWidget);

      // Verify Routine name from effective workout
      expect(find.text('Workout A – Chest + Triceps'), findsWidgets);

      // Select Tuesday on calendar strip
      workoutController.selectDate(tuesday);
      await tester.pumpAndSettle();

      // Verify effective workout updated to Workout B
      expect(find.text('Workout B – Lats + Biceps'), findsWidgets);
    });

    testWidgets('ScheduleScreen renders monthly calendar, displays unassigned date state and save button',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await workoutController.clearDateAssignment(today);
      workoutHistoryController.clearHistory();

      await tester.pumpWidget(
        const MaterialApp(
          home: ScheduleScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Schedule Header
      expect(find.text('Schedule'), findsOneWidget);

      // Verify Weekday labels
      expect(find.text('MON'), findsOneWidget);
      expect(find.text('TUE'), findsOneWidget);
      expect(find.text('WED'), findsOneWidget);
      expect(find.text('THU'), findsOneWidget);
      expect(find.text('FRI'), findsOneWidget);
      expect(find.text('SAT'), findsOneWidget);
      expect(find.text('SUN'), findsOneWidget);

      // Unassigned date shows "No workout assigned"
      expect(find.text('No workout assigned'), findsOneWidget);
      expect(find.text('ASSIGN WORKOUT'), findsOneWidget);

      // Save button initially shows disabled state
      expect(find.text('NO PENDING CHANGES'), findsOneWidget);
    });

    testWidgets('ScheduleScreen assigning routine sets pending state and persists upon tapping Save',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final futureDate = today.add(const Duration(days: 3));

      await workoutController.clearDateAssignment(futureDate);
      await workoutController.clearDateAssignment(today);
      workoutHistoryController.clearHistory();

      await tester.pumpWidget(
        const MaterialApp(
          home: ScheduleScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select future date in calendar
      final dayFinder = find.text('${futureDate.day}');
      expect(dayFinder, findsWidgets);
      await tester.tap(dayFinder.first);
      await tester.pumpAndSettle();

      // Tap ASSIGN WORKOUT
      expect(find.text('ASSIGN WORKOUT'), findsOneWidget);
      await tester.tap(find.text('ASSIGN WORKOUT'));
      await tester.pumpAndSettle();

      // Bottom sheet is visible with Rest Day and available routines
      expect(find.text('Rest Day'), findsOneWidget);
      expect(find.text('AVAILABLE ROUTINES'), findsOneWidget);
      expect(find.text('Workout A – Chest + Triceps'), findsOneWidget);

      // Select Routine A
      await tester.tap(find.text('Workout A – Chest + Triceps'));
      await tester.pumpAndSettle();

      // Details panel now reflects pending workout and shows PENDING SAVE badge
      expect(find.text('Workout A – Chest + Triceps'), findsOneWidget);
      expect(find.text('PENDING SAVE'), findsOneWidget);

      // SAVE SCHEDULE button is now active
      expect(find.text('SAVE SCHEDULE'), findsOneWidget);

      // Tap SAVE SCHEDULE
      await tester.tap(find.text('SAVE SCHEDULE'));
      await tester.pumpAndSettle();

      // Schedule is persisted in controller
      final savedSchedule = workoutController.getDaySchedule(futureDate);
      expect(savedSchedule.type, ScheduledDayType.workout);
      expect(savedSchedule.workoutId, 'routine_a_push');

      // Pending badge disappears
      expect(find.text('PENDING SAVE'), findsNothing);
    });

    testWidgets('ScheduleScreen assigning Rest Day and saving persists Rest Day',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final futureDate = today.add(const Duration(days: 4));

      await workoutController.clearDateAssignment(futureDate);
      await workoutController.clearDateAssignment(today);
      workoutHistoryController.clearHistory();

      await tester.pumpWidget(
        const MaterialApp(
          home: ScheduleScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select futureDate
      final dayFinder = find.text('${futureDate.day}');
      await tester.tap(dayFinder.first);
      await tester.pumpAndSettle();

      // Tap ASSIGN WORKOUT
      await tester.tap(find.text('ASSIGN WORKOUT'));
      await tester.pumpAndSettle();

      // Tap Rest Day in bottom sheet
      await tester.tap(find.text('Rest Day'));
      await tester.pumpAndSettle();

      // Panel reflects pending Rest Day
      expect(find.text('PENDING SAVE'), findsOneWidget);
      expect(find.text('Rest Day'), findsWidgets);

      // Save
      await tester.tap(find.text('SAVE SCHEDULE'));
      await tester.pumpAndSettle();

      final saved = workoutController.getDaySchedule(futureDate);
      expect(saved.type, ScheduledDayType.rest);
    });

    testWidgets('ScheduleScreen clearing assignment reverts date to unassigned',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final futureDate = today.add(const Duration(days: 5));

      // Pre-assign Routine B
      await workoutController.assignRoutineToDate(futureDate, 'routine_b_pull');

      await tester.pumpWidget(
        const MaterialApp(
          home: ScheduleScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select futureDate
      final dayFinder = find.text('${futureDate.day}');
      await tester.tap(dayFinder.first);
      await tester.pumpAndSettle();

      // Panel displays Workout B and CLEAR button
      expect(find.text('Workout B – Lats + Biceps'), findsOneWidget);
      expect(find.text('CLEAR'), findsOneWidget);

      // Tap CLEAR
      await tester.tap(find.text('CLEAR'));
      await tester.pumpAndSettle();

      // Panel now shows pending unassigned state
      expect(find.text('No workout assigned'), findsOneWidget);
      expect(find.text('PENDING SAVE'), findsOneWidget);

      // Tap SAVE SCHEDULE
      await tester.tap(find.text('SAVE SCHEDULE'));
      await tester.pumpAndSettle();

      // Persisted state is unassigned
      final saved = workoutController.getDaySchedule(futureDate);
      expect(saved.type, ScheduledDayType.unassigned);
    });

    testWidgets('ScheduleScreen past dates are strictly read-only',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await routineController.initialize();
      await workoutController.initialize();
      await dailyWorkoutController.initialize();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final pastDate = today.subtract(const Duration(days: 2));

      await tester.pumpWidget(
        const MaterialApp(
          home: ScheduleScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select past date
      final dayFinder = find.text('${pastDate.day}');
      await tester.tap(dayFinder.first);
      await tester.pumpAndSettle();

      // Read-only badge is present
      expect(find.text('PAST // READ ONLY'), findsOneWidget);

      // Editable action buttons are NOT present
      expect(find.text('ASSIGN WORKOUT'), findsNothing);
      expect(find.text('CHANGE'), findsNothing);
      expect(find.text('CLEAR'), findsNothing);
    });

    test('Routine deletion unassigns future scheduled dates while preserving history',
        () async {
      await routineController.initialize();
      await workoutController.initialize();
      await workoutHistoryController.initialize();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final futureDate = today.add(const Duration(days: 7));
      final pastDate = today.subtract(const Duration(days: 5));

      // 1. Assign routine_c_legs to futureDate
      await workoutController.assignRoutineToDate(futureDate, 'routine_c_legs');

      // 2. Record completed session in history for routine_c_legs on pastDate
      await workoutHistoryController.recordCompletedSession(
        date: pastDate,
        routineId: 'routine_c_legs',
        routineName: 'Workout C – Quads + Hamstrings',
      );

      expect(workoutController.getDaySchedule(futureDate).workoutId,
          'routine_c_legs');
      expect(workoutHistoryController.totalCompletedCount, greaterThanOrEqualTo(1));

      // 3. Delete routine_c_legs from RoutineController
      await routineController.deleteRoutine('routine_c_legs');

      // 4. Future schedule is cleanly unassigned
      final updatedFuture = workoutController.getDaySchedule(futureDate);
      expect(updatedFuture.type, ScheduledDayType.unassigned);
      expect(updatedFuture.workoutId, isNull);

      // 5. Past completed history is strictly preserved
      final pastSessions =
          workoutHistoryController.getSessionsForDate(pastDate);
      expect(pastSessions.isNotEmpty, true);
      expect(pastSessions.first.routineId, 'routine_c_legs');
    });
  });

  group('Complete Removal of Rest Timer Functionality Verification', () {
    test('WorkoutExercise serialization completely omits restSeconds and safely ignores legacy restSeconds', () {
      const ex = WorkoutExercise(
        id: 'ex_timer_free',
        name: 'Incline Bench Press',
        targetMuscle: 'Chest',
        sets: 4,
        reps: 10,
        weightKg: 40.0,
      );

      final json = ex.toJson();
      expect(json.containsKey('restSeconds'), isFalse);

      // Deserialization of legacy JSON containing obsolete restSeconds
      final legacyJson = {
        'id': 'ex_legacy_1',
        'name': 'Incline Bench Press',
        'targetMuscle': 'Chest',
        'sets': 4,
        'reps': 10,
        'weightKg': 40.0,
        'restSeconds': 90,
      };

      final restored = WorkoutExercise.fromJson(legacyJson);
      expect(restored.id, 'ex_legacy_1');
      expect(restored.name, 'Incline Bench Press');
      expect(restored.effectiveSetConfigs.length, 4);
    });

    test('RoutineExercise serialization completely omits restDuration and safely ignores legacy restDuration', () {
      const routineEx = RoutineExercise(
        id: 're_timer_free',
        routineId: 'routine_1',
        exerciseId: 'ex_1',
        name: 'Barbell Squat',
        targetMuscle: 'Legs',
        exerciseOrder: 0,
      );

      final json = routineEx.toJson();
      expect(json.containsKey('restDuration'), isFalse);

      // Deserialization of legacy JSON containing obsolete restDuration
      final legacyJson = {
        'id': 're_legacy_1',
        'routineId': 'routine_1',
        'exerciseId': 'ex_1',
        'name': 'Barbell Squat',
        'targetMuscle': 'Legs',
        'exerciseOrder': 0,
        'restDuration': 120,
      };

      final restored = RoutineExercise.fromJson(legacyJson);
      expect(restored.id, 're_legacy_1');
      expect(restored.name, 'Barbell Squat');
      expect(restored.effectiveSets.length, 3);
    });

    testWidgets('ActiveWorkoutScreen has no rest countdown bar and allows immediate set completion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveWorkoutScreen(
            workoutTitle: 'Push Power Session',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure NO rest timer bar exists on screen
      expect(find.text('REST INTERVAL'), findsNothing);
      expect(find.text('+30s'), findsNothing);
      expect(find.textContaining('Remaining'), findsNothing);

      // Complete Set 3 by tapping its checkbox
      final setCheckboxes = find.byType(Checkbox);
      if (setCheckboxes.evaluate().isNotEmpty) {
        await tester.tap(setCheckboxes.at(2));
        await tester.pumpAndSettle();
      }

      // Verify that completing set 3 does NOT trigger a rest countdown bar or popup
      expect(find.text('REST INTERVAL'), findsNothing);
      expect(find.text('+30s'), findsNothing);
      expect(find.textContaining('Remaining'), findsNothing);
    });

    testWidgets('ActiveWorkoutScreen elapsed time starts at 00:00', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ActiveWorkoutScreen(
            workoutTitle: 'Chest & Triceps Hypertrophy',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure elapsed stopwatch displays 00:00 at startup
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('ActiveWorkoutScreen initially shows no logged sets and displays progression upon logging', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ActiveWorkoutScreen(
            workoutTitle: 'Back + Rear Delts',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At initial, no set has logged and SET LOG PROGRESSION is kept to nothing
      expect(find.text('SET LOG PROGRESSION'), findsNothing);

      // Tap LOG NEXT SET
      final logSetBtn = find.text('LOG NEXT SET');
      expect(logSetBtn, findsOneWidget);
      await tester.tap(logSetBtn);
      await tester.pumpAndSettle();

      // Now SET LOG PROGRESSION appears with Set 1
      expect(find.text('SET LOG PROGRESSION'), findsOneWidget);
      expect(find.text('34 kg × 10 reps'), findsOneWidget);
    });

    testWidgets('ActiveWorkoutScreen routes to next exercise in sequence upon tapping UP NEXT IN SEQUENCE', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final workout = Workout(
        id: 'test_seq_workout',
        name: 'Workout D — Back + Rear Delts',
        targetMuscleGroups: 'Back • Rear Delts',
        estimatedDurationMinutes: 45,
        exercises: const [
          WorkoutExercise(
            id: 'ex_1',
            name: 'Incline Dumbbell Bench Press',
            targetMuscle: 'Upper Pecs',
            sets: 3,
            reps: 10,
            weightKg: 34.0,
          ),
          WorkoutExercise(
            id: 'ex_2',
            name: 'Weighted Tricep Dips',
            targetMuscle: 'Triceps',
            sets: 3,
            reps: 10,
            weightKg: 20.0,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveWorkoutScreen(
            workout: workout,
            workoutTitle: workout.name,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check initial exercise
      expect(find.text('Incline Dumbbell Bench Press'), findsOneWidget);
      expect(find.text('EXERCISE 01 OF 02'), findsOneWidget);

      // Log set for Exercise 1
      await tester.tap(find.text('LOG NEXT SET'));
      await tester.pumpAndSettle();
      expect(find.text('34 kg × 10 reps'), findsOneWidget);

      // Verify UP NEXT IN SEQUENCE shows Weighted Tricep Dips
      expect(find.textContaining('Weighted Tricep Dips'), findsOneWidget);

      // Tap UP NEXT IN SEQUENCE card to advance
      await tester.tap(find.textContaining('Weighted Tricep Dips'));
      await tester.pumpAndSettle();

      // Verify routed to next exercise
      expect(find.text('Weighted Tricep Dips'), findsOneWidget);
      expect(find.text('EXERCISE 02 OF 02'), findsOneWidget);

      // Set log progression for Exercise 2 is initially empty (nothing until logged)
      expect(find.text('SET LOG PROGRESSION'), findsNothing);

      // Log set for Exercise 2
      await tester.tap(find.text('LOG NEXT SET'));
      await tester.pumpAndSettle();
      expect(find.text('SET LOG PROGRESSION'), findsOneWidget);
      expect(find.text('20 kg × 10 reps'), findsOneWidget);
    });

    testWidgets('ActiveWorkoutScreen wires actual performed sets to completion snapshot and daily analytics', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Workout? completedResult;
      final workout = Workout(
        id: 'test_live_workout',
        name: 'Workout D — Back + Rear Delts',
        targetMuscleGroups: 'Back • Rear Delts',
        estimatedDurationMinutes: 45,
        exercises: const [
          WorkoutExercise(
            id: 'ex_1',
            name: 'Barbell Bent-Over Row',
            targetMuscle: 'Back',
            sets: 3,
            reps: 10,
            weightKg: 70.0,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveWorkoutScreen(
            workout: workout,
            workoutTitle: workout.name,
            onFinishWithData: (completed) {
              completedResult = completed;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Log set 1 (70kg x 10)
      await tester.tap(find.text('LOG NEXT SET'));
      await tester.pumpAndSettle();

      // Tap + on weight stepper (+2kg -> 72kg)
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('LOG NEXT SET'));
      await tester.pumpAndSettle();

      // Finish workout
      await tester.tap(find.text('FINISH').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('SAVE TO PERFORMANCE ARCHIVE'));
      await tester.pumpAndSettle();

      expect(completedResult, isNotNull);
      expect(completedResult!.exercises.first.effectiveSetConfigs.length, 2);
      expect(completedResult!.exercises.first.effectiveSetConfigs[0].weightKg, 70.0);
      expect(completedResult!.exercises.first.effectiveSetConfigs[1].weightKg, 72.0);
    });

    test('WorkoutController.updateWorkoutForDate successfully saves modifications and preserves custom workout', () async {
      final testDate = DateTime(2026, 11, 8);
      final initialWorkout = WorkoutController.instance.getWorkoutForDate(testDate) ??
          const Workout(
            id: 'test_workout_nov8',
            name: 'Original Workout',
            targetMuscleGroups: 'Chest',
            estimatedDurationMinutes: 45,
            exercises: [],
          );

      final modifiedWorkout = initialWorkout.copyWith(
        name: 'Nov 8 Modified Chest Session',
        targetMuscleGroups: 'Chest & Core',
        exercises: [
          const WorkoutExercise(
            id: 'mod_ex_1',
            name: 'Incline Dumbbell Bench Press',
            targetMuscle: 'Chest',
            sets: 4,
            reps: 10,
            weightKg: 34.0,
            order: 0,
            setConfigs: [
              ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 34.0),
              ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 34.0),
              ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 36.0),
              ExerciseSetConfig(setNumber: 4, reps: 8, weightKg: 36.0),
            ],
          ),
        ],
      );

      final success = await WorkoutController.instance.updateWorkoutForDate(testDate, modifiedWorkout);
      expect(success, isTrue);

      final loadedWorkout = WorkoutController.instance.getWorkoutForDate(testDate);
      expect(loadedWorkout, isNotNull);
      expect(loadedWorkout!.name, 'Nov 8 Modified Chest Session');
      expect(loadedWorkout.exercises.length, 1);
      expect(loadedWorkout.exercises.first.name, 'Incline Dumbbell Bench Press');
      expect(loadedWorkout.exercises.first.effectiveSetConfigs.length, 4);
    });

    testWidgets('Tapping ASSIGN WORKOUT on Home unassigned card opens DailyWorkoutSelectionScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Mark unassigned day on test date
      final unassignedDate = DateTime(2026, 12, 1);
      await WorkoutController.instance.setDayType(unassignedDate, ScheduledDayType.unassigned);
      WorkoutController.instance.selectDate(unassignedDate);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final assignBtn = find.text('ASSIGN WORKOUT');
      expect(assignBtn, findsOneWidget);

      await tester.tap(assignBtn);
      await tester.pumpAndSettle();

      // Verify routed to DailyWorkoutSelectionScreen
      expect(find.byType(DailyWorkoutSelectionScreen), findsOneWidget);
      expect(find.textContaining('What are we training'), findsOneWidget);
    });

    test('WorkoutHistoryController records and calculates session metrics accurately', () async {
      final testWorkout = Workout(
        id: 'test_routine_push',
        name: 'Push Strength Focus',
        targetMuscleGroups: 'Chest, Triceps, Shoulders',
        estimatedDurationMinutes: 45,
        exercises: [
          const WorkoutExercise(
            id: 'we_1',
            name: 'Incline Dumbbell Bench Press',
            targetMuscle: 'Chest',
            setConfigs: [
              ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 34.0),
              ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 34.0),
              ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 36.0),
              ExerciseSetConfig(setNumber: 4, reps: 8, weightKg: 36.0),
            ],
          ),
          const WorkoutExercise(
            id: 'we_2',
            name: 'Weighted Tricep Dips',
            targetMuscle: 'Triceps',
            setConfigs: [
              ExerciseSetConfig(setNumber: 1, reps: 12, weightKg: 16.0),
              ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 20.0),
            ],
          ),
        ],
      );

      final date = DateTime(2026, 11, 8);
      await WorkoutHistoryController.instance.recordCompletedSession(
        date: date,
        routineId: testWorkout.id,
        routineName: testWorkout.name,
        targetMuscleGroups: testWorkout.targetMuscleGroups,
        workoutSnapshot: testWorkout,
        completedAt: date,
      );

      final sessions = WorkoutHistoryController.instance.getSessionsForDate(date);
      expect(sessions.isNotEmpty, isTrue);
      final session = sessions.first;
      expect(session.routineName, 'Push Strength Focus');
      expect(session.calculatedExercisesCount, 2);
      expect(session.calculatedTotalSets, 6);
      expect(session.calculatedTotalReps, 58);
      expect(session.calculatedVolumeKg, 1648.0);
    });

    testWidgets('DailyAnalyticsScreen displays workout summary, exercise breakdown, and muscle groups', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testWorkout = Workout(
        id: 'test_hypertrophy',
        name: 'Chest & Triceps Hypertrophy',
        targetMuscleGroups: 'Chest • Triceps',
        estimatedDurationMinutes: 50,
        exercises: [
          const WorkoutExercise(
            id: 'ex_1',
            name: 'Incline Dumbbell Bench Press',
            targetMuscle: 'Chest',
            setConfigs: [
              ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 34.0),
              ExerciseSetConfig(setNumber: 2, reps: 8, weightKg: 36.0),
            ],
          ),
          const WorkoutExercise(
            id: 'ex_2',
            name: 'Bodyweight Dips',
            targetMuscle: 'Triceps',
            setConfigs: [
              ExerciseSetConfig(setNumber: 1, reps: 12, weightKg: 0.0),
            ],
          ),
        ],
      );

      final session = CompletedWorkoutSession(
        routineId: 'test_hypertrophy',
        completedAt: DateTime(2026, 11, 8),
        routineName: testWorkout.name,
        targetMuscleGroups: testWorkout.targetMuscleGroups,
        workoutSnapshot: testWorkout,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DailyAnalyticsScreen(session: session),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Header
      expect(find.text('DAILY ANALYTICS'), findsOneWidget);
      expect(find.text('Chest & Triceps Hypertrophy'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);

      // Section A: 4 Summary Cards
      expect(find.text('EXERCISES'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('TOTAL SETS'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('TOTAL REPS'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
      expect(find.text('628 kg'), findsOneWidget);

      // Section B: Exercise Performance List
      expect(find.text('EXERCISE PERFORMANCE'), findsOneWidget);
      expect(find.text('Incline Dumbbell Bench Press'), findsOneWidget);
      expect(find.text('Bodyweight Dips'), findsOneWidget);
      expect(find.text('Set 1 — 34 kg × 10 reps'), findsOneWidget);
      expect(find.text('Set 2 — 36 kg × 8 reps'), findsOneWidget);
      expect(find.text('Set 1 — Bodyweight × 12 reps'), findsOneWidget);

      // Section C: Muscle Groups Trained
      expect(find.text('MUSCLE GROUPS TRAINED'), findsOneWidget);
      expect(find.text('Chest'), findsWidgets);
      expect(find.text('Triceps'), findsWidgets);
    });

    testWidgets('HistoryScreen displays compact monthly calendar, indicators, and navigates to Daily Analytics', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testDate = DateTime(2026, 11, 8);
      final testWorkout = Workout(
        id: 'test_rot_a',
        name: 'Workout A — Chest & Triceps',
        targetMuscleGroups: 'Chest • Triceps',
        estimatedDurationMinutes: 45,
        exercises: [
          const WorkoutExercise(
            id: 'e1',
            name: 'Incline Bench Press',
            targetMuscle: 'Chest',
            setConfigs: [
              ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 34.0),
            ],
          ),
        ],
      );

      await WorkoutHistoryController.instance.recordCompletedSession(
        date: testDate,
        routineId: testWorkout.id,
        routineName: testWorkout.name,
        targetMuscleGroups: testWorkout.targetMuscleGroups,
        workoutSnapshot: testWorkout,
        completedAt: testDate,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Calendar presence & title
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Rest Day'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);

      // Workout History list section
      expect(find.text('WORKOUT HISTORY'), findsOneWidget);
      expect(find.text('Workout A — Chest & Triceps'), findsOneWidget);
      expect(find.text('1 Exercises'), findsOneWidget);
      expect(find.text('1 Sets'), findsOneWidget);

      // Tapping workout history item opens Daily Analytics
      final historyCard = find.text('Workout A — Chest & Triceps');
      await tester.tap(historyCard);
      await tester.pumpAndSettle();

      expect(find.byType(DailyAnalyticsScreen), findsOneWidget);
      expect(find.text('DAILY ANALYTICS'), findsOneWidget);
      expect(find.text('Set 1 — 34 kg × 10 reps'), findsOneWidget);
    });

    testWidgets('HistoryScreen shows empty state when no workouts are recorded', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Clear sessions in history controller
      await WorkoutHistoryController.instance.clearHistory();

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No workouts recorded yet.'), findsOneWidget);
      expect(find.textContaining('Your workout journey starts here'), findsOneWidget);
    });

    test('ProfileAnalyticsService computes all-time overview and current streak with rest day continuity', () {
      final now = DateTime(2026, 11, 9);
      final schedules = <String, DaySchedule>{
        '2026-11-08': DaySchedule(date: DateTime(2026, 11, 8), type: ScheduledDayType.rest),
      };

      final emptyOverview = ProfileAnalyticsService.computeAllTimeOverview(
        sessions: const [],
        schedules: const {},
        referenceDate: now,
      );
      expect(emptyOverview.totalWorkouts, 0);
      expect(emptyOverview.trainingDays, 0);
      expect(emptyOverview.totalVolumeKg, 0.0);
      expect(emptyOverview.hasWeightedVolume, false);
      expect(emptyOverview.currentStreak, 0);

      final sessionNov7A = CompletedWorkoutSession(
        id: 's1',
        routineId: 'r1',
        routineName: 'Push',
        completedAt: DateTime(2026, 11, 7, 10, 0),
        workoutSnapshot: const Workout(
          id: 'w1',
          name: 'Push',
          targetMuscleGroups: 'Chest',
          estimatedDurationMinutes: 45,
          exercises: [
            WorkoutExercise(
              id: 'e1',
              name: 'Bench Press',
              targetMuscle: 'Chest',
              setConfigs: [
                ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 100),
              ],
            ),
          ],
        ),
      );

      final sessionNov7B = CompletedWorkoutSession(
        id: 's2',
        routineId: 'r2',
        routineName: 'Arms',
        completedAt: DateTime(2026, 11, 7, 18, 0),
        workoutSnapshot: const Workout(
          id: 'w2',
          name: 'Arms',
          targetMuscleGroups: 'Biceps',
          estimatedDurationMinutes: 30,
          exercises: [
            WorkoutExercise(
              id: 'e2',
              name: 'Bicep Curl',
              targetMuscle: 'Biceps',
              setConfigs: [
                ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 20),
              ],
            ),
          ],
        ),
      );

      final sessionNov9 = CompletedWorkoutSession(
        id: 's3',
        routineId: 'r1',
        routineName: 'Push',
        completedAt: DateTime(2026, 11, 9, 9, 0),
        workoutSnapshot: const Workout(
          id: 'w3',
          name: 'Push',
          targetMuscleGroups: 'Chest',
          estimatedDurationMinutes: 45,
          exercises: [
            WorkoutExercise(
              id: 'e1',
              name: 'Bench Press',
              targetMuscle: 'Chest',
              setConfigs: [
                ExerciseSetConfig(setNumber: 1, reps: 8, weightKg: 110),
              ],
            ),
          ],
        ),
      );

      final overview = ProfileAnalyticsService.computeAllTimeOverview(
        sessions: [sessionNov7A, sessionNov7B, sessionNov9],
        schedules: schedules,
        referenceDate: now,
      );

      expect(overview.totalWorkouts, 3);
      expect(overview.trainingDays, 2);
      expect(overview.totalVolumeKg, 2080.0);
      expect(overview.hasWeightedVolume, true);
      expect(overview.currentStreak, 2);
    });

    test('ProfileAnalyticsService computes monthly analytics and weekly distribution', () {
      final sessNov = CompletedWorkoutSession(
        id: 's1',
        routineId: 'r1',
        routineName: 'Nov Workout',
        completedAt: DateTime(2026, 11, 3, 10, 0),
        workoutSnapshot: const Workout(
          id: 'w1',
          name: 'Nov Workout',
          targetMuscleGroups: 'Quadriceps',
          estimatedDurationMinutes: 45,
          exercises: [
            WorkoutExercise(
              id: 'e1',
              name: 'Squat',
              targetMuscle: 'Quadriceps',
              setConfigs: [
                ExerciseSetConfig(setNumber: 1, reps: 5, weightKg: 100),
              ],
            ),
          ],
        ),
      );

      final sessOct = CompletedWorkoutSession(
        id: 's2',
        routineId: 'r2',
        routineName: 'Oct Workout',
        completedAt: DateTime(2026, 10, 25, 10, 0),
      );

      final monthly = ProfileAnalyticsService.computeMonthlyAnalytics(
        sessions: [sessNov, sessOct],
        viewingMonth: DateTime(2026, 11, 1),
      );

      expect(monthly.totalWorkouts, 1);
      expect(monthly.trainingDays, 1);
      expect(monthly.totalVolumeKg, 500.0);
      expect(monthly.weeklyFrequency.isNotEmpty, true);
      final w2 = monthly.weeklyFrequency.firstWhere((w) => w.weekLabel == 'W2');
      expect(w2.workoutCount, 1);
    });

    test('ProfileAnalyticsService computes muscle distribution and personal records', () {
      final sess = CompletedWorkoutSession(
        id: 's1',
        routineId: 'r1',
        routineName: 'Upper',
        completedAt: DateTime(2026, 11, 5),
        workoutSnapshot: const Workout(
          id: 'w1',
          name: 'Upper',
          targetMuscleGroups: 'Chest • Back',
          estimatedDurationMinutes: 50,
          exercises: [
            WorkoutExercise(
              id: 'e1',
              name: 'Barbell Bench Press',
              targetMuscle: 'Pectorals',
              setConfigs: [
                ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 80),
                ExerciseSetConfig(setNumber: 2, reps: 5, weightKg: 100),
              ],
            ),
            WorkoutExercise(
              id: 'e2',
              name: 'Barbell Row',
              targetMuscle: 'Back',
              setConfigs: [
                ExerciseSetConfig(setNumber: 1, reps: 8, weightKg: 70),
              ],
            ),
          ],
        ),
      );

      final dist = ProfileAnalyticsService.computeMuscleDistribution(sessions: [sess]);
      expect(dist.length, 2);
      expect(dist.first.muscleGroup, 'Chest');
      expect(dist.first.count, 1);
      expect(dist.first.percentage, 0.5);

      final prs = ProfileAnalyticsService.computePersonalRecords(sessions: [sess]);
      expect(prs.length, 2);
      expect(prs.first.exerciseName, 'Barbell Bench Press');
      expect(prs.first.maxWeightKg, 100.0);
      expect(prs.first.repsAtMaxWeight, 5);
      expect(prs.first.bestSetVolumeKg, 800.0);
    });

    testWidgets('ProfileScreen renders personal profile and overall analytics with empty states', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await ProfileController.instance.saveProfile(
        name: 'Alex Mercer',
        currentWeight: 80.0,
        height: 180.0,
        age: 26,
      );

      await WorkoutHistoryController.instance.clearHistory();

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('BODY INFORMATION'), findsOneWidget);
      expect(find.text('CURRENT WEIGHT'), findsOneWidget);
      expect(find.text('HEIGHT'), findsOneWidget);
      expect(find.text('AGE'), findsOneWidget);
      expect(find.text('TARGET WEIGHT'), findsOneWidget);

      expect(find.text('OVERALL ANALYTICS'), findsOneWidget);
      expect(find.text('ALL-TIME OVERVIEW'), findsOneWidget);
      expect(find.text('TOTAL WORKOUTS'), findsOneWidget);
      expect(find.text('TRAINING DAYS'), findsOneWidget);
      expect(find.text('TOTAL VOLUME'), findsOneWidget);
      expect(find.text('CURRENT STREAK'), findsOneWidget);
      expect(find.text('0 DAYS'), findsOneWidget);

      expect(find.text('WEEKLY WORKOUT FREQUENCY'), findsOneWidget);
      expect(find.text('No workouts recorded in this month.'), findsOneWidget);

      expect(find.text('MUSCLE GROUP DISTRIBUTION'), findsOneWidget);
      expect(find.text('No muscle groups trained yet.'), findsOneWidget);

      expect(find.text('PERSONAL RECORDS'), findsOneWidget);
      expect(find.text('No personal records recorded yet.'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders populated analytics data when sessions exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await ProfileController.instance.saveProfile(
        name: 'Alex Mercer',
        currentWeight: 80.0,
        height: 180.0,
        age: 26,
      );

      final testDate = DateTime.now();
      final workout = Workout(
        id: 'w_test',
        name: 'Full Body Power',
        targetMuscleGroups: 'Chest • Back',
        estimatedDurationMinutes: 45,
        exercises: [
          const WorkoutExercise(
            id: 'e1',
            name: 'Overhead Press',
            targetMuscle: 'Shoulders',
            setConfigs: [
              ExerciseSetConfig(setNumber: 1, reps: 5, weightKg: 60.0),
            ],
          ),
        ],
      );

      await WorkoutHistoryController.instance.recordCompletedSession(
        date: testDate,
        routineId: workout.id,
        routineName: workout.name,
        targetMuscleGroups: workout.targetMuscleGroups,
        workoutSnapshot: workout,
        completedAt: testDate,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TOTAL WORKOUTS'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('300 kg'), findsWidgets);
      expect(find.text('1 DAY'), findsOneWidget);

      expect(find.text('W1'), findsWidgets);
      expect(find.text('Shoulders'), findsOneWidget);
      expect(find.text('Overhead Press'), findsOneWidget);
      expect(find.text('60 KG'), findsOneWidget);
    });
  });
}
