import 'package:flutter/material.dart';
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

  void _launchLiveWorkout([String title = 'Chest & Triceps Hypertrophy']) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(
          workoutTitle: title,
          onFinish: () {
            WorkoutController.instance.markWorkoutCompleted(
              WorkoutController.instance.selectedDate,
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
        onStartWorkoutWithData: (workout) => _launchLiveWorkout(workout.name),
        onStartWorkout: () => _launchLiveWorkout('Chest & Triceps Hypertrophy'),
        onNavigateTab: _onTabSelected,
      ),
      WorkoutsScreen(
        onStartSession: () => _launchLiveWorkout('Push Focus: Chest & Triceps'),
      ),
      ScheduleScreen(
        onStartTodaySession: () => _launchLiveWorkout('Chest & Triceps Hypertrophy'),
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
