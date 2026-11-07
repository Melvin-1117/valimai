import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valimai/models/exercise.dart';
import 'package:valimai/models/user_profile.dart';
import 'package:valimai/models/workout.dart';
import 'package:valimai/services/exercise_controller.dart';
import 'package:valimai/services/exercise_storage.dart';
import 'package:valimai/services/profile_controller.dart';
import 'package:valimai/services/profile_storage.dart';
import 'package:valimai/services/workout_controller.dart';
import 'package:valimai/services/workout_storage.dart';
import 'package:valimai/screens/add_exercise_screen.dart';
import 'package:valimai/screens/home_screen.dart';
import 'package:valimai/screens/profile_screen.dart';
import 'package:valimai/screens/workout_editor_screen.dart';

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

  MockWorkoutStorage() {
    _seed();
  }

  void _seed() {
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
          restSeconds: 90,
          order: 0,
        ),
        WorkoutExercise(
          id: 'ex_2',
          name: 'Weighted Tricep Dips',
          targetMuscle: 'Lateral Triceps',
          sets: 3,
          reps: 12,
          weightKg: 16.0,
          restSeconds: 90,
          order: 1,
        ),
      ],
    );

    workouts[pushWorkout.id] = pushWorkout;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final key = DaySchedule.dateKey(today);

    schedules[key] = DaySchedule(
      date: today,
      type: ScheduledDayType.workout,
      workoutId: pushWorkout.id,
      isCompleted: false,
    );
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

void main() {
  late MockProfileStorage mockProfileStorage;
  late ProfileController profileController;
  late MockWorkoutStorage mockWorkoutStorage;
  late WorkoutController workoutController;
  late MockExerciseStorage mockExerciseStorage;
  late ExerciseController exerciseController;

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
  });
}
