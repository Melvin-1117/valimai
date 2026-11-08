import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/workout_controller.dart';
import '../widgets/valimai_bottom_nav.dart';
import 'home_screen.dart';
import 'workouts_screen.dart';
import 'schedule_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'active_workout_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _launchLiveWorkout([Workout? workout, String title = 'Chest & Triceps Hypertrophy']) {
    final effectiveWorkout = workout ??
        WorkoutController.instance
            .getWorkoutForDate(WorkoutController.instance.selectedDate);
    final selectedDate = WorkoutController.instance.selectedDate;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(
          workoutTitle: effectiveWorkout?.name ?? title,
          workout: effectiveWorkout,
          onFinishWithData: (completedWorkout) {
            WorkoutController.instance.markWorkoutCompleted(
              selectedDate,
              true,
              completedWorkout: completedWorkout,
            );
            _onTabSelected(3); // Switch to History tab to see new records
          },
          onFinish: () {
            WorkoutController.instance.markWorkoutCompleted(
              selectedDate,
              true,
            );
            _onTabSelected(3); // Switch to History tab to see new records
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onStartWorkoutWithData: (w) => _launchLiveWorkout(w, w.name),
        onStartWorkout: () => _launchLiveWorkout(null, 'Chest & Triceps Hypertrophy'),
        onNavigateTab: _onTabSelected,
      ),
      WorkoutsScreen(
        onStartSession: () => _launchLiveWorkout(null, 'Push Focus: Chest & Triceps'),
      ),
      ScheduleScreen(
        onStartTodaySession: () => _launchLiveWorkout(null, 'Chest & Triceps Hypertrophy'),
      ),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: ValimaiBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
