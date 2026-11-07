import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valimai/models/user_profile.dart';
import 'package:valimai/models/workout.dart';
import 'package:valimai/services/profile_controller.dart';
import 'package:valimai/services/profile_storage.dart';
import 'package:valimai/services/workout_controller.dart';
import 'package:valimai/services/workout_storage.dart';
import 'package:valimai/main.dart';
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

void main() {
  late MockProfileStorage mockProfileStorage;
  late ProfileController profileController;
  late MockWorkoutStorage mockWorkoutStorage;
  late WorkoutController workoutController;

  setUp(() {
    mockProfileStorage = MockProfileStorage();
    profileController = ProfileController(storage: mockProfileStorage);
    ProfileController.setInstance(profileController);

    mockWorkoutStorage = MockWorkoutStorage();
    workoutController = WorkoutController(storage: mockWorkoutStorage);
    WorkoutController.setInstance(workoutController);
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

  group('Workout & DaySchedule Model Tests', () {
    test('calculates total sets and exercise count', () {
      const workout = Workout(
        id: 'test_w',
        name: 'Upper Body',
        targetMuscleGroups: 'Chest & Back',
        estimatedDurationMinutes: 45,
        exercises: [
          WorkoutExercise(
            id: 'e1',
            name: 'Bench Press',
            targetMuscle: 'Chest',
            sets: 4,
            reps: 8,
            weightKg: 80,
            restSeconds: 90,
          ),
          WorkoutExercise(
            id: 'e2',
            name: 'Pull-ups',
            targetMuscle: 'Lats',
            sets: 3,
            reps: 10,
            weightKg: 0,
            restSeconds: 60,
          ),
        ],
      );

      expect(workout.totalSets, 7);
      expect(workout.exerciseCount, 2);
    });

    test('standardizes dateKey correctly', () {
      final dt = DateTime(2026, 3, 5, 14, 30);
      expect(DaySchedule.dateKey(dt), '2026-03-05');
    });
  });

  group('Home Dashboard Tests', () {
    testWidgets('Displays Section A: Weekly Calendar, Section B: Today\'s Workout, Section C: Modify Workout',
        (tester) async {
      await workoutController.initialize();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Section A: Calendar
      expect(find.byType(HomeScreen), findsOneWidget);

      // Section B: Today's Workout details
      expect(find.text('Chest & Triceps Hypertrophy'), findsOneWidget);
      expect(find.text("START TODAY'S WORKOUT"), findsOneWidget);
      expect(find.text('EXERCISES IN PROTOCOL'), findsOneWidget);
      expect(find.text('Incline Dumbbell Bench Press'), findsOneWidget);

      // Section C: Modify Workout button
      expect(find.text('MODIFY WORKOUT'), findsOneWidget);
    });

    testWidgets('Tapping Modify Workout opens WorkoutEditorScreen',
        (tester) async {
      await workoutController.initialize();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final modifyBtn = find.text('MODIFY WORKOUT');
      expect(modifyBtn, findsOneWidget);

      await tester.tap(modifyBtn);
      await tester.pumpAndSettle();

      // Opened WorkoutEditorScreen
      expect(find.byType(WorkoutEditorScreen), findsOneWidget);
      expect(find.text('WORKOUT EDITOR'), findsOneWidget);
      expect(find.text('SAVE WORKOUT CHANGES'), findsOneWidget);
    });

    testWidgets('Handles Rest Day correctly', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await workoutController.initialize();

      // Set today to rest
      await workoutController.setDayType(today, ScheduledDayType.rest);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SCHEDULED REST & RECOVERY'), findsOneWidget);
      expect(find.text('Active Recovery Day'), findsOneWidget);
      expect(find.text('ASSIGN A WORKOUT TO THIS DAY'), findsOneWidget);
    });

    testWidgets('Handles Unassigned Day correctly', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await workoutController.initialize();

      // Set today to unassigned
      await workoutController.setDayType(today, ScheduledDayType.unassigned);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Workout Scheduled'), findsOneWidget);
      expect(find.text('ASSIGN WORKOUT'), findsOneWidget);
    });

    testWidgets('Handles Completed Workout correctly', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await workoutController.initialize();

      // Mark completed
      await workoutController.markWorkoutCompleted(today, true);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WORKOUT COMPLETED'), findsOneWidget);
      expect(find.text('REPEAT SESSION'), findsOneWidget);
      expect(find.text('MODIFY WORKOUT'), findsOneWidget);
    });
  });

  group('Profile Page Tests', () {
    testWidgets('Profile page shows Section A (Header) and Section B (Body Info)',
        (tester) async {
      mockProfileStorage.storedProfile = UserProfile(
        name: 'Diana Prince',
        currentWeight: 68.0,
        height: 178.0,
        age: 28,
        targetWeight: 66.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await profileController.initialize();

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Section A: Header
      expect(find.text('DP'), findsOneWidget); // Initials
      expect(find.text('Diana Prince'), findsOneWidget);
      expect(find.text('EDIT PROFILE'), findsOneWidget);

      // Section B: Body Information
      expect(find.text('BODY INFORMATION'), findsOneWidget);
      expect(find.text('Edit Information'), findsOneWidget);
      expect(find.text('CURRENT WEIGHT'), findsOneWidget);
      expect(find.text('68.0'), findsOneWidget);
      expect(find.text('HEIGHT'), findsOneWidget);
      expect(find.text('178'), findsOneWidget);
      expect(find.text('AGE'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('TARGET WEIGHT'), findsOneWidget);
      expect(find.text('66.0'), findsOneWidget);

      // Verify no cluttered legacy sections or athlete mary badge
      expect(find.text('ATHLETE #MARY'), findsNothing);
      expect(find.text('TRAINING ARCHITECTURE'), findsNothing);
    });
  });
}
