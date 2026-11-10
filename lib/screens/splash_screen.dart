import 'package:flutter/material.dart';

import '../services/daily_workout_controller.dart';
import '../services/exercise_controller.dart';
import '../services/profile_controller.dart';
import '../services/routine_controller.dart';
import '../services/storage_helper.dart';
import '../services/workout_controller.dart';
import '../services/workout_history_controller.dart';
import '../theme/app_theme.dart';
import 'daily_workout_selection_screen.dart';
import 'profile_setup_screen.dart';
import 'main_shell.dart';

/// Premium animated Valimai splash screen recreating the progressive build-up:
/// Stage 1: Dark Introduction (athlete silhouette)
/// Stage 2: Character Reveal & Muscle Illumination
/// Stage 3: Red Circular Energy Arc drawing smoothly around the athlete
/// Stage 4: Bold Metallic Italic VALIMAI Wordmark reveal with red winged accent
/// Stage 5: Hold in full brilliance, then smooth fade transition to target screen.
///
/// Continuous dual-frame cross-fade interpolation eliminates stepped jumps
/// between frames, producing a fluid 60/120 FPS cinematic motion experience.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalFrames = 9;
  static const Duration _animationDuration = Duration(milliseconds: 2400);
  static const Duration _holdDuration = Duration(milliseconds: 250);

  late final AnimationController _controller;
  late final Animation<double> _buildUpAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _introFadeAnimation;
  late final Animation<double> _glowAnimation;

  final List<ImageProvider> _frameProviders = List.generate(
    _totalFrames,
    (index) => AssetImage('assets/branding/valimai_splash_$index.png'),
  );

  bool _initializationFinished = false;
  bool _navigated = false;
  bool _precached = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    // Smooth cubic curve for realistic cinematic acceleration and settle
    _buildUpAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.92, curve: Curves.easeInOutCubic),
    );

    // Subtle scale expansion giving depth and power
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    // Initial fade in for the dark silhouette (Stage 1)
    _introFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.12, curve: Curves.easeIn),
      ),
    );

    // Subtle crimson glow expansion when the circular aura forms
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.85, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onAnimationCompleted();
      }
    });

    _initializeAppAndPlay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final provider in _frameProviders) {
        precacheImage(provider, context);
      }
      precacheImage(
        const AssetImage('assets/branding/valimai_wordmark.png'),
        context,
      );
      precacheImage(
        const AssetImage('assets/branding/valimai_logo_emblem.png'),
        context,
      );
    }
  }

  Future<void> _initializeAppAndPlay() async {
    // Start animation playback immediately
    _controller.forward();

    try {
      // Controlled one-time development mock data cleanup
      await StorageHelper.cleanDevMockDataOnce();

      // Initialize all domain controllers from persistent local storage
      await Future.wait([
        ProfileController.instance.initialize(),
        WorkoutController.instance.initialize(),
        ExerciseController.instance.initialize(),
        RoutineController.instance.initialize(),
        DailyWorkoutController.instance.initialize(),
        WorkoutHistoryController.instance.initialize(),
      ]);
    } catch (e) {
      debugPrint('Valimai startup initialization error: $e');
    } finally {
      if (mounted) {
        _initializationFinished = true;
        // If animation has already completed, transition to app immediately
        if (_controller.isCompleted) {
          _onAnimationCompleted();
        }
      }
    }
  }

  void _onAnimationCompleted() {
    if (_navigated || !mounted) return;

    if (_initializationFinished) {
      // Hold completed branding briefly for impact before smooth navigation
      Future.delayed(_holdDuration, () {
        if (!_navigated && mounted) {
          _navigateToApp();
        }
      });
    }
  }

  void _navigateToApp() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final Widget targetScreen;
    if (ProfileController.instance.isOnboardingCompleted) {
      if (DailyWorkoutController.instance.hasDecisionForToday()) {
        targetScreen = const MainShell();
      } else {
        targetScreen = const DailyWorkoutSelectionScreen();
      }
    } else {
      targetScreen = const ProfileSetupScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = (size.width * 0.82).clamp(280.0, 420.0);

    return Scaffold(
      backgroundColor: ValimaiColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Allow tapping to skip hold once initialization is complete
          if (_initializationFinished && !_navigated) {
            _navigateToApp();
          }
        },
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient subtle background energy glow
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  final glow = _glowAnimation.value;
                  if (glow <= 0.01) return const SizedBox.shrink();
                  return Container(
                    width: logoSize * 0.9,
                    height: logoSize * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(240, 45, 54, 0.20 * glow),
                          blurRadius: 70 * glow,
                          spreadRadius: 15 * glow,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Progressive Animated Logo Build-up with 60 FPS continuous cross-fade
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final animProgress = _buildUpAnimation.value;
                  final totalIndexMax = (_totalFrames - 1).toDouble();
                  final frameProgress = (animProgress * totalIndexMax).clamp(
                    0.0,
                    totalIndexMax,
                  );

                  final baseIdx = frameProgress.floor().clamp(
                    0,
                    _totalFrames - 2,
                  );
                  final nextIdx = (baseIdx + 1).clamp(0, _totalFrames - 1);
                  final blendRatio = (frameProgress - baseIdx).clamp(0.0, 1.0);

                  final introOpacity = _introFadeAnimation.value;
                  final currentOpacity = ((1.0 - blendRatio) * introOpacity)
                      .clamp(0.0, 1.0);
                  final nextOpacity = (blendRatio * introOpacity).clamp(
                    0.0,
                    1.0,
                  );

                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Base frame
                          if (currentOpacity > 0.001)
                            Opacity(
                              opacity: currentOpacity,
                              child: Image(
                                image: _frameProviders[baseIdx],
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),

                          // Next frame cross-fading in smoothly
                          if (nextOpacity > 0.001)
                            Opacity(
                              opacity: nextOpacity,
                              child: Image(
                                image: _frameProviders[nextIdx],
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Bottom status line & subtle progress
              Positioned(
                bottom: 48,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PRECISION ATHLETIC TERMINAL',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 48,
                      height: 2,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(1),
                            child: LinearProgressIndicator(
                              value: _controller.value,
                              backgroundColor: ValimaiColors.surface,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                ValimaiColors.primaryContainer,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
