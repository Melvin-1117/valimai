import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valimai/models/user_profile.dart';
import 'package:valimai/services/profile_controller.dart';
import 'package:valimai/services/profile_storage.dart';
import 'package:valimai/main.dart';
import 'package:valimai/screens/profile_screen.dart';
import 'package:valimai/screens/profile_setup_screen.dart';

class MockProfileStorage implements IProfileStorage {
  UserProfile? storedProfile;

  @override
  Future<UserProfile?> loadProfile() async {
    return storedProfile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    storedProfile = profile;
  }

  @override
  Future<void> clearProfile() async {
    storedProfile = null;
  }
}

void main() {
  late MockProfileStorage mockStorage;
  late ProfileController controller;

  setUp(() {
    mockStorage = MockProfileStorage();
    controller = ProfileController(storage: mockStorage);
    ProfileController.setInstance(controller);
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

  group('ProfileController Logic Tests', () {
    test('validation catches empty name and invalid ranges', () async {
      await controller.initialize();
      expect(controller.isOnboardingCompleted, isFalse);

      // Empty name
      final res1 = await controller.saveProfile(
        name: '   ',
        currentWeight: 75,
        height: 175,
        age: 25,
      );
      expect(res1, isFalse);
      expect(controller.errorMessage, contains('Name cannot be empty'));

      // Weight out of range
      final res2 = await controller.saveProfile(
        name: 'Alex',
        currentWeight: 10, // < 20
        height: 175,
        age: 25,
      );
      expect(res2, isFalse);
      expect(controller.errorMessage, contains('Weight must be between'));

      // Height out of range
      final res3 = await controller.saveProfile(
        name: 'Alex',
        currentWeight: 75,
        height: 350, // > 300
        age: 25,
      );
      expect(res3, isFalse);
      expect(controller.errorMessage, contains('Height must be between'));

      // Age out of range
      final res4 = await controller.saveProfile(
        name: 'Alex',
        currentWeight: 75,
        height: 175,
        age: 5, // < 10
      );
      expect(res4, isFalse);
      expect(controller.errorMessage, contains('Age must be between'));

      // Valid save
      final res5 = await controller.saveProfile(
        name: 'Alex Mercer',
        currentWeight: 82.4,
        height: 182.0,
        age: 27,
        targetWeight: 80.0,
      );
      expect(res5, isTrue);
      expect(controller.isOnboardingCompleted, isTrue);
      expect(controller.profile?.name, 'Alex Mercer');
      expect(mockStorage.storedProfile?.name, 'Alex Mercer');
    });

    test('updating profile reflects changes immediately', () async {
      await controller.saveProfile(
        name: 'Alex Mercer',
        currentWeight: 82.4,
        height: 182.0,
        age: 27,
      );

      final updateRes = await controller.updateProfile(
        currentWeight: 81.5,
        targetWeight: 79.0,
      );
      expect(updateRes, isTrue);
      expect(controller.profile?.currentWeight, 81.5);
      expect(controller.profile?.targetWeight, 79.0);
      expect(mockStorage.storedProfile?.currentWeight, 81.5);
    });
  });

  group('Application Flow & UI Tests', () {
    testWidgets('First launch flow: Splash -> Profile Setup', (tester) async {
      await tester.pumpWidget(const ValimaiApp());

      // Initial frame is Splash Screen
      expect(find.text('VALIMAI'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Settle splash timer
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Profile Setup Screen is shown
      expect(find.text('Profile Setup'), findsOneWidget);
      expect(find.text('SAVE PROFILE'), findsOneWidget);
      expect(find.text('FULL NAME'), findsOneWidget);
    });

    testWidgets('Subsequent launch flow: Splash skips Setup -> Home Dashboard',
        (tester) async {
      // Pre-seed profile as if already completed
      mockStorage.storedProfile = UserProfile(
        name: 'Bruce Wayne',
        currentWeight: 95.0,
        height: 188.0,
        age: 32,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(const ValimaiApp());
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Directly on Home Dashboard (MainShell)
      expect(find.text('Profile Setup'), findsNothing);
      expect(find.text('Good morning, Bruce'), findsOneWidget);
      expect(find.text('START WORKOUT'), findsOneWidget);
      expect(find.text('Workouts'), findsOneWidget);
    });

    testWidgets('Profile page shows Section A (Header) and Section B (Body Info)',
        (tester) async {
      mockStorage.storedProfile = UserProfile(
        name: 'Diana Prince',
        currentWeight: 68.0,
        height: 178.0,
        age: 28,
        targetWeight: 66.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await controller.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: const ProfileScreen(),
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

      // Verify no cluttered legacy sections
      expect(find.text('TRAINING ARCHITECTURE'), findsNothing);
      expect(find.text('SYSTEM TELEMETRY & SYNC'), findsNothing);
    });
  });
}
