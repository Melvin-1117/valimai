import 'package:flutter/material.dart';
import '../widgets/valimai_bottom_nav.dart';
import 'home_screen.dart';
import 'workouts_screen.dart';
import 'schedule_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onStartWorkout: () => _onTabSelected(1),
        onNavigateTab: _onTabSelected,
      ),
      WorkoutsScreen(
        onStartSession: () {},
      ),
      ScheduleScreen(
        onStartTodaySession: () => _onTabSelected(1),
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

