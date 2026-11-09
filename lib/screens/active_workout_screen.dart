import 'dart:async';

import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../theme/app_theme.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final String workoutTitle;
  final Workout? workout;
  final void Function(Workout completedWorkout)? onFinishWithData;
  final VoidCallback? onFinish;

  const ActiveWorkoutScreen({
    super.key,
    this.workoutTitle = 'Chest & Triceps Hypertrophy',
    this.workout,
    this.onFinishWithData,
    this.onFinish,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late Timer _stopwatchTimer;
  final ValueNotifier<int> _secondsElapsedNotifier = ValueNotifier<int>(0);

  int get _secondsElapsed => _secondsElapsedNotifier.value;

  // Active exercises in this workout session
  late List<WorkoutExercise> _exercises;
  int _currentExerciseIndex = 0;

  // Current active set controls
  int _currentWeight = 34;
  int _currentReps = 10;
  double _currentRpe = 8.5;

  // Map of exerciseIndex -> logged sets (empty initially for each exercise)
  final Map<int, List<Map<String, dynamic>>> _loggedSetsPerExercise = {};

  List<Map<String, dynamic>> get _currentLoggedSets {
    return _loggedSetsPerExercise.putIfAbsent(_currentExerciseIndex, () => []);
  }

  @override
  void initState() {
    super.initState();
    _startStopwatch();

    // Load exercises from provided workout or fallback to default sequence
    if (widget.workout != null && widget.workout!.exercises.isNotEmpty) {
      _exercises = List<WorkoutExercise>.from(widget.workout!.exercises);
    } else {
      _exercises = _buildDefaultExercises();
    }

    _loadExerciseInputs(_currentExerciseIndex);
  }

  List<WorkoutExercise> _buildDefaultExercises() {
    return const [
      WorkoutExercise(
        id: 'ex_1',
        name: 'Incline Dumbbell Bench Press',
        targetMuscle: 'Upper Pecs (Clavicular Head)',
        equipment: '30° Bench Angle',
        sets: 4,
        reps: 10,
        weightKg: 34.0,
        setConfigs: [
          ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 34.0),
          ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 34.0),
          ExerciseSetConfig(setNumber: 3, reps: 10, weightKg: 34.0),
          ExerciseSetConfig(setNumber: 4, reps: 10, weightKg: 34.0),
        ],
      ),
      WorkoutExercise(
        id: 'ex_2',
        name: 'Weighted Tricep Dips',
        targetMuscle: 'Triceps',
        equipment: 'Bodyweight',
        sets: 3,
        reps: 10,
        weightKg: 20.0,
        setConfigs: [
          ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 20.0),
          ExerciseSetConfig(setNumber: 2, reps: 10, weightKg: 20.0),
          ExerciseSetConfig(setNumber: 3, reps: 8, weightKg: 20.0),
        ],
      ),
      WorkoutExercise(
        id: 'ex_3',
        name: 'Standing Dual-Cable Flyes',
        targetMuscle: 'Chest',
        equipment: 'Cable',
        sets: 3,
        reps: 15,
        weightKg: 14.0,
        setConfigs: [
          ExerciseSetConfig(setNumber: 1, reps: 15, weightKg: 14.0),
          ExerciseSetConfig(setNumber: 2, reps: 15, weightKg: 14.0),
          ExerciseSetConfig(setNumber: 3, reps: 12, weightKg: 16.0),
        ],
      ),
      WorkoutExercise(
        id: 'ex_4',
        name: 'Overhead Rope Triceps Extension',
        targetMuscle: 'Triceps',
        equipment: 'Cable',
        sets: 3,
        reps: 12,
        weightKg: 25.0,
        setConfigs: [
          ExerciseSetConfig(setNumber: 1, reps: 12, weightKg: 25.0),
          ExerciseSetConfig(setNumber: 2, reps: 12, weightKg: 25.0),
          ExerciseSetConfig(setNumber: 3, reps: 10, weightKg: 30.0),
        ],
      ),
      WorkoutExercise(
        id: 'ex_5',
        name: 'Dumbbell Lateral Raises',
        targetMuscle: 'Lateral Delts',
        equipment: 'Dumbbell',
        sets: 3,
        reps: 12,
        weightKg: 12.0,
      ),
      WorkoutExercise(
        id: 'ex_6',
        name: 'Close-Grip Pushups',
        targetMuscle: 'Triceps & Chest',
        equipment: 'Bodyweight',
        sets: 3,
        reps: 15,
        weightKg: 0.0,
      ),
    ];
  }

  void _loadExerciseInputs(int index) {
    if (index < 0 || index >= _exercises.length) return;
    _currentExerciseIndex = index;

    final currentEx = _exercises[index];
    final loggedSets = _currentLoggedSets;

    if (loggedSets.isNotEmpty) {
      final lastSet = loggedSets.last;
      _currentWeight = (lastSet['weight'] as num).toInt();
      _currentReps = (lastSet['reps'] as num).toInt();
      _currentRpe = (lastSet['rpe'] as num).toDouble();
    } else {
      final defaultConfigs = currentEx.effectiveSetConfigs;
      if (defaultConfigs.isNotEmpty) {
        _currentWeight = defaultConfigs.first.weightKg.toInt();
        _currentReps = defaultConfigs.first.reps;
      } else {
        _currentWeight = currentEx.weightKg > 0
            ? currentEx.weightKg.toInt()
            : 34;
        _currentReps = currentEx.reps > 0 ? currentEx.reps : 10;
      }
      _currentRpe = 8.5;
    }
  }

  void _navigateToExercise(int targetIndex) {
    if (targetIndex >= 0 && targetIndex < _exercises.length) {
      setState(() {
        _loadExerciseInputs(targetIndex);
      });
    }
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _secondsElapsedNotifier.value++;
      }
    });
  }

  void _toggleSetCompletion(int index) {
    setState(() {
      _currentLoggedSets[index]['completed'] =
          !_currentLoggedSets[index]['completed'];
    });
  }

  void _adjustWeight(int delta) {
    setState(() {
      _currentWeight = (_currentWeight + delta).clamp(0, 500);
    });
  }

  void _adjustReps(int delta) {
    setState(() {
      _currentReps = (_currentReps + delta).clamp(1, 100);
    });
  }

  String _formatTime(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stopwatchTimer.cancel();
    _secondsElapsedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ValimaiColors.background,
      appBar: AppBar(
        backgroundColor: ValimaiColors.surfaceContainer,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: ValimaiColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LIVE SESSION TERMINAL',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: ValimaiColors.primaryContainer,
              ),
            ),
            Text(
              widget.workoutTitle,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ValimaiColors.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _showSessionSummary,
              style: TextButton.styleFrom(
                backgroundColor: ValimaiColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'FINISH',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stop Watch & Live Intensity Strip
            _buildStopwatchHeader(),
            const SizedBox(height: 14),

            // Active Movement Card
            _buildActiveMovementCard(),
            const SizedBox(height: 16),

            // Steppers & Set Quick Logger
            _buildSetInputControls(),
            const SizedBox(height: 16),

            // Sets Progression Table (kept to nothing until first set is logged)
            if (_currentLoggedSets.isNotEmpty) ...[
              _buildSetsTable(),
              const SizedBox(height: 20),
            ],

            // Upcoming Movement in Queue
            _buildNextExercisePreview(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStopwatchHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ValimaiColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ELAPSED TIME',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: ValimaiColors.secondary,
                ),
              ),
            ],
          ),
          Flexible(
            child: ValueListenableBuilder<int>(
              valueListenable: _secondsElapsedNotifier,
              builder: (context, seconds, _) {
                return Text(
                  _formatTime(seconds),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: ValimaiColors.onSurface,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt,
                  size: 11,
                  color: ValimaiColors.primaryContainer,
                ),
                SizedBox(width: 3),
                Text(
                  'HEAVY LOAD',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: ValimaiColors.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMovementCard() {
    final currentEx = _exercises[_currentExerciseIndex];
    final displayOrder = (_currentExerciseIndex + 1).toString().padLeft(2, '0');
    final totalCount = _exercises.length.toString().padLeft(2, '0');

    String subtitle = 'Primary focus: ${currentEx.targetMuscle}';
    if (currentEx.equipment != null && currentEx.equipment!.trim().isNotEmpty) {
      subtitle += ' • ${currentEx.equipment}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.activeBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ValimaiColors.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'EXERCISE $displayOrder OF $totalCount',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_currentExerciseIndex > 0)
                      GestureDetector(
                        onTap: () =>
                            _navigateToExercise(_currentExerciseIndex - 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ValimaiColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chevron_left,
                                size: 12,
                                color: ValimaiColors.secondary,
                              ),
                              Text(
                                'PREV',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: ValimaiColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'TARGET: RPE 8.5',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ValimaiColors.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currentEx.name,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: ValimaiColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetInputControls() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Weight Control
              Expanded(
                child: _buildStepperBox(
                  label: 'WEIGHT',
                  value: '$_currentWeight',
                  unit: 'KG',
                  onMinus: () => _adjustWeight(-2),
                  onPlus: () => _adjustWeight(2),
                ),
              ),
              const SizedBox(width: 12),
              // Reps Control
              Expanded(
                child: _buildStepperBox(
                  label: 'REPS',
                  value: '$_currentReps',
                  unit: 'REPS',
                  onMinus: () => _adjustReps(-1),
                  onPlus: () => _adjustReps(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Exertion (RPE) Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EXERTION (RPE)',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ValimaiColors.secondary,
                ),
              ),
              Text(
                'RPE $_currentRpe',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: ValimaiColors.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ValimaiColors.primaryContainer,
              inactiveTrackColor: ValimaiColors.surfaceContainerHigh,
              thumbColor: ValimaiColors.primaryContainer,
              overlayColor: ValimaiColors.primaryContainer.withOpacity(0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _currentRpe,
              min: 6.0,
              max: 10.0,
              divisions: 8,
              onChanged: (val) {
                setState(() {
                  _currentRpe = val;
                });
              },
            ),
          ),
          const SizedBox(height: 8),

          // Log Next Set Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentLoggedSets.add({
                    'set': _currentLoggedSets.length + 1,
                    'prev': '$_currentWeight kg × $_currentReps',
                    'weight': _currentWeight,
                    'reps': _currentReps,
                    'rpe': _currentRpe,
                    'completed': true,
                  });
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ValimaiColors.surfaceContainerHigh,
                foregroundColor: ValimaiColors.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: ValimaiColors.cardBorder),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_task,
                    size: 18,
                    color: ValimaiColors.primaryContainer,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'LOG NEXT SET',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperBox({
    required String label,
    required String value,
    required String unit,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: ValimaiColors.onSurface,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ValimaiColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStepperBtn(Icons.remove, onMinus),
              _buildStepperBtn(Icons.add, onPlus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: ValimaiColors.onSurface),
      ),
    );
  }

  Widget _buildSetsTable() {
    final sets = _currentLoggedSets;
    if (sets.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SET LOG PROGRESSION',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ValimaiColors.secondary,
                ),
              ),
              Text(
                'STATUS',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ValimaiColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(sets.length, (index) {
            final set = sets[index];
            final bool isCompleted = set['completed'] as bool;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isCompleted
                    ? ValimaiColors.surfaceContainerHigh.withOpacity(0.5)
                    : ValimaiColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted
                      ? ValimaiColors.primaryContainer.withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: ValimaiColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${set['set']}',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: ValimaiColors.secondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${set['weight']} kg × ${set['reps']} reps',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isCompleted
                              ? ValimaiColors.onSurface
                              : ValimaiColors.secondary,
                          decoration: isCompleted ? TextDecoration.none : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RPE ${set['rpe']}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _toggleSetCompletion(index),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? ValimaiColors.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCompleted
                              ? ValimaiColors.primaryContainer
                              : ValimaiColors.secondary.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNextExercisePreview() {
    final bool hasNext = _currentExerciseIndex < _exercises.length - 1;
    final WorkoutExercise? nextEx = hasNext
        ? _exercises[_currentExerciseIndex + 1]
        : null;

    return GestureDetector(
      onTap: () {
        if (hasNext) {
          _navigateToExercise(_currentExerciseIndex + 1);
        } else {
          _showSessionSummary();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasNext
                ? ValimaiColors.cardBorder
                : ValimaiColors.primaryContainer.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    hasNext ? Icons.skip_next : Icons.check_circle_outline,
                    size: 20,
                    color: ValimaiColors.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasNext ? 'UP NEXT IN SEQUENCE' : 'WORKOUT COMPLETE',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: hasNext
                                ? ValimaiColors.secondary
                                : ValimaiColors.primaryContainer,
                          ),
                        ),
                        Text(
                          hasNext
                              ? '${nextEx!.name} (${nextEx.effectiveSetConfigs.length} Sets)'
                              : 'All ${_exercises.length} movements complete',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ValimaiColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasNext ? 'NEXT' : 'FINISH',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ValimaiColors.primaryContainer,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  color: ValimaiColors.primaryContainer,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Workout _buildCompletedWorkoutSnapshot() {
    final List<WorkoutExercise> performedExercises = [];

    for (int i = 0; i < _exercises.length; i++) {
      final ex = _exercises[i];
      final loggedSets = _loggedSetsPerExercise[i];

      if (loggedSets != null && loggedSets.isNotEmpty) {
        final List<ExerciseSetConfig> setConfigs = [];
        for (int s = 0; s < loggedSets.length; s++) {
          final setMap = loggedSets[s];
          setConfigs.add(
            ExerciseSetConfig(
              setNumber: s + 1,
              reps: (setMap['reps'] as num).toInt(),
              weightKg: (setMap['weight'] as num).toDouble(),
            ),
          );
        }

        performedExercises.add(
          ex.copyWith(
            setConfigs: setConfigs,
            sets: setConfigs.length,
            reps: setConfigs.isNotEmpty ? setConfigs.first.reps : ex.reps,
            weightKg: setConfigs.isNotEmpty
                ? setConfigs.first.weightKg
                : ex.weightKg,
          ),
        );
      }
    }

    // If no sets were explicitly logged, fall back to base exercises
    final effectiveExercises = performedExercises.isNotEmpty
        ? performedExercises
        : List<WorkoutExercise>.from(_exercises);

    final baseWorkout = widget.workout;
    return Workout(
      id: baseWorkout?.id ?? 'workout_${DateTime.now().millisecondsSinceEpoch}',
      name: baseWorkout?.name ?? widget.workoutTitle,
      targetMuscleGroups:
          baseWorkout?.targetMuscleGroups ??
          effectiveExercises.map((e) => e.targetMuscle).toSet().join(' • '),
      estimatedDurationMinutes: (_secondsElapsed / 60).ceil().clamp(1, 300),
      exercises: effectiveExercises,
    );
  }

  void _showSessionSummary() {
    int totalLoggedSets = 0;
    for (final list in _loggedSetsPerExercise.values) {
      totalLoggedSets += list.length;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: ValimaiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ValimaiColors.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: ValimaiColors.primaryContainer,
              ),
              const SizedBox(height: 12),
              const Text(
                'WORKOUT COMPLETED',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: ValimaiColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                totalLoggedSets > 0
                    ? 'Total Sets: $totalLoggedSets • ${_formatTime(_secondsElapsed)} duration'
                    : 'Duration: ${_formatTime(_secondsElapsed)}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: ValimaiColors.secondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final completedSnapshot = _buildCompletedWorkoutSnapshot();
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                    if (widget.onFinishWithData != null) {
                      widget.onFinishWithData!(completedSnapshot);
                    } else if (widget.onFinish != null) {
                      widget.onFinish!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ValimaiColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'SAVE TO PERFORMANCE ARCHIVE',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
