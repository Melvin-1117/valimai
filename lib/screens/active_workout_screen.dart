import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final String workoutTitle;
  final VoidCallback? onFinish;

  const ActiveWorkoutScreen({
    super.key,
    this.workoutTitle = 'Chest & Triceps Hypertrophy',
    this.onFinish,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late Timer _stopwatchTimer;
  int _secondsElapsed = 14 * 60 + 28; // Start at 14:28 for demo feel

  // Current active set data
  int _currentWeight = 34;
  int _currentReps = 10;
  double _currentRpe = 8.5;

  // Completed sets
  final List<Map<String, dynamic>> _loggedSets = [
    {'set': 1, 'prev': '32 kg × 10', 'weight': 34, 'reps': 10, 'rpe': 8.0, 'completed': true},
    {'set': 2, 'prev': '34 kg × 8', 'weight': 34, 'reps': 10, 'rpe': 8.5, 'completed': true},
    {'set': 3, 'prev': '34 kg × 8', 'weight': 34, 'reps': 9, 'rpe': 9.0, 'completed': false},
    {'set': 4, 'prev': '34 kg × 8', 'weight': 34, 'reps': 8, 'rpe': 9.5, 'completed': false},
  ];

  // Rest timer
  int _restSecondsRemaining = 82;
  Timer? _restTimer;
  bool _isResting = true;

  @override
  void initState() {
    super.initState();
    _startStopwatch();
    _startRestTimer();
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restSecondsRemaining > 0) {
        setState(() {
          _restSecondsRemaining--;
        });
      } else {
        setState(() {
          _isResting = false;
        });
        timer.cancel();
      }
    });
  }

  void _toggleSetCompletion(int index) {
    setState(() {
      _loggedSets[index]['completed'] = !_loggedSets[index]['completed'];
      if (_loggedSets[index]['completed']) {
        _restSecondsRemaining = 90;
        _isResting = true;
        _startRestTimer();
      }
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
    _restTimer?.cancel();
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ElevatedButton(
              onPressed: () {
                _showSessionSummary();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ValimaiColors.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
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

            // Rest Timer Floating Bar
            if (_isResting) _buildRestTimerBar(),
            if (_isResting) const SizedBox(height: 14),

            // Active Movement Card
            _buildActiveMovementCard(),
            const SizedBox(height: 16),

            // Steppers & Set Quick Logger
            _buildSetInputControls(),
            const SizedBox(height: 16),

            // Sets Progression Table
            _buildSetsTable(),
            const SizedBox(height: 20),

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
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ValimaiColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ELAPSED TIME',
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
          Text(
            _formatTime(_secondsElapsed),
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, size: 14, color: ValimaiColors.primaryContainer),
                SizedBox(width: 4),
                Text(
                  'HEAVY LOAD',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
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

  Widget _buildRestTimerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ValimaiColors.primaryContainer.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ValimaiColors.primaryContainer.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer,
                color: ValimaiColors.primaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REST INTERVAL',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  Text(
                    '${_restSecondsRemaining}s Remaining',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _restSecondsRemaining += 30;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: ValimaiColors.surfaceContainerHigh,
                  foregroundColor: ValimaiColors.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '+30s',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 20, color: ValimaiColors.secondary),
                onPressed: () {
                  setState(() {
                    _isResting = false;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMovementCard() {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ValimaiColors.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'EXERCISE 01 OF 06',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
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
          const Text(
            'Incline Dumbbell Bench Press',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Primary focus: Upper Pecs (Clavicular Head) • 30° Bench Angle',
            style: TextStyle(
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
          const SizedBox(height: 14),

          // RPE Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EXERTION (RPE)',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ValimaiColors.secondary,
                ),
              ),
              Text(
                'RPE ${_currentRpe.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ValimaiColors.primaryContainer,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ValimaiColors.primaryContainer,
              inactiveTrackColor: ValimaiColors.surfaceContainerHigh,
              thumbColor: ValimaiColors.primaryContainer,
              overlayColor: ValimaiColors.primaryContainer.withOpacity(0.2),
              trackHeight: 4,
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

          // Log Set Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _loggedSets.add({
                    'set': _loggedSets.length + 1,
                    'prev': '$_currentWeight kg × $_currentReps',
                    'weight': _currentWeight,
                    'reps': _currentReps,
                    'rpe': _currentRpe,
                    'completed': true,
                  });
                  _restSecondsRemaining = 90;
                  _isResting = true;
                  _startRestTimer();
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
                  Icon(Icons.add_task, size: 18, color: ValimaiColors.primaryContainer),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
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
              const SizedBox(width: 4),
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
              _buildStepButton(Icons.remove, onMinus),
              _buildStepButton(Icons.add, onPlus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: ValimaiColors.onSurface),
      ),
    );
  }

  Widget _buildSetsTable() {
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
          ...List.generate(_loggedSets.length, (index) {
            final set = _loggedSets[index];
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.skip_next, size: 20, color: ValimaiColors.secondary),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UP NEXT IN SEQUENCE',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  Text(
                    'Weighted Tricep Dips (3 Sets)',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Icon(Icons.chevron_right, color: ValimaiColors.secondary, size: 20),
        ],
      ),
    );
  }

  void _showSessionSummary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ValimaiColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
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
                'Total Volume: 18 Sets • ${_formatTime(_secondsElapsed)} duration',
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
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                    if (widget.onFinish != null) widget.onFinish!();
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
