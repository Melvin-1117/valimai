import 'package:flutter/material.dart';
import '../services/profile_controller.dart';
import '../services/workout_controller.dart';
import '../theme/app_theme.dart';
import 'profile_setup_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppEntryFlow();
  }

  Future<void> _checkAppEntryFlow() async {
    final startTime = DateTime.now();

    // Initialize controllers and load from persistent storage
    await Future.wait([
      ProfileController.instance.initialize(),
      WorkoutController.instance.initialize(),
    ]);

    // Ensure smooth minimum presentation duration (800ms)
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(milliseconds: 800);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    if (!mounted) return;

    if (ProfileController.instance.isOnboardingCompleted) {
      // Subsequent launches: skip setup, navigate to Home Dashboard
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      // First launch: navigate to Profile Setup
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ProfileSetupScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ValimaiColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kinetic Emblem
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ValimaiColors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3DF02D36),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'VALIMAI',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.0,
                color: ValimaiColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'PRECISION ATHLETIC TERMINAL',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: ValimaiColors.secondary,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ValimaiColors.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

